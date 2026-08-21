import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/i_task_repository.dart';
import 'debug_settings_provider.dart';
import 'project_provider.dart';

class TaskFilterState {
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final String? assigneeIdFilter;
  final String searchQuery;
  final DateTimeRange? dateRangeFilter;

  const TaskFilterState({
    this.statusFilter,
    this.priorityFilter,
    this.assigneeIdFilter,
    this.searchQuery = '',
    this.dateRangeFilter,
  });

  bool get hasActiveFilters =>
      statusFilter != null ||
      priorityFilter != null ||
      assigneeIdFilter != null ||
      searchQuery.isNotEmpty ||
      dateRangeFilter != null;

  TaskFilterState copyWith({
    TaskStatus? statusFilter,
    bool clearStatus = false,
    TaskPriority? priorityFilter,
    bool clearPriority = false,
    String? assigneeIdFilter,
    bool clearAssignee = false,
    String? searchQuery,
    DateTimeRange? dateRangeFilter,
    bool clearDateRange = false,
  }) {
    return TaskFilterState(
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      priorityFilter: clearPriority ? null : (priorityFilter ?? this.priorityFilter),
      assigneeIdFilter: clearAssignee ? null : (assigneeIdFilter ?? this.assigneeIdFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      dateRangeFilter: clearDateRange ? null : (dateRangeFilter ?? this.dateRangeFilter),
    );
  }
}

abstract class TaskListState {
  const TaskListState();
}

class TaskListInitial extends TaskListState {
  const TaskListInitial();
}

class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

class TaskListSuccess extends TaskListState {
  final List<TaskEntity> allTasks;
  final List<TaskEntity> filteredTasks;
  final TaskFilterState filters;

  const TaskListSuccess({
    required this.allTasks,
    required this.filteredTasks,
    required this.filters,
  });
}

class TaskListEmpty extends TaskListState {
  final TaskFilterState filters;
  const TaskListEmpty({required this.filters});
}

class TaskListError extends TaskListState {
  final Failure failure;
  const TaskListError(this.failure);
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final ITaskRepository _taskRepository;
  String? _currentOrgId;
  String? _currentProjectId;

  TaskListNotifier(this._taskRepository) : super(const TaskListInitial());

  Future<void> loadTasksForOrg(String orgId) async {
    _currentOrgId = orgId;
    _currentProjectId = null;
    await _fetchTasks(() => _taskRepository.getTasksForOrg(orgId));
  }

  Future<void> loadTasksForProject(String projectId) async {
    _currentProjectId = projectId;
    _currentOrgId = null;
    await _fetchTasks(() => _taskRepository.getTasksForProject(projectId));
  }

  Future<void> _fetchTasks(Future<dynamic> Function() fetchCall) async {
    state = const TaskListLoading();
    final res = await fetchCall();
    res.fold(
      (tasks) {
        final taskList = tasks as List<TaskEntity>;
        final currentFilters = const TaskFilterState();
        _applyFiltersAndEmit(taskList, currentFilters);
      },
      (failure) => state = TaskListError(failure),
    );
  }

  void setFilter(TaskFilterState newFilters) {
    final current = state;
    if (current is TaskListSuccess) {
      _applyFiltersAndEmit(current.allTasks, newFilters);
    } else if (current is TaskListEmpty) {
      // Re-apply on empty
      _applyFiltersAndEmit([], newFilters);
    }
  }

  void _applyFiltersAndEmit(List<TaskEntity> allTasks, TaskFilterState filters) {
    var result = List<TaskEntity>.from(allTasks);

    if (filters.statusFilter != null) {
      result = result.where((t) => t.status == filters.statusFilter).toList();
    }
    if (filters.priorityFilter != null) {
      result = result.where((t) => t.priority == filters.priorityFilter).toList();
    }
    if (filters.assigneeIdFilter != null) {
      result = result.where((t) => t.assigneeId == filters.assigneeIdFilter).toList();
    }
    if (filters.searchQuery.isNotEmpty) {
      final q = filters.searchQuery.toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q)).toList();
    }
    if (filters.dateRangeFilter != null) {
      result = result.where((t) {
        return t.dueDate.isAfter(filters.dateRangeFilter!.start.subtract(const Duration(days: 1))) &&
            t.dueDate.isBefore(filters.dateRangeFilter!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (result.isEmpty) {
      state = TaskListEmpty(filters: filters);
    } else {
      state = TaskListSuccess(
        allTasks: allTasks,
        filteredTasks: result,
        filters: filters,
      );
    }
  }

  Future<String?> createTask(UserSession session, TaskEntity task) async {
    final res = await _taskRepository.createTask(session, task);
    return res.fold(
      (newTask) {
        _reloadCurrent();
        return null;
      },
      (failure) => failure.message,
    );
  }

  Future<String?> updateTask(UserSession session, TaskEntity task) async {
    final res = await _taskRepository.updateTask(session, task);
    return res.fold(
      (updatedTask) {
        _reloadCurrent();
        return null;
      },
      (failure) => failure.message,
    );
  }

  Future<String?> assignUser(UserSession session, String taskId, String? assigneeId) async {
    final res = await _taskRepository.assignTaskUser(session, taskId, assigneeId);
    return res.fold(
      (_) {
        _reloadCurrent();
        return null;
      },
      (failure) => failure.message,
    );
  }

  Future<String?> deleteTask(UserSession session, String taskId) async {
    final res = await _taskRepository.deleteTask(session, taskId);
    return res.fold(
      (_) {
        _reloadCurrent();
        return null;
      },
      (failure) => failure.message,
    );
  }

  void _reloadCurrent() {
    if (_currentProjectId != null) {
      loadTasksForProject(_currentProjectId!);
    } else if (_currentOrgId != null) {
      loadTasksForOrg(_currentOrgId!);
    }
  }
}

final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  final mockDs = ref.watch(mockDataSourceProvider);
  final localDs = ref.watch(localStorageDataSourceProvider);
  return TaskRepositoryImpl(mockDataSource: mockDs, localStorage: localDs);
});

final taskListProvider = StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repo);
});

final orgMembersProvider = FutureProvider.family<List<User>, String>((ref, orgId) async {
  final repo = ref.watch(taskRepositoryProvider);
  final res = await repo.getOrgMembers(orgId);
  return res.fold((users) => users, (failure) => []);
});

final taskCommentsProvider = FutureProvider.family<List<Comment>, String>((ref, taskId) async {
  final repo = ref.watch(taskRepositoryProvider);
  final res = await repo.getTaskComments(taskId);
  return res.fold((comments) => comments, (failure) => []);
});
