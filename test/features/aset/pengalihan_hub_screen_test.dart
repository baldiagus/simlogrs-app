import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/pengalihan_hub_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/aset/presentation/utils/pengalihan_access.dart';
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

    // Verify TabBar is non-scrollable and tabs are distributed evenly
    final TabBar tabBar = tester.widget(find.byType(TabBar));
    expect(tabBar.isScrollable, isFalse);
    expect(tabBar.tabAlignment, isNull);

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

  testWidgets('PengalihanHubScreen isolates Karu to ASET even if selectedKategoriPengalihanProvider is BARANG', (tester) async {
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
          selectedKategoriPengalihanProvider.overrideWith((ref) => 'BARANG'),
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

    // Title must stay 'Pengalihan Aset RS' and not 'Pengalihan Barang Gudang'
    expect(find.text('Pengalihan Aset RS'), findsOneWidget);
    expect(find.text('Pengalihan Barang Gudang'), findsNothing);

    // Category switcher must not be shown for Karu
    expect(find.text('Aset Fisik'), findsNothing);
    expect(find.text('Barang Gudang'), findsNothing);
  });

  testWidgets('PengalihanHubScreen isolates Karu to ASET even if Karu has gudang in profile', (tester) async {
    const karuWithGudang = UserModel(
      id: 10,
      name: 'Karu Dengan Gudang',
      email: 'karu_gudang@simlogrs.local',
      roles: ['kepala_unit'],
      permissions: ['layanan_unit::approval::peminjaman'],
      unit: UnitModel(id: 3, nama: 'IGD', kode: 'IGD'),
      gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
    );

    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(karuWithGudang)),
          selectedKategoriPengalihanProvider.overrideWith((ref) => 'BARANG'),
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

    // Must still strictly lock to ASET
    expect(find.text('Pengalihan Aset RS'), findsOneWidget);
    expect(find.text('Pengalihan Barang Gudang'), findsNothing);
    expect(find.text('Aset Fisik'), findsNothing);
    expect(find.text('Barang Gudang'), findsNothing);
    expect(find.text('Ajukan Pengalihan Aset'), findsOneWidget);
  });

  group('canAccessPengalihanBarang RBAC tests', () {
    test('returns false for kepala_unit and petugas_unit even if gudang is set', () {
      const karu = UserModel(
        id: 1,
        name: 'Karu',
        email: 'karu@simlogrs.local',
        roles: ['kepala_unit'],
        permissions: [],
        gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
      );
      const stafUnit = UserModel(
        id: 2,
        name: 'Staf Unit',
        email: 'staf@simlogrs.local',
        roles: ['petugas_unit'],
        permissions: [],
        gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
      );
      expect(canAccessPengalihanBarang(karu), isFalse);
      expect(canAccessPengalihanBarang(stafUnit), isFalse);
    });

    test('returns true for warehouse roles and admin', () {
      const kagud = UserModel(
        id: 3,
        name: 'Kagud',
        email: 'kagud@simlogrs.local',
        roles: ['kepala_gudang'],
        permissions: [],
      );
      const petugasGudang = UserModel(
        id: 4,
        name: 'Petugas Gudang',
        email: 'petugas@simlogrs.local',
        roles: ['petugas_gudang'],
        permissions: [],
      );
      const adminLogistik = UserModel(
        id: 5,
        name: 'Admin Logistik',
        email: 'admin@simlogrs.local',
        roles: ['admin_logistik'],
        permissions: [],
      );
      const superAdmin = UserModel(
        id: 6,
        name: 'Super Admin',
        email: 'super@simlogrs.local',
        roles: ['super_admin'],
        permissions: [],
      );
      expect(canAccessPengalihanBarang(kagud), isTrue);
      expect(canAccessPengalihanBarang(petugasGudang), isTrue);
      expect(canAccessPengalihanBarang(adminLogistik), isTrue);
      expect(canAccessPengalihanBarang(superAdmin), isTrue);
    });
  });
}
