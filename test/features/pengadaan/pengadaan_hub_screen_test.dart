import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/inbound_provider.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/po_model.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/pr_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/screens/pengadaan_hub_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user)
      : super(AuthState(status: AuthStatus.authenticated, user: user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const pengadaanUser = UserModel(
    id: 1,
    name: 'Siti Pengadaan',
    email: 'pengadaan@simlogrs.local',
    roles: ['pengadaan', 'admin_logistik'],
    permissions: ['view_any_gudang_stok::penerimaan::po'],
    unit: UnitModel(id: 4, nama: 'Bagian Pengadaan', kode: 'PENGADAAN'),
  );
  const petugasUnitUser = UserModel(
    id: 2,
    name: 'Ns. Budi',
    email: 'petugas@simlogrs.local',
    roles: ['petugas_unit'],
    permissions: [],
    unit: UnitModel(id: 3, nama: 'Ruang Melati', kode: 'MELATI'),
  );
  const dummyPr = PrHeaderModel(
    id: 10,
    kode: 'PR-202610-001',
    unit: 'Ruang Melati',
    pengaju: 'Ns. Siti',
    tanggalPermintaan: '2026-10-08',
    urgensi: 'NORMAL',
    status: 'DITERUSKAN_KE_PENGADAAN',
    jumlahItem: 2,
    items: [],
  );

  const dummyPo = PesananPembelianModel(
    id: 20,
    kode: 'PO-202610-099',
    pemasokId: 1,
    namaPemasok: 'PT Medika Farma',
    kodePemasok: 'VND-01',
    tanggalPo: '2026-10-08',
    estimasiTanggalKirim: '2026-10-15',
    totalBiaya: 5000000.0,
    syaratPembayaran: 'TEMPO_30_HARI',
    status: 'DITERBITKAN',
    pembuat: 'Budi',
    totalItem: 1,
    items: [],
  );

  const dummyInbound = PoInboundHeaderModel(
    id: 30,
    kodePo: 'PO-202610-099',
    pemasok: 'PT Medika Farma',
    tanggalPo: '2026-10-08',
    status: 'DIKIRIM_VENDOR',
    totalItem: 5,
    items: [],
  );

  Widget createWidget({UserModel user = pengadaanUser}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
        daftarPrProvider.overrideWith((ref) => Future.value([dummyPr])),
        poListProvider.overrideWith((ref) => Future.value([dummyPo])),
        daftarPoInboundProvider.overrideWith((ref) => Future.value([dummyInbound])),
      ],
      child: const MaterialApp(
        home: PengadaanHubScreen(),
      ),
    );
  }

  testWidgets('PengadaanHubScreen renders 3 tabs for Gudang user and switches between tabs', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidget(user: pengadaanUser));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hub Pengadaan & PO'), findsOneWidget);
    expect(find.text('Permintaan (PR)'), findsOneWidget);
    expect(find.text('Pesanan (PO)'), findsOneWidget);
    expect(find.text('Penerimaan Inbound'), findsOneWidget);

    // Tab 1: Shows PR item
    expect(find.text('PR-202610-001'), findsOneWidget);

    // Switch to Tab 2: Pesanan (PO)
    await tester.tap(find.text('Pesanan (PO)'));
    await tester.pumpAndSettle();
    expect(find.text('PO-202610-099'), findsOneWidget);
    expect(find.text('Tandai Dikirim Vendor'), findsOneWidget);
    await tester.tap(find.text('Tandai Dikirim Vendor'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Pengiriman Vendor'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    final inboundTab = find.text('Penerimaan Inbound');
    await tester.ensureVisible(inboundTab);
    await tester.tap(inboundTab);
    await tester.pumpAndSettle();
    expect(find.text('PT Medika Farma'), findsOneWidget);
    expect(find.text('PO-202610-099'), findsOneWidget);
  });

  testWidgets('PengadaanHubScreen hides Penerimaan Inbound for Petugas Unit and toggles FAB', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidget(user: petugasUnitUser));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Permintaan (PR)'), findsOneWidget);
    expect(find.text('Pesanan (PO)'), findsOneWidget);
    // Penerimaan Inbound MUST NOT exist for Petugas Unit
    expect(find.text('Penerimaan Inbound'), findsNothing);

    // On Tab 1 (PR): FAB 'Ajukan PR Baru' is visible
    expect(find.text('Ajukan PR Baru'), findsOneWidget);

    // Switch to Tab 2 (Pesanan PO)
    await tester.tap(find.text('Pesanan (PO)'));
    await tester.pumpAndSettle();

    // On Tab 2 (PO): FAB 'Ajukan PR Baru' is hidden
    expect(find.text('Ajukan PR Baru'), findsNothing);
  });
}
