import '../../core/utils/result.dart';
import '../entities/task.dart';
import '../entities/user.dart';
import '../entities/comment.dart';
import '../entities/user_session.dart';

abstract class ITaskRepository {
  Future<Result<List<TaskEntity>>> getTasksForProject(String projectId);
  Future<Result<List<TaskEntity>>> getTasksForOrg(String orgId);
  Future<Result<TaskEntity>> getTaskById(String taskId);
  Future<Result<TaskEntity>> createTask(UserSession session, TaskEntity task);
  Future<Result<TaskEntity>> updateTask(UserSession session, TaskEntity task);
  Future<Result<void>> deleteTask(UserSession session, String taskId);
  Future<Result<TaskEntity>> assignTaskUser(UserSession session, String taskId, String? assigneeId);
  Future<Result<List<User>>> getOrgMembers(String orgId);
  Future<Result<List<Comment>>> getTaskComments(String taskId);
  Future<Result<Comment>> addComment(UserSession session, String taskId, String body);
}
