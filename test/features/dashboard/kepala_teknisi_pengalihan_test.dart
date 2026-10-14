import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/approval_provider.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/pengalihan_hub_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:simlog_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:simlog_mobile/features/dashboard/presentation/screens/home_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const kepalaTeknisiUser = UserModel(
    id: 11,
    name: 'Ir. Gunawan, S.T.',
    email: 'karu_ipsrs@simlogrs.local',
    roles: ['kepala_teknisi', 'panel_user'],
    permissions: [
      'page_TeknisiDashboard',
      'create_pemeliharaan::spk::perbaikan',
      'view_pemeliharaan::spk::perbaikan',
    ],
    unit: UnitModel(id: 2, nama: 'Instalasi Pemeliharaan Sarana Rumah Sakit', kode: 'IPSRS'),
  );

  const teknisiUser = UserModel(
    id: 8,
    name: 'Agus Teknisi',
    email: 'teknisi@simlogrs.local',
    roles: ['teknisi'],
    permissions: [],
    unit: UnitModel(id: 2, nama: 'Instalasi Pemeliharaan Sarana Rumah Sakit', kode: 'IPSRS'),
  );

  const dummySummary = DashboardSummaryModel(
    hero: HeroMetricModel(
      judul: 'Panggilan Servis Darurat',
      total: 3,
      satuan: 'Tiket',
      labelTombol: 'Komando',
      targetAksi: 'none',
      subMetrik: [],
    ),
    recentActivities: [],
  );

  testWidgets('DashboardIpsrsView renders Pengalihan banner for Kepala Teknisi and navigates with Otorisasi tab', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(kepalaTeknisiUser)),
          dashboardSummaryProvider.overrideWith((ref) => Future.value(dummySummary)),
          approvalPendingProvider.overrideWith((ref) => Future.value(const ApprovalPendingResponse(prList: [], amprahList: [], totalPr: 0, totalAmprah: 0))),
          daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          daftarPengalihanProvider('otorisasi').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          countOtorisasiPengalihanProvider.overrideWith((ref) => Future.value(0)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify banner exists on Kepala Teknisi dashboard
    expect(find.text('Pengalihan & Mutasi Aset'), findsOneWidget);
    expect(find.text('Otorisasi dan mutasi fisik alat elektromedis/sarana RS'), findsOneWidget);

    // Tap the banner to navigate
    await tester.tap(find.text('Pengalihan & Mutasi Aset'));
    await tester.pumpAndSettle();

    // Verify PengalihanHubScreen is opened and Otorisasi tab is visible
    expect(find.byType(PengalihanHubScreen), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Otorisasi'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.byKey(const Key('fab_ajukan_pengalihan_aset')), findsOneWidget);
  });

  testWidgets('DashboardIpsrsView hides Pengalihan banner for Field Teknisi', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(teknisiUser)),
          dashboardSummaryProvider.overrideWith((ref) => Future.value(dummySummary)),
          approvalPendingProvider.overrideWith((ref) => Future.value(const ApprovalPendingResponse(prList: [], amprahList: [], totalPr: 0, totalAmprah: 0))),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Field teknisi should NOT see the Pengalihan banner on their dashboard
    expect(find.text('Pengalihan & Mutasi Aset'), findsNothing);
  });

  testWidgets('PengalihanHubScreen directly opened by Field Teknisi hides Otorisasi tab and hides FAB', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(teknisiUser)),
          daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          countOtorisasiPengalihanProvider.overrideWith((ref) => Future.value(0)),
        ],
        child: const MaterialApp(
          home: PengalihanHubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Field teknisi should only see 2 tabs: Aktif and Riwayat (no Otorisasi)
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Otorisasi'), findsNothing);
    expect(find.text('Riwayat'), findsOneWidget);

    // Field teknisi should NOT see the create FAB
    expect(find.text('Ajukan Pengalihan Aset'), findsNothing);
  });
}
