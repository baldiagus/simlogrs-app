import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/aset_tersedia_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/modal_pengalihan_aset_sheet.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/peminjaman_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePengalihanActionNotifier extends StateNotifier<PengalihanActionState>
    implements PengalihanActionNotifier {
  FakePengalihanActionNotifier() : super(const PengalihanActionState());

  bool ajukanCalled = false;
  Map<String, dynamic>? lastPayload;

  @override
  Future<bool> ajukanPengalihan(Map<String, dynamic> payload) async {
    ajukanCalled = true;
    lastPayload = payload;
    return true;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUser = UserModel(
    id: 5,
    name: 'Karu ICU',
    email: 'karu_icu@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: [],
    unit: UnitModel(id: 4, nama: 'Intensive Care Unit (ICU)', kode: 'ICU'),
  );

  const testAset = AsetTersediaModel(
    id: 101,
    kodeAset: 'AST-IGD-001',
    nomorSeri: 'SN-BED-001',
    namaKomoditas: 'Bed Pasien Elektrik',
    tipePenyedia: 'RUANGAN',
    penyediaId: 3,
    namaPenyedia: 'Instalasi Gawat Darurat (IGD)',
    kategori: 'Medis',
    satuan: 'Unit',
    merek: 'Paramount',
    kondisi: 'BAIK',
    lokasiLengkap: 'Ruang Resusitasi IGD',
  );


  testWidgets('ModalPengalihanAsetSheet renders Tahap 1 & Tahap 2 cards, locks origin, and submits', (tester) async {
    final fakeNotifier = FakePengalihanActionNotifier();
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });


    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          katalogAsetPengalihanProvider('').overrideWith((ref) => Future.value([testAset])),
          katalogAsetTersediaProvider('').overrideWith((ref) => Future.value([testAset])),
          pengalihanActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ModalPengalihanAsetSheet(aset: testAset),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Tahap 1 and Tahap 2 card headers
    expect(find.text('Tahap 1: Komoditas & Fasilitas Asal (Sumber)'), findsOneWidget);
    expect(find.text('Tahap 2: Kuantitas & Alasan'), findsOneWidget);

    // Verify locked destination unit is displayed
    expect(find.text('Intensive Care Unit (ICU)'), findsWidgets);
    expect(find.textContaining('Instalasi Gawat Darurat (IGD)'), findsWidgets);
    // Verify submit button exists
    final submitBtn = find.text('Ajukan Pengalihan Aset');
    expect(submitBtn, findsOneWidget);

    // Fill reason
    await tester.enterText(
      find.byKey(const Key('field_alasan_pengalihan')),
      'Relokasi permanen ke ICU karena penataan ruang',
    );
    await tester.pumpAndSettle();

    // Tap submit
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(fakeNotifier.ajukanCalled, isTrue);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('ModalPengalihanAsetSheet renders standalone dropdown selector when opened without initial asset', (tester) async {
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
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          katalogAsetPengalihanProvider('').overrideWith((ref) => Future.value([testAset])),
          katalogAsetTersediaProvider('').overrideWith((ref) => Future.value([testAset])),
          pengalihanActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ModalPengalihanAsetSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify standalone asset dropdown is rendered
    final dropdownFinder = find.byKey(const Key('dropdown_aset_asal'));
    expect(dropdownFinder, findsOneWidget);

    // Select asset
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Bed Pasien Elektrik').last);
    await tester.pumpAndSettle();

    // Fill reason and submit
    await tester.enterText(
      find.byKey(const Key('field_alasan_pengalihan')),
      'Relokasi mandiri alat medis ke ICU',
    );
    await tester.pumpAndSettle();
    final submitBtn = find.text('Ajukan Pengalihan Aset');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(fakeNotifier.ajukanCalled, isTrue);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('ModalPengalihanAsetSheet dynamically aggregates multi-unit quantity and submits all selected asset IDs', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeNotifier = FakePengalihanActionNotifier();

    const testAset2 = AsetTersediaModel(
      id: 102,
      kodeAset: 'AST-IGD-002',
      nomorSeri: 'SN-BED-002',
      namaKomoditas: 'Bed Pasien Elektrik',
      tipePenyedia: 'RUANGAN',
      penyediaId: 3,
      namaPenyedia: 'Instalasi Gawat Darurat (IGD)',
      kategori: 'Medis',
      satuan: 'Unit',
      merek: 'Paramount',
      kondisi: 'BAIK',
      lokasiLengkap: 'Ruang Resusitasi IGD',
    );

    const testAset3 = AsetTersediaModel(
      id: 103,
      kodeAset: 'AST-IGD-003',
      nomorSeri: 'SN-BED-003',
      namaKomoditas: 'Bed Pasien Elektrik',
      tipePenyedia: 'RUANGAN',
      penyediaId: 3,
      namaPenyedia: 'Instalasi Gawat Darurat (IGD)',
      kategori: 'Medis',
      satuan: 'Unit',
      merek: 'Paramount',
      kondisi: 'BAIK',
      lokasiLengkap: 'Ruang Resusitasi IGD',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          katalogAsetPengalihanProvider('').overrideWith((ref) => Future.value([testAset, testAset2, testAset3])),
          katalogAsetTersediaProvider('').overrideWith((ref) => Future.value([testAset, testAset2, testAset3])),
          pengalihanActionProvider.overrideWith((ref) => fakeNotifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ModalPengalihanAsetSheet(aset: testAset),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dynamic multi-unit text
    expect(find.text('Tersedia: 3 unit di Instalasi Gawat Darurat (IGD)'), findsOneWidget);

    // Tap stepper plus button twice to select 3 units
    final plusBtn = find.byIcon(LucideIcons.plus);
    expect(plusBtn, findsOneWidget);
    await tester.tap(plusBtn);
    await tester.pumpAndSettle();
    await tester.tap(plusBtn);
    await tester.pumpAndSettle();

    // Verify quantity is now 3
    expect(find.text('3'), findsOneWidget);

    // Fill reason
    await tester.enterText(
      find.byKey(const Key('field_alasan_pengalihan')),
      'Kebutuhan darurat 3 unit bed di ruang ICU',
    );
    await tester.pumpAndSettle();

    // Submit
    final submitBtn = find.text('Ajukan Pengalihan Aset');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(fakeNotifier.ajukanCalled, isTrue);
    expect(fakeNotifier.lastPayload?['jumlah'], 3);
    expect(fakeNotifier.lastPayload?['aset_ids'], [101, 102, 103]);
    await tester.pump(const Duration(seconds: 4));
  });
}
