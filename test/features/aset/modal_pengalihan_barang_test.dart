import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/modal_pengalihan_barang_sheet.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/master/data/models/master_barang_item_model.dart';
import 'package:simlog_mobile/features/master/presentation/providers/master_barang_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePengalihanActionNotifier extends StateNotifier<PengalihanActionState>
    implements PengalihanActionNotifier {
  FakePengalihanActionNotifier() : super(const PengalihanActionState());

  bool ajukanBarangCalled = false;

  @override
  Future<bool> ajukanPengalihanBarang(Map<String, dynamic> payload) async {
    ajukanBarangCalled = true;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testGudangUser = UserModel(
    id: 3,
    name: 'Hendra Kusuma, S.T.',
    email: 'kepalagudang@simlogrs.local',
    roles: ['kepala_gudang'],
    permissions: [],
    gudang: GudangModel(id: 1, nama: 'Gudang Sentral Logistik Non-Medis', kode: 'GUD_SENTRAL'),
  );

  final dummyBarangs = [
    const MasterBarangItemModel(
      id: 2,
      kode: 'BRG-2026-002',
      nama: 'Kertas A4',
      tipe: 'HABIS_PAKAI',
      tipeLabel: 'Habis Pakai',
      kategori: 'ATK',
      satuan: 'Rim',
      simbolSatuan: 'Rim',
      merek: 'PaperOne',
      pemasok: 'PT Supplier',
      hargaBeliTerakhir: 50000,
      hargaEstimasi: 50000,
      stokMinimum: 5,
      stokMaksimum: 100,
      titikPesan: 10,
      status: 'AKTIF',
      stokGudang: 42,
      stokRuangan: 0,
      totalAset: 0,
    ),
  ];

  final dummyGudangs = [
    const GudangModel(id: 1, nama: 'Gudang Sentral Logistik Non-Medis', kode: 'GUD_SENTRAL'),
    const GudangModel(id: 2, nama: 'Gudang Suku Cadang IPSRS', kode: 'GUD_IPSRS'),
    const GudangModel(id: 3, nama: 'Gudang ATK & Cetakan', kode: 'GUD_ATK'),
  ];

  testWidgets('ModalPengalihanBarangSheet renders form, locks destination, and submits transfer', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeNotifier = FakePengalihanActionNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testGudangUser)),
          masterBarangListProvider.overrideWith((ref) => Future.value(dummyBarangs)),
          masterGudangListProvider.overrideWith((ref) => Future.value(dummyGudangs)),
          pengalihanActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ModalPengalihanBarangSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Tahap 1 and Tahap 2 card headers
    expect(find.text('Tahap 1: Komoditas & Fasilitas Asal'), findsOneWidget);
    expect(find.text('Tahap 2: Kuantitas & Alasan'), findsOneWidget);

    // Verify locked destination warehouse is displayed
    expect(find.text('Gudang Sentral Logistik Non-Medis'), findsWidgets);

    // Verify submit button exists
    final submitBtn = find.text('Ajukan Pengalihan Barang');
    expect(submitBtn, findsOneWidget);

    // Fill reason
    await tester.enterText(
      find.byKey(const Key('field_alasan_barang')),
      'Kebutuhan mendesak restok kertas di gudang sentral',
    );
    await tester.pumpAndSettle();

    // Tap submit (will trigger validation error for origin warehouse if not picked)
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Select origin warehouse from dropdown
    final dropdownFinder = find.byKey(const Key('dropdown_gudang_asal_barang'));
    expect(dropdownFinder, findsOneWidget);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Tap Gudang ATK
    final optionGudangAtk = find.text('Gudang ATK & Cetakan').last;
    await tester.tap(optionGudangAtk);
    await tester.pumpAndSettle();

    // Select barang from dropdown
    final barangDropdown = find.byKey(const Key('dropdown_barang_logistik'));
    expect(barangDropdown, findsOneWidget);
    await tester.tap(barangDropdown);
    await tester.pumpAndSettle();
    final optionKertas = find.textContaining('Kertas A4').last;
    await tester.tap(optionKertas);
    await tester.pumpAndSettle();

    // Tap submit again
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(fakeNotifier.ajukanBarangCalled, isTrue);
    await tester.pump(const Duration(seconds: 4));
  });
}
