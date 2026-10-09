import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/master/data/models/detail_barang_model.dart';
import 'package:simlog_mobile/features/master/data/models/master_barang_entity.dart';
import 'package:simlog_mobile/features/master/presentation/providers/master_barang_provider.dart';
import 'package:simlog_mobile/features/master/presentation/screens/detail_barang_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const dummyMaster = MasterBarangItemModel(
    id: 1,
    kode: 'BRG-BHP-001',
    nama: 'Sarung Tangan Medis Sensi',
    tipe: 'HABIS_PAKAI',
    tipeLabel: 'BHP Medis',
    kategori: 'Medis',
    satuan: 'Box',
    simbolSatuan: 'Box',
    merek: 'Sensi',
    pemasok: 'PT Kimia Farma',
    hargaBeliTerakhir: 45000,
    hargaEstimasi: 50000,
    stokMinimum: 10,
    stokMaksimum: 100,
    titikPesan: 20,
    status: 'AKTIF',
    stokGudang: 120,
    stokRuangan: 45,
    totalAset: 0,
  );

  const dummyDetail = DetailBarangModel(
    master: dummyMaster,
    daftarBatch: [
      DaftarBatchItem(
        id: 1,
        nomorBatch: 'LOT-2026-01',
        gudang: 'Gudang Sentral',
        rak: 'B-02',
        jumlah: 80,
        hargaSatuan: 45000,
      ),
    ],
    daftarRuangan: [
      DaftarRuanganItem(
        unit: 'Instalasi Gawat Darurat (IGD)',
        jumlah: 45,
      ),
    ],
    daftarAset: [],
  );

  const petugasUser = UserModel(
    id: 7,
    name: 'Ns. Budi Santoso',
    email: 'perawat@simlogrs.local',
    roles: ['petugas_unit'],
    permissions: ['page_UnitDashboard'],
    unit: UnitModel(id: 1, nama: 'IGD', kode: 'IGD'),
  );

  testWidgets('DetailBarangScreen renders stock KPI cards and sticky bottom action bar', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(petugasUser)),
          detailBarangProvider(1).overrideWith((ref) => Future.value(dummyDetail)),
        ],
        child: const MaterialApp(
          home: DetailBarangScreen(barangId: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Verify stock KPI cards
    expect(find.text('Stok Gudang'), findsOneWidget);
    expect(find.text('120 Box'), findsOneWidget);
    expect(find.text('Di Ruangan'), findsOneWidget);
    expect(find.text('45 Box'), findsNWidgets(2)); // Found in Hero KPI card and Daftar Ruangan list

    // Verify Sticky bottom action bar buttons
    expect(find.text('Tambah PR'), findsOneWidget);
    expect(find.text('Minta Amprah'), findsOneWidget);
  });
}
