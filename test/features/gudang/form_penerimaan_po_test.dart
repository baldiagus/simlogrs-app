import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/gudang/data/models/rak_model.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/gudang_provider.dart';
import 'package:simlog_mobile/features/gudang/presentation/screens/form_penerimaan_po_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const mockPo = PoInboundHeaderModel(
    id: 2,
    kodePo: 'PO-2026-002',
    pemasok: 'CV Graha Logistik Medis',
    tanggalPo: '2026-09-30',
    estimasiTanggalKirim: null,
    status: 'DIKIRIM_VENDOR',
    totalItem: 1,
    items: [
      PoInboundItemModel(
        id: 1,
        barangId: 101,
        kodeBarang: 'BRG-2026-001',
        namaBarang: 'Kertas A4',
        satuan: 'Rim (500 Lembar)',
        jumlahDipesan: 50,
        jumlahSudahDiterima: 0,
        sisaKebutuhan: 50,
        hargaSatuan: 55000,
      ),
    ],
  );

  const mockRaks = [
    RakModel(
      id: 1,
      kode: 'BIN-C1',
      nama: 'Bin C1 - Rak Medis Lantai 1',
      status: 'AKTIF',
      gudangId: 1,
      namaGudang: 'Gudang Utama',
      totalBarang: 5,
      totalAset: 0,
    ),
  ];

  const gudangUser = UserModel(
    id: 1,
    name: 'Petugas Gudang',
    email: 'gudang@simlogrs.local',
    roles: ['petugas_gudang'],
    permissions: ['create_gudang_stok::penerimaan::po'],
  );

  testWidgets('FormPenerimaanPoScreen displays clean item card and reactive total format', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(gudangUser)),
          daftarRakProvider.overrideWith((ref) => Future.value(mockRaks)),
        ],
        child: const MaterialApp(
          home: FormPenerimaanPoScreen(po: mockPo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Verify Header Item & Satuan
    expect(find.text('Kertas A4'), findsOneWidget);
    expect(find.text('Satuan: Rim (500 Lembar)'), findsOneWidget);

    // Verify Bottom Bar Format matching Image #2: 50 Barang (1 Jenis)
    expect(find.text('Total Diterima:'), findsOneWidget);
    expect(find.text('50 Barang (1 Jenis)'), findsOneWidget);

    // Tap '-' button on stepper to decrease quantity
    final minusButton = find.byIcon(LucideIcons.minus);
    expect(minusButton, findsOneWidget);
    await tester.tap(minusButton);
    await tester.pumpAndSettle();

    expect(find.text('49 Barang (1 Jenis)'), findsOneWidget);
  });

  testWidgets('FormPenerimaanPoScreen renders cleanly on narrow 320px viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(gudangUser)),
          daftarRakProvider.overrideWith((ref) => Future.value(mockRaks)),
        ],
        child: const MaterialApp(
          home: FormPenerimaanPoScreen(po: mockPo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Kertas A4'), findsOneWidget);
    expect(find.text('Total Diterima:'), findsOneWidget);
  });

  Future<void> pumpForm(WidgetTester tester, UserModel user) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
          daftarRakProvider.overrideWith((ref) => Future.value(mockRaks)),
        ],
        child: const MaterialApp(home: FormPenerimaanPoScreen(po: mockPo)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Field Jumlah Rusak tampil dengan teks bantu stok bersih', (tester) async {
    await pumpForm(tester, gudangUser);
    expect(find.text('Jumlah Rusak'), findsOneWidget);
    expect(find.text('Stok bersih: diterima - rusak'), findsOneWidget);
  });

  testWidgets('Jumlah rusak melebihi diterima ditolak validasi', (tester) async {
    await pumpForm(tester, gudangUser);
    await tester.enterText(find.byKey(const ValueKey('jumlah-rusak-field')), '51');
    await tester.enterText(find.byType(TextFormField).first, 'SJ-1');
    await tester.tap(find.text('Simpan ke Stok Gudang'));
    await tester.pumpAndSettle();
    expect(find.text('Jumlah rusak tidak boleh melebihi jumlah diterima'), findsOneWidget);
  });

  testWidgets('Tombol Tolak Kiriman Vendor terlihat untuk penerima, ikon AppBar hilang', (tester) async {
    await pumpForm(tester, gudangUser);
    expect(find.text('Tolak Kiriman Vendor'), findsOneWidget);
    expect(find.byTooltip('Tolak Kiriman Fisik'), findsNothing);
  });

  testWidgets('Tombol Tolak Kiriman Vendor tersembunyi tanpa izin terima', (tester) async {
    const viewer = UserModel(
      id: 9,
      name: 'Viewer',
      email: 'v@simlogrs.local',
      roles: ['auditor'],
      permissions: [],
    );
    await pumpForm(tester, viewer);
    expect(find.text('Tolak Kiriman Vendor'), findsNothing);
  });
}
