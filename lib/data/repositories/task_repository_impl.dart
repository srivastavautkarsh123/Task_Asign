import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/i_task_repository.dart';
import '../datasources/mock_data_source.dart';
import '../datasources/local_storage_data_source.dart';
import '../models/task_dto.dart';
import '../models/comment_dto.dart';

class TaskRepositoryImpl implements ITaskRepository {
  final MockDataSource _mockDataSource;
  final LocalStorageDataSource _localStorage;

  List<TaskDto>? _inMemoryTasks;
  List<CommentDto>? _inMemoryComments;

  TaskRepositoryImpl({
    required MockDataSource mockDataSource,
    required LocalStorageDataSource localStorage,
  })  : _mockDataSource = mockDataSource,
        _localStorage = localStorage;

  Future<void> _ensureLoaded() async {
    if (_inMemoryTasks == null) {
      final tasksFromSource = await _mockDataSource.getTasks();
      _inMemoryTasks = List.from(tasksFromSource);
      await _localStorage.saveTasks(_inMemoryTasks!);
    }
    if (_inMemoryComments == null) {
      final commentsFromSource = await _mockDataSource.getComments();
      _inMemoryComments = List.from(commentsFromSource);
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksForProject(String projectId) async {
    try {
      await _ensureLoaded();
      final filtered = _inMemoryTasks!
          .where((t) => t.projectId == projectId)
          .map((t) => t.toEntity())
          .toList();
      return Success(filtered);
    } on Failure catch (f) {
      if (f is OfflineFailure || f is NetworkTimeoutFailure) {
        final cached = await _localStorage.getCachedTasks();
        if (cached != null) {
          final filtered = cached.where((t) => t.projectId == projectId).map((t) => t.toEntity()).toList();
          return Success(filtered);
        }
      }
      return Error(f);
    } catch (e) {
      return Error(ServerFailure("Failed to load tasks: $e"));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksForOrg(String orgId) async {
    try {
      await _ensureLoaded();
      final projects = await _mockDataSource.getProjects();
      final orgProjectIds = projects.where((p) => p.orgId == orgId).map((p) => p.id).toSet();

      final filtered = _inMemoryTasks!
          .where((t) => orgProjectIds.contains(t.projectId))
          .map((t) => t.toEntity())
          .toList();
      return Success(filtered);
    } on Failure catch (f) {
      if (f is OfflineFailure || f is NetworkTimeoutFailure) {
        final cached = await _localStorage.getCachedTasks();
        if (cached != null) {
          final projects = await _mockDataSource.getProjects();
          final orgProjectIds = projects.where((p) => p.orgId == orgId).map((p) => p.id).toSet();
          final filtered = cached.where((t) => orgProjectIds.contains(t.projectId)).map((t) => t.toEntity()).toList();
          return Success(filtered);
        }
      }
      return Error(f);
    } catch (e) {
      return Error(ServerFailure("Failed to load tasks for org: $e"));
    }
  }

  @override
  Future<Result<TaskEntity>> getTaskById(String taskId) async {
    try {
      await _ensureLoaded();
      final match = _inMemoryTasks!.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw const NotFoundFailure("Task not found."),
      );
      return Success(match.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure("Task fetch failed: $e"));
    }
  }

  @override
  Future<Result<TaskEntity>> createTask(UserSession session, TaskEntity task) async {
    try {
      await _ensureLoaded();

      // Org member assignment validation guard
      if (task.assigneeId != null) {
        final validationRes = await _validateAssigneeOrgMembership(session.orgId, task.assigneeId!);
        if (validationRes.isFailure) return Error(validationRes.failureOrNull!);
      }

      final newDto = TaskDto.fromEntity(task);
      _inMemoryTasks!.insert(0, newDto);
      await _localStorage.saveTasks(_inMemoryTasks!);

      return Success(newDto.toEntity());
    } catch (e) {
      return Error(ServerFailure("Failed to create task: $e"));
    }
  }

  @override
  Future<Result<TaskEntity>> updateTask(UserSession session, TaskEntity task) async {
    try {
      await _ensureLoaded();

      if (task.assigneeId != null) {
        final validationRes = await _validateAssigneeOrgMembership(session.orgId, task.assigneeId!);
        if (validationRes.isFailure) return Error(validationRes.failureOrNull!);
      }

      final index = _inMemoryTasks!.indexWhere((t) => t.id == task.id);
      if (index == -1) {
        return const Error(NotFoundFailure("Task not found for update."));
      }

      final updatedDto = TaskDto.fromEntity(task);
      _inMemoryTasks![index] = updatedDto;
      await _localStorage.saveTasks(_inMemoryTasks!);

      return Success(updatedDto.toEntity());
    } catch (e) {
      return Error(ServerFailure("Failed to update task: $e"));
    }
  }

  @override
  Future<Result<void>> deleteTask(UserSession session, String taskId) async {
    try {
      await _ensureLoaded();
      _inMemoryTasks!.removeWhere((t) => t.id == taskId);
      await _localStorage.saveTasks(_inMemoryTasks!);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure("Failed to delete task: $e"));
    }
  }

  @override
  Future<Result<TaskEntity>> assignTaskUser(UserSession session, String taskId, String? assigneeId) async {
    try {
      await _ensureLoaded();

      if (assigneeId != null) {
        final validationRes = await _validateAssigneeOrgMembership(session.orgId, assigneeId);
        if (validationRes.isFailure) return Error(validationRes.failureOrNull!);
      }

      final index = _inMemoryTasks!.indexWhere((t) => t.id == taskId);
      if (index == -1) return const Error(NotFoundFailure("Task not found."));

      final current = _inMemoryTasks![index].toEntity();
      final updated = current.copyWith(
        assigneeId: assigneeId,
        clearAssignee: assigneeId == null,
      );

      final updatedDto = TaskDto.fromEntity(updated);
      _inMemoryTasks![index] = updatedDto;
      await _localStorage.saveTasks(_inMemoryTasks!);

      return Success(updated);
    } catch (e) {
      return Error(ServerFailure("Task assignment failed: $e"));
    }
  }

  Future<Result<void>> _validateAssigneeOrgMembership(String currentOrgId, String assigneeId) async {
    final orgMembers = await _mockDataSource.getOrgMembers();
    final belongsToOrg = orgMembers.any((m) => m.orgId == currentOrgId && m.userId == assigneeId);
    if (!belongsToOrg) {
      return const Error(ValidationError("Assignee does not belong to the active organization."));
    }
    return const Success(null);
  }

  @override
  Future<Result<List<User>>> getOrgMembers(String orgId) async {
    try {
      final orgMembers = await _mockDataSource.getOrgMembers();
      final users = await _mockDataSource.getUsers();

      final validUserIds = orgMembers.where((m) => m.orgId == orgId).map((m) => m.userId).toSet();
      final filteredUsers = users.where((u) => validUserIds.contains(u.id)).map((u) => u.toEntity()).toList();

      return Success(filteredUsers);
    } catch (e) {
      return Error(ServerFailure("Failed to load org members: $e"));
    }
  }

  @override
  Future<Result<List<Comment>>> getTaskComments(String taskId) async {
    try {
      await _ensureLoaded();
      final filtered = _inMemoryComments!
          .where((c) => c.taskId == taskId)
          .map((c) => c.toEntity())
          .toList();
      return Success(filtered);
    } catch (e) {
      return Error(ServerFailure("Failed to load comments: $e"));
    }
  }

  @override
  Future<Result<Comment>> addComment(UserSession session, String taskId, String body) async {
    try {
      await _ensureLoaded();
      final newComment = CommentDto(
        id: "cmt_${DateTime.now().millisecondsSinceEpoch}",
        taskId: taskId,
        authorId: session.user.id,
        body: body,
        createdAt: DateTime.now().toIso8601String(),
      );
      _inMemoryComments!.add(newComment);
      return Success(newComment.toEntity());
    } catch (e) {
      return Error(ServerFailure("Failed to add comment: $e"));
    }
  }
}
