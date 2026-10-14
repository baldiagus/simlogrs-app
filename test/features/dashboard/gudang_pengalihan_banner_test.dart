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
  const kepalaGudangUser = UserModel(
    id: 12,
    name: 'Budi Kepala Gudang',
    email: 'karu_gudang@simlogrs.local',
    roles: ['kepala_gudang', 'panel_user'],
    permissions: [],
    gudang: GudangModel(id: 1, nama: 'Gudang Utama Farmasi', kode: 'G-FAR'),
  );

  const petugasGudangUser = UserModel(
    id: 13,
    name: 'Joko Petugas Gudang',
    email: 'petugas_gudang@simlogrs.local',
    roles: ['petugas_gudang', 'panel_user'],
    permissions: [],
    gudang: GudangModel(id: 1, nama: 'Gudang Utama Farmasi', kode: 'G-FAR'),
  );

  const dummySummary = DashboardSummaryModel(
    hero: HeroMetricModel(
      judul: 'Inbound PO & Picking FEFO',
      total: 5,
      satuan: 'Dokumen',
      labelTombol: 'Periksa',
      targetAksi: 'none',
      subMetrik: [],
    ),
    recentActivities: [],
  );

  testWidgets('DashboardGudangView renders Pengalihan banner for Kepala Gudang and navigates with Otorisasi tab', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(kepalaGudangUser)),
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

    // Verify banner exists on Kepala Gudang dashboard
    expect(find.text('Pengalihan & Mutasi Aset / Barang'), findsOneWidget);
    expect(find.text('Otorisasi dan monitoring redistribusi antar fasilitas logistik'), findsOneWidget);

    // Tap the banner to navigate
    await tester.tap(find.text('Pengalihan & Mutasi Aset / Barang'));
    await tester.pumpAndSettle();

    // Verify PengalihanHubScreen is opened and Otorisasi tab is visible
    expect(find.byType(PengalihanHubScreen), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Otorisasi'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.byKey(const Key('fab_ajukan_pengalihan_aset')), findsOneWidget);
  });

  testWidgets('DashboardGudangView renders Pengalihan banner for Petugas Gudang and navigates without Otorisasi tab', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(petugasGudangUser)),
          dashboardSummaryProvider.overrideWith((ref) => Future.value(dummySummary)),
          approvalPendingProvider.overrideWith((ref) => Future.value(const ApprovalPendingResponse(prList: [], amprahList: [], totalPr: 0, totalAmprah: 0))),
          daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          countOtorisasiPengalihanProvider.overrideWith((ref) => Future.value(0)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify banner exists on Petugas Gudang dashboard
    expect(find.text('Pengalihan & Mutasi Aset / Barang'), findsOneWidget);
    expect(find.text('Pengajuan dan serah terima redistribusi fisik logistik'), findsOneWidget);

    // Tap the banner to navigate
    await tester.tap(find.text('Pengalihan & Mutasi Aset / Barang'));
    await tester.pumpAndSettle();

    // Verify PengalihanHubScreen is opened and Otorisasi tab is HIDDEN
    expect(find.byType(PengalihanHubScreen), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Otorisasi'), findsNothing);
    expect(find.text('Riwayat'), findsOneWidget);

    // Petugas Gudang HAS permission to create pengalihan
    expect(find.byKey(const Key('fab_ajukan_pengalihan_aset')), findsOneWidget);
  });
}
