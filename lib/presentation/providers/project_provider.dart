import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/local_storage_data_source.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/i_project_repository.dart';
import 'auth_provider.dart';
import 'debug_settings_provider.dart';

abstract class ProjectListState {
  const ProjectListState();
}

class ProjectListInitial extends ProjectListState {
  const ProjectListInitial();
}

class ProjectListLoading extends ProjectListState {
  const ProjectListLoading();
}

class ProjectListSuccess extends ProjectListState {
  final List<Project> projects;
  final bool isStaleOffline;

  const ProjectListSuccess(this.projects, {this.isStaleOffline = false});
}

class ProjectListEmpty extends ProjectListState {
  final bool isStaleOffline;
  const ProjectListEmpty({this.isStaleOffline = false});
}

class ProjectListError extends ProjectListState {
  final Failure failure;
  const ProjectListError(this.failure);
}

class ProjectListNotifier extends StateNotifier<ProjectListState> {
  final IProjectRepository _projectRepository;

  ProjectListNotifier(this._projectRepository) : super(const ProjectListInitial());

  Future<void> loadProjects(String orgId) async {
    state = const ProjectListLoading();
    final res = await _projectRepository.getProjectsForOrg(orgId);
    res.fold(
      (projects) {
        if (projects.isEmpty) {
          state = const ProjectListEmpty();
        } else {
          state = ProjectListSuccess(projects);
        }
      },
      (failure) {
        if (failure is OfflineFailure) {
          // If offline, attempt to get cached empty or error
          state = ProjectListError(failure);
        } else {
          state = ProjectListError(failure);
        }
      },
    );
  }

  Future<String?> createProject(UserSession session, String name, String description) async {
    final res = await _projectRepository.createProject(session, name, description);
    return res.fold(
      (newProject) {
        loadProjects(session.orgId);
        return null; // Success
      },
      (failure) => failure.message,
    );
  }

  Future<String?> deleteProject(UserSession session, String projectId) async {
    final res = await _projectRepository.deleteProject(session, projectId);
    return res.fold(
      (_) {
        loadProjects(session.orgId);
        return null; // Success
      },
      (failure) => failure.message,
    );
  }
}

final localStorageDataSourceProvider = Provider<LocalStorageDataSource>((ref) {
  return LocalStorageDataSource();
});

final projectRepositoryProvider = Provider<IProjectRepository>((ref) {
  final mockDs = ref.watch(mockDataSourceProvider);
  final localDs = ref.watch(localStorageDataSourceProvider);
  return ProjectRepositoryImpl(mockDataSource: mockDs, localStorage: localDs);
});

final projectListProvider = StateNotifierProvider<ProjectListNotifier, ProjectListState>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return ProjectListNotifier(repo);
});
