import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/aset_tersedia_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/modal_pengalihan_aset_sheet.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/master/presentation/providers/master_barang_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePengalihanActionNotifier extends StateNotifier<PengalihanActionState>
    implements PengalihanActionNotifier {
  FakePengalihanActionNotifier() : super(const PengalihanActionState());

  bool ajukanCalled = false;

  @override
  Future<bool> ajukanPengalihan(Map<String, dynamic> payload) async {
    ajukanCalled = true;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUser = UserModel(
    id: 5,
    name: 'Karu IGD',
    email: 'karu_igd@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: [],
    unit: UnitModel(id: 3, nama: 'Instalasi Gawat Darurat (IGD)', kode: 'IGD'),
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

  final dummyUnits = [
    const UnitModel(id: 3, nama: 'Instalasi Gawat Darurat (IGD)', kode: 'IGD'),
    const UnitModel(id: 4, nama: 'Intensive Care Unit (ICU)', kode: 'ICU'),
    const UnitModel(id: 5, nama: 'Rawat Inap Bedah', kode: 'BEDAH'),
  ];

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
          masterUnitListProvider.overrideWith((ref) => Future.value(dummyUnits)),
          masterGudangListProvider.overrideWith((ref) => Future.value([])),
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
    expect(find.text('Tahap 1: Aset & Fasilitas Asal'), findsOneWidget);
    expect(find.text('Tahap 2: Fasilitas Tujuan & Alasan'), findsOneWidget);

    // Verify locked origin unit is displayed
    expect(find.text('Instalasi Gawat Darurat (IGD)'), findsWidgets);

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
}
