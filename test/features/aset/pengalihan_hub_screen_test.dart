import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/pengalihan_hub_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testKaruUser = UserModel(
    id: 1,
    name: 'Karu IGD',
    email: 'karu@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: ['layanan_unit::approval::peminjaman'],
    unit: UnitModel(id: 3, nama: 'IGD', kode: 'IGD'),
  );

  final dummyPengalihan = [
    const PengalihanItemModel(
      id: 50,
      kode: 'TRF-202610-050',
      tipe: 'ASET',
      tipeAsal: 'RUANGAN',
      asalNama: 'IGD',
      tipeTujuan: 'RUANGAN',
      tujuanNama: 'ICU',
      status: 'DIAJUKAN',
      tanggalPengalihan: '2026-10-07',
      namaItem: 'Ventilator Hamilton C1',
      jumlah: 2,
      alasan: 'Alat dialihkan darurat ke ICU',
      canCancel: true,
      canApprove: true,
      items: [
        PengalihanDetailItem(id: 101, kodeAset: 'AST-VENT-001'),
        PengalihanDetailItem(id: 102, kodeAset: 'AST-VENT-002'),
      ],
    ),
  ];

  testWidgets('PengalihanHubScreen renders Aktif, Otorisasi, and Riwayat tabs and displays transfer items', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testKaruUser)),
          daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(dummyPengalihan)),
          daftarPengalihanProvider('otorisasi').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
        ],
        child: const MaterialApp(
          home: PengalihanHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify tabs exist
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Otorisasi'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);

    // Verify transfer item details
    expect(find.text('TRF-202610-050'), findsOneWidget);
    expect(find.text('Ventilator Hamilton C1'), findsOneWidget);
    expect(find.textContaining('IGD ➔ ICU'), findsOneWidget);

    // Verify asset detail info (jumlah + kode aset)
    expect(find.text('2 unit'), findsOneWidget);
    expect(find.textContaining('AST-VENT-001'), findsOneWidget);
    expect(find.textContaining('AST-VENT-002'), findsOneWidget);

    // Verify dynamic FAB for ASET category
    expect(find.text('Ajukan Pengalihan Aset'), findsOneWidget);
  });
}
