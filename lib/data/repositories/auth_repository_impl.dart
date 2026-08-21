import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/mock_data_source.dart';
import '../datasources/secure_token_storage.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final MockDataSource _mockDataSource;
  final SecureTokenStorage _tokenStorage;

  AuthRepositoryImpl({
    required MockDataSource mockDataSource,
    required SecureTokenStorage tokenStorage,
  })  : _mockDataSource = mockDataSource,
        _tokenStorage = tokenStorage;

  @override
  Future<Result<UserSession>> login(String email, String password) async {
    try {
      final creds = await _mockDataSource.getTestCredentials();
      final match = creds.firstWhere(
        (c) => c.email.trim().toLowerCase() == email.trim().toLowerCase() && c.password == password,
        orElse: () => throw const AuthFailure("Invalid email or password."),
      );

      final users = await _mockDataSource.getUsers();
      final userDto = users.firstWhere(
        (u) => u.email.trim().toLowerCase() == match.email.trim().toLowerCase(),
        orElse: () => throw const AuthFailure("User record not found."),
      );

      final orgMembers = await _mockDataSource.getOrgMembers();
      final memberDto = orgMembers.firstWhere(
        (m) => m.userId == userDto.id && m.orgId == match.orgId,
        orElse: () => throw const AuthFailure("Org membership record not found."),
      );

      final loginResponse = await _mockDataSource.getMockLoginResponse();
      final expiry = DateTime.now().add(Duration(seconds: loginResponse.accessTokenExpiresInSeconds));

      await _tokenStorage.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        expiry: expiry,
        userId: userDto.id,
        orgId: match.orgId,
      );

      final session = UserSession(
        user: userDto.toEntity(),
        memberInfo: memberDto.toEntity(),
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        accessTokenExpiry: expiry,
      );

      return Success(session);
    } on Failure catch (f) {
      return Error(f);
    } catch (e) {
      return Error(ServerFailure("Login failed unexpectedly: $e"));
    }
  }

  @override
  Future<Result<UserSession>> register(String name, String email, String password, String orgId) async {
    try {
      // Simulate registering new user in local state
      final newUserId = "user_${DateTime.now().millisecondsSinceEpoch}";
      final newUser = User(id: newUserId, name: name, email: email, avatarUrl: "https://i.pravatar.cc/150?img=6");
      final memberInfo = OrgMember(orgId: orgId, userId: newUserId, role: OrgRole.member);

      final loginResponse = await _mockDataSource.getMockLoginResponse();
      final expiry = DateTime.now().add(Duration(seconds: loginResponse.accessTokenExpiresInSeconds));

      await _tokenStorage.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        expiry: expiry,
        userId: newUserId,
        orgId: orgId,
      );

      final session = UserSession(
        user: newUser,
        memberInfo: memberInfo,
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        accessTokenExpiry: expiry,
      );

      return Success(session);
    } catch (e) {
      return Error(ServerFailure("Registration failed: $e"));
    }
  }

  @override
  Future<Result<UserSession>> refreshToken() async {
    try {
      final currentRefreshToken = await _tokenStorage.getRefreshToken();
      if (currentRefreshToken == null) {
        return const Error(AuthFailure("No refresh token available."));
      }

      final userId = await _tokenStorage.getUserId();
      final orgId = await _tokenStorage.getOrgId();

      if (userId == null || orgId == null) {
        return const Error(AuthFailure("Invalid session state."));
      }

      final users = await _mockDataSource.getUsers();
      final userDto = users.firstWhere(
        (u) => u.id == userId,
        orElse: () => users.first,
      );

      final orgMembers = await _mockDataSource.getOrgMembers();
      final memberDto = orgMembers.firstWhere(
        (m) => m.userId == userId && m.orgId == orgId,
        orElse: () => orgMembers.first,
      );

      final mockResponse = await _mockDataSource.getMockLoginResponse();
      final newAccessToken = "mock.access.token.refreshed_${DateTime.now().millisecondsSinceEpoch}";
      final expiry = DateTime.now().add(Duration(seconds: mockResponse.accessTokenExpiresInSeconds));

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: currentRefreshToken,
        expiry: expiry,
        userId: userId,
        orgId: orgId,
      );

      final session = UserSession(
        user: userDto.toEntity(),
        memberInfo: memberDto.toEntity(),
        accessToken: newAccessToken,
        refreshToken: currentRefreshToken,
        accessTokenExpiry: expiry,
      );

      return Success(session);
    } catch (e) {
      return Error(ServerFailure("Failed to refresh token: $e"));
    }
  }

  @override
  Future<Result<void>> logout() async {
    await _tokenStorage.clearSession();
    return const Success(null);
  }

  @override
  Future<Result<UserSession?>> restoreSession() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      final refreshTokenStr = await _tokenStorage.getRefreshToken();
      final expiry = await _tokenStorage.getExpiryTimestamp();
      final userId = await _tokenStorage.getUserId();
      final orgId = await _tokenStorage.getOrgId();

      if (token == null || refreshTokenStr == null || expiry == null || userId == null || orgId == null) {
        return const Success(null);
      }

      // Check expiry
      if (DateTime.now().isAfter(expiry)) {
        // Attempt refresh
        final refreshRes = await refreshToken();
        if (refreshRes.isSuccess) {
          return Success(refreshRes.dataOrNull);
        }
        await _tokenStorage.clearSession();
        return const Success(null);
      }

      final users = await _mockDataSource.getUsers();
      final userDto = users.firstWhere((u) => u.id == userId, orElse: () => users.first);

      final orgMembers = await _mockDataSource.getOrgMembers();
      final memberDto = orgMembers.firstWhere((m) => m.userId == userId && m.orgId == orgId, orElse: () => orgMembers.first);

      final session = UserSession(
        user: userDto.toEntity(),
        memberInfo: memberDto.toEntity(),
        accessToken: token,
        refreshToken: refreshTokenStr,
        accessTokenExpiry: expiry,
      );

      return Success(session);
    } catch (e) {
      return const Success(null);
    }
  }
}
