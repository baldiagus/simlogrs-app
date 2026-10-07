import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/peminjaman_aset_model.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/peminjaman_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
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
      jumlah: 1,
      alasan: 'Alat dialihkan darurat ke ICU',
      canCancel: true,
      canApprove: true,
    ),
  ];

  testWidgets('SirkulasiAsetHubScreen renders Pengalihan tab and lists transfer items', (tester) async {
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
          daftarPeminjamanSayaProvider.overrideWith((ref) => Future.value(<PeminjamanAsetModel>[])),
          daftarApprovalPeminjamanProvider.overrideWith((ref) => Future.value(<ApprovalPeminjamanModel>[])),
          daftarPeminjamanAktifDipinjamProvider.overrideWith((ref) => Future.value(<PeminjamanAsetModel>[])),
          daftarPeminjamanAktifDipinjamkanProvider.overrideWith((ref) => Future.value(<PeminjamanAsetModel>[])),
          daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(dummyPengalihan)),
        ],
        child: const MaterialApp(
          home: SirkulasiAsetHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Tab Pengalihan exists
    final pengalihanTab = find.text('Pengalihan');
    expect(pengalihanTab, findsOneWidget);

    // Tap Tab Pengalihan
    await tester.tap(pengalihanTab);
    await tester.pumpAndSettle();

    // Verify transfer item details are shown
    expect(find.text('TRF-202610-050'), findsOneWidget);
    expect(find.text('Ventilator Hamilton C1'), findsOneWidget);
    expect(find.textContaining('IGD ➔ ICU'), findsOneWidget);
  });
}
