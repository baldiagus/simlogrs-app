import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/dashboard/presentation/widgets/user_top_bar.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('UserTopBar renders without overflow on narrow 320px viewport with long names', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const testUser = UserModel(
      id: 8,
      name: 'Drs. H. Mulyono, M.Kes, Sp.PK(K)',
      email: 'manajemen@simlogrs.local',
      username: 'manajemen',
      roles: ['manajemen'],
      permissions: ['page_ManajemenDashboard'],
      unit: UnitModel(
        id: 8,
        nama: 'Direktorat & Manajemen Eksekutif Rumah Sakit Sentral',
        kode: 'DIREKSI_SENTRAL_RS',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: UserTopBar(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(UserTopBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
