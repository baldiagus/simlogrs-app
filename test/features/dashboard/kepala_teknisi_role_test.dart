import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/dashboard/presentation/widgets/ipsrs_shortcut_grid.dart';
import 'package:simlog_mobile/features/dashboard/presentation/widgets/quick_action_grid.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  const kepalaTeknisiUser = UserModel(
    id: 11,
    name: 'Ir. Gunawan, S.T.',
    email: 'karu_ipsrs@simlogrs.local',
    roles: ['kepala_teknisi', 'panel_user'],
    permissions: ['page_TeknisiDashboard', 'page_KepalaUnitDashboard'],
    unit: UnitModel(id: 2, nama: 'Instalasi Pemeliharaan Sarana Rumah Sakit', kode: 'IPSRS'),
  );

  test('UserModel computes isKepalaTeknisi and isKaru correctly while distinguishing from isTeknisi', () {
    expect(kepalaTeknisiUser.isKepalaTeknisi, isTrue);
    expect(kepalaTeknisiUser.isKaru, isTrue);
    expect(kepalaTeknisiUser.isTeknisi, isFalse); // Non-fieldwork so Tab 1 stays Approval Center
  });

  testWidgets('QuickActionGrid renders 4 pilar universal and IpsrsShortcutGrid renders Komando IPSRS', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(kepalaTeknisiUser)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  QuickActionGrid(
                    pendingCount: 3,
                    isKepalaTeknisi: true,
                    onApprovalTap: () {},
                    onRakGudangTap: () {},
                    onAsetTap: () {},
                    onLaporRusakTap: () {},
                  ),
                  const IpsrsShortcutGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aksi Cepat Operasional'), findsOneWidget);
    expect(find.text('Pengadaan'), findsOneWidget);
    expect(find.text('Amprah Ruangan'), findsOneWidget);
    expect(find.text('Sirkulasi Aset'), findsOneWidget);
    expect(find.text('Lapor Rusak'), findsOneWidget);

    expect(find.text('Komando & Lapangan IPSRS'), findsOneWidget);
    expect(find.text('Semua SPK'), findsOneWidget);
    expect(find.text('Lembar Kerja'), findsOneWidget);
    expect(find.text('Jadwal Preventif'), findsOneWidget);
    expect(find.text('Rekam Medis Aset'), findsOneWidget);
  });
}
