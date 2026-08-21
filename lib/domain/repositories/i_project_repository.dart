import '../../core/utils/result.dart';
import '../entities/project.dart';
import '../entities/user_session.dart';

abstract class IProjectRepository {
  Future<Result<List<Project>>> getProjectsForOrg(String orgId);
  Future<Result<Project>> getProjectById(String projectId);
  Future<Result<Project>> createProject(UserSession session, String name, String description);
  Future<Result<Project>> updateProject(UserSession session, Project project);
  Future<Result<void>> deleteProject(UserSession session, String projectId);
}
