import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:assignment/data/datasources/mock_data_source.dart';
import 'package:assignment/data/datasources/secure_token_storage.dart';
import 'package:assignment/data/repositories/auth_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});

  late MockDataSource mockDataSource;
  late SecureTokenStorage tokenStorage;
  late AuthRepositoryImpl authRepository;

  setUp(() {
    mockDataSource = MockDataSource();
    tokenStorage = SecureTokenStorage();
    authRepository = AuthRepositoryImpl(
      mockDataSource: mockDataSource,
      tokenStorage: tokenStorage,
    );
  });

  group('AuthRepositoryImpl Unit Tests', () {
    test('login with valid admin credentials succeeds and returns session', () async {
      final res = await authRepository.login('aditya.admin@nimbusdigital.test', 'Password123!');
      expect(res.isSuccess, isTrue);
      final session = res.dataOrNull!;
      expect(session.user.email, equals('aditya.admin@nimbusdigital.test'));
      expect(session.isAdmin, isTrue);
      expect(session.orgId, equals('org_a1b2c3'));
      expect(session.accessToken, isNotEmpty);
    });

    test('login with invalid password fails with AuthFailure', () async {
      final res = await authRepository.login('aditya.admin@nimbusdigital.test', 'WrongPass!');
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message, contains('Invalid email or password'));
    });

    test('refresh token generates new access token with extended expiration', () async {
      await authRepository.login('aditya.admin@nimbusdigital.test', 'Password123!');
      final refreshRes = await authRepository.refreshToken();
      expect(refreshRes.isSuccess, isTrue);
      final newSession = refreshRes.dataOrNull!;
      expect(newSession.accessToken, contains('mock.access.token.refreshed_'));
    });
  });
}
