import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_response.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated([String? message]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository, DioClient dioClient) : super(AuthState.initial()) {
    dioClient.onUnauthorized = handleUnauthorized;
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = AuthState.loading();
    try {
      final hasToken = await _repository.hasValidToken();
      if (!hasToken) {
        state = AuthState.unauthenticated();
        return;
      }

      final cachedUser = await _repository.getCachedUser();
      if (cachedUser != null) {
        state = AuthState.authenticated(cachedUser);
      }

      final user = await _repository.getMe();
      state = AuthState.authenticated(user);
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );
      state = AuthState.authenticated(user);
    } on ApiException catch (e) {
      state = AuthState.unauthenticated(e.message);
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    await _repository.logout();
    state = AuthState.unauthenticated();
  }

  void handleUnauthorized() {
    state = AuthState.unauthenticated('Sesi Anda telah berakhir. Silakan login kembali.');
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final dioClient = ref.watch(dioClientProvider);
  return AuthNotifier(repository, dioClient);
});
