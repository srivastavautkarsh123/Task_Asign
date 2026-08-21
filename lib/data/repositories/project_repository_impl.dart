import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/i_project_repository.dart';
import '../datasources/mock_data_source.dart';
import '../datasources/local_storage_data_source.dart';
import '../models/project_dto.dart';

class ProjectRepositoryImpl implements IProjectRepository {
  final MockDataSource _mockDataSource;
  final LocalStorageDataSource _localStorage;

  List<ProjectDto>? _inMemoryProjects;

  ProjectRepositoryImpl({
    required MockDataSource mockDataSource,
    required LocalStorageDataSource localStorage,
  })  : _mockDataSource = mockDataSource,
        _localStorage = localStorage;

  @override
  Future<Result<List<Project>>> getProjectsForOrg(String orgId) async {
    try {
      if (_inMemoryProjects == null) {
        final dtoList = await _mockDataSource.getProjects();
        _inMemoryProjects = List.from(dtoList);
        await _localStorage.saveProjects(_inMemoryProjects!);
      }
      final filtered = _inMemoryProjects!
          .where((p) => p.orgId == orgId)
          .map((p) => p.toEntity())
          .toList();
      return Success(filtered);
    } on Failure catch (f) {
      if (f is OfflineFailure || f is NetworkTimeoutFailure) {
        final cached = await _localStorage.getCachedProjects();
        if (cached != null) {
          final filtered = cached.where((p) => p.orgId == orgId).map((p) => p.toEntity()).toList();
          return Success(filtered);
        }
      }
      return Error(f);
    } catch (e) {
      return Error(ServerFailure("Failed to load projects: $e"));
    }
  }

  @override
  Future<Result<Project>> getProjectById(String projectId) async {
    try {
      final listRes = await getProjectsForOrg("");
      if (listRes.isFailure) return Error(listRes.failureOrNull!);
      final match = _inMemoryProjects?.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw const NotFoundFailure("Project not found."),
      );
      return Success(match!.toEntity());
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure("Error fetching project: $e"));
    }
  }

  @override
  Future<Result<Project>> createProject(UserSession session, String name, String description) async {
    // RBAC Check in Business-Logic Layer
    if (!session.isAdmin) {
      return const Error(UnauthorizedFailure("Only Organization Admins can create projects."));
    }

    try {
      final newId = "proj_${DateTime.now().millisecondsSinceEpoch}";
      final newDto = ProjectDto(
        id: newId,
        orgId: session.orgId,
        name: name,
        description: description,
        taskCount: 0,
        status: 'active',
        createdAt: DateTime.now().toIso8601String(),
      );

      _inMemoryProjects ??= [];
      _inMemoryProjects!.insert(0, newDto);
      await _localStorage.saveProjects(_inMemoryProjects!);

      return Success(newDto.toEntity());
    } catch (e) {
      return Error(ServerFailure("Failed to create project: $e"));
    }
  }

  @override
  Future<Result<Project>> updateProject(UserSession session, Project project) async {
    if (!session.isAdmin) {
      return const Error(UnauthorizedFailure("Only Organization Admins can edit projects."));
    }

    try {
      _inMemoryProjects ??= [];
      final index = _inMemoryProjects!.indexWhere((p) => p.id == project.id);
      if (index == -1) {
        return const Error(NotFoundFailure("Project not found to update."));
      }

      final updatedDto = ProjectDto.fromEntity(project);
      _inMemoryProjects![index] = updatedDto;
      await _localStorage.saveProjects(_inMemoryProjects!);

      return Success(updatedDto.toEntity());
    } catch (e) {
      return Error(ServerFailure("Failed to update project: $e"));
    }
  }

  @override
  Future<Result<void>> deleteProject(UserSession session, String projectId) async {
    // RBAC Guard
    if (!session.isAdmin) {
      return const Error(UnauthorizedFailure("Only Organization Admins can delete projects."));
    }

    try {
      _inMemoryProjects ??= [];
      _inMemoryProjects!.removeWhere((p) => p.id == projectId);
      await _localStorage.saveProjects(_inMemoryProjects!);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure("Failed to delete project: $e"));
    }
  }
}
