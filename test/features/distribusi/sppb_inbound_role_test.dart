import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/data/models/sppb_model.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/amprah_hub_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const dummySppb = SppbHeaderModel(
    id: 1,
    kode: 'SPPB-202610-001',
    gudang: 'Gudang Sentral',
    unit: 'Ruang Melati',
    pengirim: 'Pak Supir Logistik',
    tanggalKirim: '2026-10-09',
    status: 'DIKIRIM',
    totalItem: 1,
    items: [
      SppbDetailItemModel(
        barangId: 10,
        namaBarang: 'Kassa Steril 10x10',
        kodeBarang: 'KSS-01',
        satuan: 'Box',
        jumlahDikirim: 5,
        nomorBatch: 'BATCH-2026-A',
      ),
    ],
  );

  const petugasGudangUser = UserModel(
    id: 2,
    name: 'Joko Gudang',
    email: 'petugasgudang@simlogrs.local',
    roles: ['petugas_gudang'],
    permissions: [],
    gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
  );

  const karuRuanganUser = UserModel(
    id: 3,
    name: 'Karu Melati',
    email: 'karu@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: [],
    unit: UnitModel(id: 3, nama: 'Ruang Melati', kode: 'MELATI'),
  );
  const petugasUnitUser = UserModel(
    id: 4,
    name: 'Staf Unit Melati',
    email: 'stafmelati@simlogrs.local',
    roles: ['petugas_unit'],
    permissions: ['update_layanan_unit::penerimaan::barang'],
    unit: UnitModel(id: 3, nama: 'Ruang Melati', kode: 'MELATI'),
  );

  Widget createWidgetFor(UserModel user) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
        daftarAmprahProvider.overrideWith((ref, params) => Future.value(<AmprahHeaderModel>[])),
        sppbInboundProvider.overrideWith((ref) => Future.value([dummySppb])),
      ],
      child: const MaterialApp(
        home: AmprahHubScreen(),
      ),
    );
  }

  testWidgets('AmprahHubScreen Tab 2 displays destination unit and hides confirmation button for Petugas Gudang', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetFor(petugasGudangUser));
    await tester.pumpAndSettle();

    // Switch to Tab 2: Barang Masuk (SPPB)
    await tester.ensureVisible(find.textContaining('Barang Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Barang Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('SPPB-202610-001'), findsOneWidget);
    // Verifikasi teks tujuan: Dikirim ke Ruang Melati
    expect(find.text('Dikirim ke Ruang Melati'), findsOneWidget);
    // Verifikasi tombol konfirmasi di ruangan TIDAK ADA untuk tim gudang
    expect(find.text('Konfirmasi Terima Barang di Ruangan'), findsNothing);
  });

  testWidgets('AmprahHubScreen Tab 2 displays destination unit and hides confirmation button for Karu Ruangan', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetFor(karuRuanganUser));
    await tester.pumpAndSettle();

    // Switch to Tab 2: Barang Masuk (SPPB)
    await tester.ensureVisible(find.textContaining('Barang Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Barang Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('SPPB-202610-001'), findsOneWidget);
    expect(find.text('Dikirim ke Ruang Melati'), findsOneWidget);
    // Kepala unit tidak memiliki wewenang update_layanan_unit::penerimaan::barang sehingga tombol disembunyikan
    expect(find.text('Konfirmasi Terima Barang di Ruangan'), findsNothing);
  });

  testWidgets('AmprahHubScreen Tab 2 displays destination unit and shows confirmation button for Petugas Unit', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetFor(petugasUnitUser));
    await tester.pumpAndSettle();

    // Switch to Tab 2: Barang Masuk (SPPB)
    await tester.ensureVisible(find.textContaining('Barang Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Barang Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('SPPB-202610-001'), findsOneWidget);
    expect(find.text('Dikirim ke Ruang Melati'), findsOneWidget);
    // Petugas unit memiliki wewenang penerimaan barang sehingga tombol konfirmasi muncul
    expect(find.text('Konfirmasi Terima Barang di Ruangan'), findsOneWidget);
  });
}
