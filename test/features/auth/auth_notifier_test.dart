import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:simlog_mobile/core/providers/core_providers.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockErrorAuthRepository extends Fake implements AuthRepository {
  @override
  Future<UserModel> login({required String email, required String password, String? deviceName}) async {
    throw Exception('Kombinasi email atau kata sandi tidak valid.');
  }

  @override
  Future<bool> hasValidToken() async => false;

  @override
  Future<UserModel?> getCachedUser() async => null;
}

void main() {
  test('AuthNotifier sets unauthenticated errorMessage on failed login and clears error on clearError()', () async {
    final repo = MockErrorAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authStateProvider.notifier);
    await notifier.login(email: 'wrong@simlogrs.local', password: 'wrong');

    var state = container.read(authStateProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.errorMessage, contains('Kombinasi email atau kata sandi tidak valid.'));

    // Test clearError resets the errorMessage
    notifier.clearError();
    state = container.read(authStateProvider);
    expect(state.errorMessage, isNull);
  });
}
