import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/dashboard/presentation/widgets/quick_action_grid.dart';

void main() {
  test('UserModel computes isKepalaTeknisi and isKaru correctly while distinguishing from isTeknisi', () {
    const kepalaTeknisiUser = UserModel(
      id: 11,
      name: 'Ir. Gunawan, S.T.',
      email: 'karu_ipsrs@simlogrs.local',
      roles: ['kepala_teknisi', 'panel_user'],
      permissions: ['page_TeknisiDashboard', 'page_KepalaUnitDashboard'],
      unit: UnitModel(id: 2, nama: 'Instalasi Pemeliharaan Sarana Rumah Sakit', kode: 'IPSRS'),
    );

    expect(kepalaTeknisiUser.isKepalaTeknisi, isTrue);
    expect(kepalaTeknisiUser.isKaru, isTrue);
    expect(kepalaTeknisiUser.isTeknisi, isFalse); // Non-fieldwork so Tab 1 stays Approval Center
  });

  testWidgets('QuickActionGrid renders Aksi Komando & Disposisi IPSRS for isKepalaTeknisi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickActionGrid(
            pendingCount: 3,
            isKepalaTeknisi: true,
            onApprovalTap: () {},
            onRakGudangTap: () {},
            onAsetTap: () {},
            onLaporRusakTap: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aksi Komando & Disposisi IPSRS'), findsOneWidget);
    expect(find.text('Atur Tiket Servis'), findsOneWidget);
    expect(find.text('Semua SPK'), findsOneWidget);
    expect(find.text('Otorisasi PR'), findsNothing);
    expect(find.text('Jadwal Preventif'), findsOneWidget);
    expect(find.text('Rekam Medis Aset'), findsOneWidget);
  });
}
