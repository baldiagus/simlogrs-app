import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/form_pengajuan_amprah_screen.dart';
import 'package:simlog_mobile/features/distribusi/data/repositories/distribusi_repository.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAmprahActionNotifier extends StateNotifier<AmprahActionState>
    implements AmprahActionNotifier {
  FakeAmprahActionNotifier() : super(const AmprahActionState());

  bool submitCalled = false;
  List<AmprahCartDraftItem>? lastItems;

  @override
  @override
  Future<bool> submitAmprah({
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<AmprahCartDraftItem> items,
  }) async {
    submitCalled = true;
    lastItems = items;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDistribusiSubmitRepository implements DistribusiRepository {
  bool submitCalled = false;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>> submitAmprah({
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    submitCalled = true;
    lastPayload = {
      'gudang_id': gudangId,
      'urgensi': urgensi,
      'catatan': catatan,
      'items': items,
    };
    return {'id': 99, 'kode': 'REQ-202610-099'};
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

  const itemZeroStock = BarangAmprahKatalogModel(
    id: 101,
    kode: 'MED-SYR-01',
    nama: 'Spuit 3cc Terumo',
    tipe: 'HABIS_PAKAI',
    tipeLabel: 'BHP Medis',
    kategori: 'Medis',
    satuan: 'Box',
    merek: 'Terumo',
    stokTersedia: 0,
  );

  const itemWithStock = BarangAmprahKatalogModel(
    id: 102,
    kode: 'MED-INF-01',
    nama: 'Infus Set Dewasa',
    tipe: 'HABIS_PAKAI',
    tipeLabel: 'BHP Medis',
    kategori: 'Medis',
    satuan: 'Pcs',
    merek: 'Otsuka',
    stokTersedia: 10,
  );

  testWidgets('can add zero stock item to amprah cart and shows backorder indication', (tester) async {
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
          katalogAmprahProvider(const KatalogAmprahFilterParams()).overrideWith((ref) => Future.value([itemZeroStock])),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open item picker bottom sheet
    await tester.tap(find.text('Pilih dari Katalog'));
    await tester.pumpAndSettle();

    // Tap zero stock item
    await tester.tap(find.text('Spuit 3cc Terumo'));
    await tester.pumpAndSettle();

    // Item should be in cart
    expect(find.text('Spuit 3cc Terumo'), findsOneWidget);
    // Should display backorder / hutang gudang notice
    expect(find.textContaining('Backorder', findRichText: true), findsWidgets);
  });

  testWidgets('stepper can exceed warehouse stock and shows backorder delta', (tester) async {
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
          katalogAmprahProvider(const KatalogAmprahFilterParams()).overrideWith((ref) => Future.value([itemWithStock])),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(initialBarang: itemWithStock),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initial quantity is 1
    expect(find.text('1'), findsWidgets);

    // Increase quantity past 10 (tap plus icon multiple times or enter text)
    final stepperPlusBtn = find.descendant(
      of: find.byKey(const Key('stepper_amprah_item')),
      matching: find.byIcon(LucideIcons.plus),
    );
    expect(stepperPlusBtn, findsOneWidget);

    for (int i = 0; i < 14; i++) {
      await tester.tap(stepperPlusBtn);
      await tester.pumpAndSettle();
    }

    // Quantity should now be 15 (exceeding stock 10)
    expect(find.text('15'), findsWidgets);
    // Should show backorder delta notice: Selisih 5 Pcs
    expect(find.textContaining('Selisih 5 Pcs', findRichText: true), findsOneWidget);
  });

  testWidgets('submit amprah with quantity exceeding warehouse stock succeeds without error', (tester) async {
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
          katalogAmprahProvider(const KatalogAmprahFilterParams()).overrideWith((ref) => Future.value([itemWithStock])),
          amprahActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: FormPengajuanAmprahScreen(initialBarang: itemWithStock),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Increase quantity to 15 (exceeding stock 10)
    final stepperPlusBtn = find.descendant(
      of: find.byKey(const Key('stepper_amprah_item')),
      matching: find.byIcon(LucideIcons.plus),
    );
    for (int i = 0; i < 14; i++) {
      await tester.tap(stepperPlusBtn);
      await tester.pumpAndSettle();
    }
    // Submit form
    final submitBtn = find.text('Kirim Pengajuan Amprah');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(fakeNotifier.submitCalled, isTrue);
    expect(fakeNotifier.lastItems?.first.jumlah, 15);
    await tester.pump(const Duration(seconds: 4));
  });

  test('provider submitAmprah with stok 0 item and quantity above stock sends them to repository', () async {
    final fakeRepo = FakeDistribusiSubmitRepository();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
        distribusiRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final draftZeroStock = AmprahCartDraftItem(
      barang: itemZeroStock,
      jumlah: 3,
    );
    final draftAboveStock = AmprahCartDraftItem(
      barang: itemWithStock,
      jumlah: 15,
    );

    final notifier = container.read(amprahActionProvider.notifier);
    final ok = await notifier.submitAmprah(
      urgensi: 'REGULER',
      items: [draftZeroStock, draftAboveStock],
    );

    expect(ok, isTrue);
    expect(fakeRepo.submitCalled, isTrue);
    final sentItems = fakeRepo.lastPayload?['items'] as List<Map<String, dynamic>>?;
    expect(sentItems, isNotNull);
    expect(sentItems!.length, 2);
    expect(sentItems[0]['barang_id'], itemZeroStock.id);
    expect(sentItems[0]['jumlah'], 3);
    expect(sentItems[1]['barang_id'], itemWithStock.id);
    expect(sentItems[1]['jumlah'], 15);
  });
}
