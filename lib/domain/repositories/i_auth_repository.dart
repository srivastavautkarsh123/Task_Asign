import '../../core/utils/result.dart';
import '../entities/user_session.dart';

abstract class IAuthRepository {
  Future<Result<UserSession>> login(String email, String password);
  Future<Result<UserSession>> register(String name, String email, String password, String orgId);
  Future<Result<UserSession>> refreshToken();
  Future<Result<void>> logout();
  Future<Result<UserSession?>> restoreSession();
}
