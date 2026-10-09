import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/maintenance/data/models/tiket_maintenance_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/tiket_maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/detail_tiket_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/lapor_cepat_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/lapor_rusak_hub_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUser = UserModel(
    id: 1,
    name: 'Karu Melati',
    email: 'karu@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: ['page_KepalaUnitDashboard'],
    unit: UnitModel(id: 3, nama: 'Ruang Melati', kode: 'MELATI'),
  );

  const tiketAktif = TiketMaintenanceModel(
    id: 10,
    kode: 'MNT-202610-001',
    status: 'SEDANG_DIKERJAKAN',
    prioritas: 'CITO',
    deskripsiMasalah: 'Layar sentuh tidak merespons sentuhan perawat',
    dibuatPada: '2026-10-08 08:30',
    unit: 'Ruang Melati',
    pelapor: 'Ns. Siti',
    canCancel: false,
    aset: {
      'id': 5,
      'kode_aset': 'AST-2026-001',
      'nama': 'Ventilator Transport ICU',
      'nomor_seri': 'SN-VENT-01',
    },
  );

  const tiketSelesai = TiketMaintenanceModel(
    id: 9,
    kode: 'MNT-202610-002',
    status: 'SELESAI',
    prioritas: 'SEDANG',
    deskripsiMasalah: 'Motor pengatur ketinggian macet',
    dibuatPada: '2026-10-07 10:15',
    unit: 'Ruang Melati',
    pelapor: 'Ns. Siti',
    canCancel: false,
    aset: {
      'id': 6,
      'kode_aset': 'AST-2026-002',
      'nama': 'Bed Pasien Elektrik',
      'nomor_seri': 'SN-BED-02',
    },
  );

  const detailModel = TiketDetailModel(
    id: 9,
    kode: 'MNT-202610-002',
    status: 'SELESAI',
    prioritas: 'SEDANG',
    deskripsiMasalah: 'Motor pengatur ketinggian macet',
    dibuatPada: '2026-10-07 10:15',
    unit: 'Ruang Melati',
    pelapor: 'Ns. Siti',
    canCancel: false,
    aset: {
      'id': 6,
      'kode_aset': 'AST-2026-002',
      'nama': 'Bed Pasien Elektrik',
      'nomor_seri': 'SN-BED-02',
    },
    penugasan: [],
    riwayatLog: [],
  );

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
        daftarTiketUnitProvider.overrideWith(
          (ref, params) => Future.value([tiketAktif, tiketSelesai]),
        ),
        detailTiketUnitProvider.overrideWith(
          (ref, id) => Future.value(detailModel),
        ),
      ],
      child: const MaterialApp(
        home: LaporRusakHubScreen(),
      ),
    );
  }

  testWidgets('LaporRusakHubScreen partitions active and completed tickets between tabs', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Layanan Lapor Kerusakan'), findsOneWidget);
    expect(find.text('Laporan Aktif'), findsOneWidget);
    expect(find.text('Riwayat Selesai'), findsOneWidget);

    // Tab 1 (Aktif): Shows MNT-202610-001, hides MNT-202610-002
    expect(find.text('MNT-202610-001'), findsOneWidget);
    expect(find.text('MNT-202610-002'), findsNothing);

    // Switch to Tab 2 (Riwayat Selesai)
    await tester.tap(find.text('Riwayat Selesai'));
    await tester.pumpAndSettle();

    // Tab 2: Shows MNT-202610-002, hides MNT-202610-001
    expect(find.text('MNT-202610-002'), findsOneWidget);
    expect(find.text('MNT-202610-001'), findsNothing);

    // Tap ticket item -> navigates to DetailTiketScreen
    await tester.tap(find.text('MNT-202610-002'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailTiketScreen), findsOneWidget);

    // Go back
    Navigator.pop(tester.element(find.byType(DetailTiketScreen)));
    await tester.pumpAndSettle();

    // Tap FAB Lapor Kerusakan -> navigates to LaporCepatScreen
    final fab = find.text('Lapor Kerusakan');
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(find.byType(LaporCepatScreen), findsOneWidget);
  });
}
