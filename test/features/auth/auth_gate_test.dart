import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/auth/presentation/screens/auth_gate.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AuthGate routes to GantiPasswordWajibScreen when wajibGantiPassword is true', (tester) async {
    const userMustChangePass = UserModel(
      id: 1,
      name: 'Staf Reset',
      email: 'staf@simlogrs.local',
      roles: ['petugas_gudang'],
      permissions: [],
      wajibGantiPassword: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(userMustChangePass)),
        ],
        child: const MaterialApp(
          home: AuthGate(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify it renders Ganti Password screen / indicator
    expect(find.text('Ganti Kata Sandi Wajib'), findsOneWidget);
    expect(find.text('Kata Sandi Baru'), findsOneWidget);
  });
}
