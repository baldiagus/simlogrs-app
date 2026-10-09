import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/approval/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/approval/presentation/providers/approval_provider.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:simlog_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:simlog_mobile/features/dashboard/presentation/screens/home_screen.dart';
import 'package:simlog_mobile/features/dashboard/presentation/views/dashboard_eksekutif_view.dart';
import 'package:simlog_mobile/features/dashboard/presentation/views/dashboard_gudang_view.dart';
import 'package:simlog_mobile/features/dashboard/presentation/views/dashboard_ipsrs_view.dart';
import 'package:simlog_mobile/features/dashboard/presentation/views/dashboard_ruangan_view.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/amprah_hub_screen.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/data/models/sppb_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/lapor_rusak_hub_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/spk_list_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/tiket_maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/data/models/tiket_maintenance_model.dart';
import 'package:simlog_mobile/features/maintenance/data/models/spk_header_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/screens/pengadaan_hub_screen.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/pr_model.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/po_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/inbound_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const dummySummary = DashboardSummaryModel(
    hero: HeroMetricModel(
      judul: 'Agenda Operasional',
      total: 3,
      satuan: 'Item',
      labelTombol: 'Periksa',
      targetAksi: 'none',
      subMetrik: [],
    ),
    recentActivities: [],
  );

  const karuUser = UserModel(
    id: 1,
    name: 'Karu IGD',
    email: 'karu@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: ['page_KepalaUnitDashboard'],
    unit: UnitModel(id: 3, nama: 'IGD', kode: 'IGD'),
  );

  const gudangUser = UserModel(
    id: 2,
    name: 'Petugas Gudang Sentral',
    email: 'gudang@simlogrs.local',
    roles: ['petugas_gudang'],
    permissions: ['page_GudangDashboard'],
    gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
  );

  const teknisiUser = UserModel(
    id: 3,
    name: 'Teknisi Elektro',
    email: 'teknisi@simlogrs.local',
    roles: ['teknisi'],
    permissions: ['page_TeknisiDashboard'],
    unit: UnitModel(id: 2, nama: 'IPSRS', kode: 'IPSRS'),
  );

  const manajemenUser = UserModel(
    id: 4,
    name: 'Direktur Keuangan',
    email: 'direksi@simlogrs.local',
    roles: ['manajemen'],
    permissions: ['page_ManajemenDashboard'],
    unit: UnitModel(id: 8, nama: 'Direksi', kode: 'DIREKSI'),
  );

  Widget createWidgetForUser(UserModel user) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
        dashboardSummaryProvider.overrideWith((ref) => Future.value(dummySummary)),
        approvalPendingProvider.overrideWith((ref) => Future.value(const ApprovalPendingResponse(prList: [], amprahList: [], totalPr: 0, totalAmprah: 0))),
        daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
        daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
        daftarAmprahProvider.overrideWith((ref, params) => Future.value(<AmprahHeaderModel>[])),
        sppbInboundProvider.overrideWith((ref) => Future.value(<SppbHeaderModel>[])),
        spkListProvider.overrideWith((ref, status) => Future.value(<SpkHeaderModel>[])),
        daftarTiketUnitProvider.overrideWith((ref, params) => Future.value(<TiketMaintenanceModel>[])),
        daftarPrProvider.overrideWith((ref) => Future.value(<PrHeaderModel>[])),
        poListProvider.overrideWith((ref) => Future.value(<PesananPembelianModel>[])),
        daftarPoInboundProvider.overrideWith((ref) => Future.value(<PoInboundHeaderModel>[])),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen routes Karu user to DashboardRuanganView', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetForUser(karuUser));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardRuanganView), findsOneWidget);
    expect(find.text('Pengadaan'), findsOneWidget);
    expect(find.text('Pengalihan & Mutasi Aset'), findsOneWidget);
    expect(find.byType(DashboardGudangView), findsNothing);
    expect(find.byType(DashboardIpsrsView), findsNothing);
    expect(find.byType(DashboardEksekutifView), findsNothing);

    // Tap Amprah Ruangan button
    final amprahBtn = find.text('Amprah Ruangan');
    await tester.ensureVisible(amprahBtn);
    await tester.tap(amprahBtn);
    await tester.pumpAndSettle();
    expect(find.byType(AmprahHubScreen), findsOneWidget);

    // Go back
    Navigator.pop(tester.element(find.byType(AmprahHubScreen)));
    await tester.pumpAndSettle();

    // Tap Lapor Rusak button -> now opens LaporRusakHubScreen
    final laporBtn = find.text('Lapor Rusak');
    await tester.ensureVisible(laporBtn);
    await tester.tap(laporBtn);
    await tester.pumpAndSettle();
    expect(find.byType(LaporRusakHubScreen), findsOneWidget);

    // Go back
    Navigator.pop(tester.element(find.byType(LaporRusakHubScreen)));
    await tester.pumpAndSettle();

    // Tap Pengadaan button -> opens PengadaanHubScreen
    final pengadaanBtn = find.text('Pengadaan');
    await tester.ensureVisible(pengadaanBtn);
    await tester.tap(pengadaanBtn);
    await tester.pumpAndSettle();
    expect(find.byType(PengadaanHubScreen), findsOneWidget);
  });

  testWidgets('HomeScreen routes Gudang user to DashboardGudangView', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetForUser(gudangUser));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardGudangView), findsOneWidget);
    expect(find.text('Persediaan Stok Gudang'), findsOneWidget);
    expect(find.byType(DashboardRuanganView), findsNothing);
    expect(find.byType(DashboardIpsrsView), findsNothing);
    expect(find.byType(DashboardEksekutifView), findsNothing);
  });

  testWidgets('HomeScreen routes Teknisi user to DashboardIpsrsView', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetForUser(teknisiUser));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardIpsrsView), findsOneWidget);
    expect(find.text('Aksi Cepat Teknisi IPSRS'), findsOneWidget);
    expect(find.text('Pengadaan'), findsNothing);
    expect(find.byType(DashboardRuanganView), findsNothing);
    expect(find.byType(DashboardGudangView), findsNothing);
    expect(find.byType(DashboardEksekutifView), findsNothing);
  });

  testWidgets('HomeScreen routes Manajemen user to DashboardEksekutifView', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetForUser(manajemenUser));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardEksekutifView), findsOneWidget);
    expect(find.text('Pengalihan & Mutasi Aset'), findsOneWidget);
    expect(find.text('Pagu & Realisasi Anggaran RS'), findsNothing);
    expect(find.text('Pusat Audit Internal SPI & CAPA'), findsNothing);
    expect(find.byType(DashboardRuanganView), findsNothing);
    expect(find.byType(DashboardGudangView), findsNothing);
    expect(find.byType(DashboardIpsrsView), findsNothing);

    // Tap Amprah Ruangan button in executive dashboard
    final amprahBtn = find.text('Amprah Ruangan');
    await tester.ensureVisible(amprahBtn);
    await tester.tap(amprahBtn);
    await tester.pumpAndSettle();
    expect(find.byType(AmprahHubScreen), findsOneWidget);

    // Go back
    Navigator.pop(tester.element(find.byType(AmprahHubScreen)));
    await tester.pumpAndSettle();

    // Tap Pantau SPK button in executive dashboard
    final spkBtn = find.text('Pantau SPK');
    await tester.ensureVisible(spkBtn);
    await tester.tap(spkBtn);
    await tester.pumpAndSettle();
    expect(find.byType(SpkListScreen), findsOneWidget);
  });
}
