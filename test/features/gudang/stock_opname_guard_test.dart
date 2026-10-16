import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/stock_opname_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/persediaan_providers.dart';
import 'package:simlog_mobile/features/gudang/presentation/screens/stock_opname_hub_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserModel _buildUser({required int id, required String name, required List<String> roles}) {
  return UserModel(
    id: id,
    name: name,
    email: '$name@simlogrs.local'.toLowerCase().replaceAll(' ', ''),
    roles: roles,
    permissions: const [],
    gudang: const GudangModel(id: 1, nama: 'Gudang Utama', kode: 'GUD_UTAMA'),
  );
}

Future<void> _pumpScreen(WidgetTester tester, UserModel user) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
        stockOpnameListProvider.overrideWith((ref) => Future.value(<StokOpnameSesiModel>[])),
      ],
      child: const MaterialApp(
        home: StockOpnameHubScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StockOpnameHubScreen FAB RBAC Guard', () {
    testWidgets('renders Inisiasi Opname FAB for petugas_gudang', (tester) async {
      final user = _buildUser(id: 1, name: 'Petugas Gudang', roles: ['petugas_gudang']);
      await _pumpScreen(tester, user);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.widgetWithText(FloatingActionButton, 'Inisiasi Opname'), findsOneWidget);
    });

    testWidgets('renders Inisiasi Opname FAB for kepala_gudang', (tester) async {
      final user = _buildUser(id: 2, name: 'Kepala Gudang', roles: ['kepala_gudang']);
      await _pumpScreen(tester, user);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.widgetWithText(FloatingActionButton, 'Inisiasi Opname'), findsOneWidget);
    });

    testWidgets('hides Inisiasi Opname FAB for petugas_unit', (tester) async {
      final user = _buildUser(id: 3, name: 'Petugas Unit', roles: ['petugas_unit']);
      await _pumpScreen(tester, user);

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.widgetWithText(FloatingActionButton, 'Inisiasi Opname'), findsNothing);
    });

    testWidgets('hides Inisiasi Opname FAB for auditor', (tester) async {
      final user = _buildUser(id: 4, name: 'Auditor', roles: ['auditor']);
      await _pumpScreen(tester, user);

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.widgetWithText(FloatingActionButton, 'Inisiasi Opname'), findsNothing);
    });
  });
}
