import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/secure_token_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'debug_settings_provider.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserSession session;
  final bool isRefreshingToken;

  const Authenticated(this.session, {this.isRefreshingToken = false});

  Authenticated copyWith({UserSession? session, bool? isRefreshingToken}) {
    return Authenticated(
      session ?? this.session,
      isRefreshingToken: isRefreshingToken ?? this.isRefreshingToken,
    );
  }
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final Failure failure;
  const AuthError(this.failure);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;
  Timer? _tokenRefreshTimer;

  AuthNotifier(this._authRepository) : super(const AuthInitial());

  Future<void> restoreSession() async {
    state = const AuthLoading();
    final res = await _authRepository.restoreSession();
    res.fold(
      (session) {
        if (session != null) {
          state = Authenticated(session);
          _scheduleTokenRefresh(session);
        } else {
          state = const Unauthenticated();
        }
      },
      (failure) => state = const Unauthenticated(),
    );
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    final res = await _authRepository.login(email, password);
    return res.fold(
      (session) {
        state = Authenticated(session);
        _scheduleTokenRefresh(session);
        return true;
      },
      (failure) {
        state = AuthError(failure);
        return false;
      },
    );
  }

  Future<bool> register(String name, String email, String password, String orgId) async {
    state = const AuthLoading();
    final res = await _authRepository.register(name, email, password, orgId);
    return res.fold(
      (session) {
        state = Authenticated(session);
        _scheduleTokenRefresh(session);
        return true;
      },
      (failure) {
        state = AuthError(failure);
        return false;
      },
    );
  }

  Future<void> manualTokenRefresh() async {
    final current = state;
    if (current is Authenticated) {
      state = current.copyWith(isRefreshingToken: true);
      final res = await _authRepository.refreshToken();
      res.fold(
        (newSession) {
          state = Authenticated(newSession);
          _scheduleTokenRefresh(newSession);
        },
        (failure) {
          state = AuthError(failure);
        },
      );
    }
  }

  Future<void> logout() async {
    _tokenRefreshTimer?.cancel();
    await _authRepository.logout();
    state = const Unauthenticated();
  }

  void _scheduleTokenRefresh(UserSession session) {
    _tokenRefreshTimer?.cancel();
    final timeUntilExpiry = session.accessTokenExpiry.difference(DateTime.now());
    final refreshDuration = timeUntilExpiry.inSeconds > 30
        ? Duration(seconds: timeUntilExpiry.inSeconds - 30)
        : const Duration(seconds: 5);

    _tokenRefreshTimer = Timer(refreshDuration, () async {
      final res = await _authRepository.refreshToken();
      res.fold(
        (newSession) {
          if (mounted && state is Authenticated) {
            state = Authenticated(newSession);
            _scheduleTokenRefresh(newSession);
          }
        },
        (failure) {
          if (mounted) state = const Unauthenticated();
        },
      );
    });
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final mockDs = ref.watch(mockDataSourceProvider);
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  return AuthRepositoryImpl(mockDataSource: mockDs, tokenStorage: tokenStorage);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
