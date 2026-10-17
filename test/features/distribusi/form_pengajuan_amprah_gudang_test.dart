import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/form_pengajuan_amprah_screen.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/persediaan_providers.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAmprahActionNotifier extends StateNotifier<AmprahActionState>
    implements AmprahActionNotifier {
  FakeAmprahActionNotifier() : super(const AmprahActionState());

  bool submitCalled = false;
  int? lastGudangId;
  String? lastUrgensi;
  String? lastCatatan;
  List<AmprahCartDraftItem>? lastItems;

  @override
  Future<bool> submitAmprah({
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<AmprahCartDraftItem> items,
  }) async {
    submitCalled = true;
    lastGudangId = gudangId;
    lastUrgensi = urgensi;
    lastCatatan = catatan;
    lastItems = items;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUser = UserModel(
    id: 7,
    name: 'Ns. Budi Santoso, S.Kep',
    email: 'petugasunit@simlogrs.local',
    roles: ['petugas_unit'],
    permissions: ['create_layanan_unit::permintaan::barang'],
    unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
  );

  const dummyGudangs = [
    GudangModel(id: 1, nama: 'Gudang Farmasi Utama', kode: 'GF-01'),
    GudangModel(id: 2, nama: 'Gudang Logistik Umum', kode: 'GL-02'),
  ];

  const item1 = BarangAmprahKatalogModel(
    id: 101,
    kode: 'MED-SYR-01',
    nama: 'Spuit 3cc Terumo',
    tipe: 'HABIS_PAKAI',
    tipeLabel: 'BHP Medis',
    kategori: 'Medis',
    satuan: 'Box',
    merek: 'Terumo',
    stokTersedia: 20,
  );

  const itemInOtherWarehouse = BarangAmprahKatalogModel(
    id: 102,
    kode: 'LOG-KTS-01',
    nama: 'Kertas HVS A4',
    tipe: 'HABIS_PAKAI',
    tipeLabel: 'ATK',
    kategori: 'ATK',
    satuan: 'Rim',
    merek: 'PaperOne',
    stokTersedia: 0,
    bestGudangId: 2,
    bestGudangNama: 'Gudang Logistik Umum',
    bestGudangStok: 50,
  );

  testWidgets('renders warehouse dropdown with master gudang options', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeNotifier = FakeAmprahActionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          masterGudangListProvider.overrideWith((ref) => Future.value(dummyGudangs)),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify label and dropdown field
    expect(find.text('Gudang Tujuan Logistik *'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(find.text('Gudang Farmasi Utama'), findsOneWidget);

    // Open dropdown menu
    await tester.tap(find.text('Gudang Farmasi Utama'));
    await tester.pumpAndSettle();

    // Both options should appear
    expect(find.text('Gudang Farmasi Utama'), findsWidgets);
    expect(find.text('Gudang Logistik Umum'), findsWidgets);
  });

  testWidgets('opening barang picker forwards selected gudangId', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    KatalogAmprahFilterParams? capturedParams;
    final fakeNotifier = FakeAmprahActionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          masterGudangListProvider.overrideWith((ref) => Future.value(dummyGudangs)),
          katalogAmprahProvider.overrideWith((ref, params) {
            capturedParams = params;
            return Future.value([item1]);
          }),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open item picker bottom sheet
    final pickerBtn = find.text('Pilih dari Katalog');
    await tester.ensureVisible(pickerBtn);
    await tester.tap(pickerBtn);
    await tester.pumpAndSettle();

    // Verify forwarded gudangId
    expect(capturedParams, isNotNull);
    expect(capturedParams!.gudangId, equals(1));

    // Verify subtitle in picker sheet header
    expect(find.text('Gudang Tujuan: Gudang Farmasi Utama'), findsOneWidget);
  });

  testWidgets('submitAmprah forwards selected gudangId', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeNotifier = FakeAmprahActionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          masterGudangListProvider.overrideWith((ref) => Future.value(dummyGudangs)),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(initialBarang: item1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final submitBtn = find.text('Kirim Pengajuan Amprah');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(fakeNotifier.submitCalled, isTrue);
    expect(fakeNotifier.lastGudangId, equals(1));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('changing warehouse when cart is not empty prompts confirmation to reset cart', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeNotifier = FakeAmprahActionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          masterGudangListProvider.overrideWith((ref) => Future.value(dummyGudangs)),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(initialBarang: item1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Cart initially has item1
    expect(find.text('Spuit 3cc Terumo'), findsOneWidget);
    expect(find.text('Gudang Farmasi Utama'), findsOneWidget);

    // Tap dropdown to select Gudang Logistik Umum
    await tester.tap(find.text('Gudang Farmasi Utama'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gudang Logistik Umum').last);
    await tester.pumpAndSettle();

    // Confirmation dialog message shown
    expect(
      find.text('Mengubah gudang logistik akan mengosongkan keranjang barang karena ketersediaan stok terikat pada gudang pilihan. Lanjutkan?'),
      findsOneWidget,
    );

    // Cancel change
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // Cart retained, warehouse remains Gudang Farmasi Utama
    expect(find.text('Spuit 3cc Terumo'), findsOneWidget);
    expect(find.text('Gudang Farmasi Utama'), findsOneWidget);

    // Select Gudang Logistik Umum again and confirm
    await tester.tap(find.text('Gudang Farmasi Utama'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gudang Logistik Umum').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Mengubah gudang logistik akan mengosongkan keranjang barang karena ketersediaan stok terikat pada gudang pilihan. Lanjutkan?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ya, Lanjutkan'));
    await tester.pumpAndSettle();

    // Warehouse updated to Gudang Logistik Umum
    expect(find.text('Gudang Logistik Umum'), findsOneWidget);

    // Cart is emptied
    expect(find.text('Spuit 3cc Terumo'), findsNothing);
    expect(find.text('Belum Ada Barang Dipilih'), findsOneWidget);
  });

  testWidgets('selecting item with bestGudangId when cart is empty automatically updates selected warehouse and adds item', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeNotifier = FakeAmprahActionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          masterGudangListProvider.overrideWith((ref) => Future.value(dummyGudangs)),
          katalogAmprahProvider.overrideWith((ref, params) => Future.value([itemInOtherWarehouse])),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Gudang Farmasi Utama'), findsOneWidget);
    expect(find.text('Belum Ada Barang Dipilih'), findsOneWidget);

    final pickerBtn = find.text('Pilih dari Katalog');
    await tester.ensureVisible(pickerBtn);
    await tester.tap(pickerBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tersedia 50 Rim di Gudang Logistik Umum'), findsOneWidget);

    await tester.tap(find.text('Kertas HVS A4'));
    await tester.pumpAndSettle();

    expect(find.text('Gudang Logistik Umum'), findsOneWidget);
    expect(find.text('Kertas HVS A4'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('selecting item from different warehouse when cart is not empty displays confirmation dialog to switch warehouse and reset cart', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeNotifier = FakeAmprahActionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          masterGudangListProvider.overrideWith((ref) => Future.value(dummyGudangs)),
          katalogAmprahProvider.overrideWith((ref, params) => Future.value([itemInOtherWarehouse])),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(initialBarang: item1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Spuit 3cc Terumo'), findsOneWidget);
    expect(find.text('Gudang Farmasi Utama'), findsOneWidget);

    final pickerBtn = find.text('Tambah');
    await tester.ensureVisible(pickerBtn);
    await tester.tap(pickerBtn);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kertas HVS A4'));
    await tester.pumpAndSettle();

    expect(find.text('Ganti Gudang Tujuan?'), findsOneWidget);
    expect(
      find.text('Komoditas Kertas HVS A4 tersedia di Gudang Logistik Umum. Pengajuan amprah dalam satu dokumen harus ditujukan ke satu gudang yang sama. Ganti gudang tujuan dan mulai daftar baru?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Spuit 3cc Terumo'), findsOneWidget);
    expect(find.text('Kertas HVS A4'), findsNothing);
    expect(find.text('Gudang Farmasi Utama'), findsOneWidget);

    await tester.tap(pickerBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kertas HVS A4'));
    await tester.pumpAndSettle();

    expect(find.text('Ganti Gudang Tujuan?'), findsOneWidget);
    await tester.tap(find.text('Ya, Ganti Gudang'));
    await tester.pumpAndSettle();

    expect(find.text('Gudang Logistik Umum'), findsOneWidget);
    expect(find.text('Spuit 3cc Terumo'), findsNothing);
    expect(find.text('Kertas HVS A4'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}
