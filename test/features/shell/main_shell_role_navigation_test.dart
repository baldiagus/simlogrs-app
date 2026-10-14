import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/approval/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/approval/presentation/providers/approval_provider.dart';
import 'package:simlog_mobile/features/approval/presentation/screens/approval_center_screen.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:simlog_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/amprah_hub_screen.dart';
import 'package:simlog_mobile/core/notifications/notification_router.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/picking_distribusi_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/ipsrs_hub_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/spk_list_screen.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/tiket_maintenance_provider.dart';
import 'package:simlog_mobile/features/maintenance/data/models/spk_model.dart';
import 'package:simlog_mobile/features/maintenance/data/models/spk_header_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/screens/inbound_po_list_screen.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/inbound_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/sppb_model.dart';
import 'package:simlog_mobile/features/maintenance/data/models/tiket_maintenance_model.dart';
import 'package:simlog_mobile/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:simlog_mobile/shared/widgets/floating_bottom_nav_bar.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const dummySummary = DashboardSummaryModel(
    hero: HeroMetricModel(
      judul: 'Agenda',
      total: 0,
      satuan: 'Item',
      labelTombol: 'Buka',
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

  const petugasUnitUser = UserModel(
    id: 7,
    name: 'Perawat Pelaksana',
    email: 'perawat@simlogrs.local',
    roles: ['petugas_unit'],
    permissions: ['page_UnitDashboard'],
    unit: UnitModel(id: 3, nama: 'IGD', kode: 'IGD'),
  );

  const gudangUser = UserModel(
    id: 2,
    name: 'Petugas Gudang',
    email: 'gudang@simlogrs.local',
    roles: ['petugas_gudang'],
    permissions: ['page_GudangDashboard'],
    gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
  );

  const teknisiUser = UserModel(
    id: 3,
    name: 'Teknisi Lapangan',
    email: 'teknisi@simlogrs.local',
    roles: ['teknisi'],
    permissions: ['page_TeknisiDashboard'],
    unit: UnitModel(id: 2, nama: 'IPSRS', kode: 'IPSRS'),
  );

  const manajemenUser = UserModel(
    id: 4,
    name: 'Direksi RS',
    email: 'direksi@simlogrs.local',
    roles: ['manajemen'],
    permissions: ['page_ManajemenDashboard'],
    unit: UnitModel(id: 8, nama: 'Direksi', kode: 'DIREKSI'),
  );

  Widget createShellForUser(UserModel user) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
        dashboardSummaryProvider.overrideWith((ref) => Future.value(dummySummary)),
        approvalPendingProvider.overrideWith((ref) => Future.value(const ApprovalPendingResponse(prList: [], amprahList: [], totalPr: 0, totalAmprah: 0))),
        daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
        daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
        daftarTiketUnitProvider.overrideWith((ref, params) => Future.value(<TiketMaintenanceModel>[])),
        spkListProvider.overrideWith((ref, status) => Future.value(<SpkHeaderModel>[])),
        daftarPoInboundProvider.overrideWith((ref) => Future.value(<PoInboundHeaderModel>[])),
        antreanPickingProvider.overrideWith((ref) => Future.value(<PickingAntreanModel>[])),
      ],
      child: const MaterialApp(
        home: MainShellScreen(),
      ),
    );
  }

  testWidgets('MainShellScreen renders Karu navigation (Beranda, Approval, Amprah, Profil)', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createShellForUser(karuUser));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(FloatingBottomNavBar), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Approval'), findsOneWidget);
    expect(find.text('Amprah'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('IPSRS'), findsNothing);

    // Tap Amprah tab (index 2)
    await tester.tap(find.text('Amprah'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AmprahHubScreen), findsOneWidget);
  });

  testWidgets('MainShellScreen renders Petugas Unit navigation (Beranda, Amprah, Sirkulasi, Profil)', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createShellForUser(petugasUnitUser));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Amprah'), findsOneWidget);
    expect(find.text('Sirkulasi'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Approval'), findsNothing);
    expect(find.text('IPSRS'), findsNothing);

    // Tap Sirkulasi tab (index 2)
    await tester.tap(find.text('Sirkulasi'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SirkulasiAsetHubScreen), findsOneWidget);
  });

  testWidgets('MainShellScreen renders Gudang navigation (Beranda, Inbound PO, Picking, Profil)', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createShellForUser(gudangUser));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Inbound PO'), findsOneWidget);
    expect(find.text('Picking'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('IPSRS'), findsNothing);

    // Tap Inbound PO tab (index 1)
    await tester.tap(find.text('Inbound PO'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(InboundPoListScreen), findsOneWidget);

    // Tap Picking tab (index 2)
    await tester.tap(find.text('Picking'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PickingDistribusiScreen), findsOneWidget);
  });

  testWidgets('Kepala Gudang punya tab Approval berurutan sebelum Picking; petugas gudang tidak', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const kepalaGudangUser = UserModel(
      id: 5,
      name: 'Kepala Gudang',
      email: 'kepalagudang@simlogrs.local',
      roles: ['kepala_gudang'],
      permissions: ['page_KepalaGudangDashboard'],
      gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
    );

    await tester.pumpWidget(createShellForUser(kepalaGudangUser));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Approval'), findsOneWidget);
    final nav = find.byType(FloatingBottomNavBar);
    double x(String t) => tester.getCenter(find.descendant(of: nav, matching: find.text(t))).dx;
    expect(x('Inbound PO') < x('Approval') && x('Approval') < x('Picking') && x('Picking') < x('Profil'), isTrue);

    await tester.tap(find.descendant(of: nav, matching: find.text('Approval')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ApprovalCenterScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(createShellForUser(gudangUser));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Approval'), findsNothing);
  });

  test('resolveGudangTabIndex menyesuaikan indeks tab dengan ada/tidaknya tab Approval', () {
    expect(resolveGudangTabIndex(NotificationTarget.approvalAmprah, punyaTabApproval: true), 2);
    expect(resolveGudangTabIndex(NotificationTarget.approvalAmprah, punyaTabApproval: false), isNull);
    expect(resolveGudangTabIndex(NotificationTarget.antreanPicking, punyaTabApproval: true), 3);
    expect(resolveGudangTabIndex(NotificationTarget.antreanPicking, punyaTabApproval: false), 2);
    expect(resolveGudangTabIndex(NotificationTarget.inboundPo, punyaTabApproval: true), isNull);
  });

  testWidgets('MainShellScreen renders Teknisi navigation (Beranda, Tugas SPK, IPSRS, Profil)', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createShellForUser(teknisiUser));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.descendant(of: find.byType(FloatingBottomNavBar), matching: find.text('Beranda')), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingBottomNavBar), matching: find.text('Tugas SPK')), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingBottomNavBar), matching: find.text('IPSRS')), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingBottomNavBar), matching: find.text('Profil')), findsOneWidget);
    expect(find.text('Inbound PO'), findsNothing);
    expect(find.text('Picking'), findsNothing);

    // Tap Tugas SPK tab (index 1) in bottom nav
    await tester.tap(find.descendant(of: find.byType(FloatingBottomNavBar), matching: find.text('Tugas SPK')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SpkListScreen), findsOneWidget);

    // Tap IPSRS tab (index 2)
    await tester.tap(find.text('IPSRS'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(IpsrsHubScreen), findsOneWidget);
  });

  testWidgets('MainShellScreen renders Manajemen navigation (Beranda, Approval, Amprah, Profil)', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createShellForUser(manajemenUser));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Approval'), findsOneWidget);
    expect(find.text('Amprah'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('IPSRS'), findsNothing);

    // Tap Approval tab (index 1)
    await tester.tap(find.text('Approval'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ApprovalCenterScreen), findsOneWidget);

    // Tap Amprah tab (index 2)
    await tester.tap(find.text('Amprah'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AmprahHubScreen), findsOneWidget);
  });
}
