import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/approval/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/approval/presentation/providers/approval_provider.dart';
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
  const testUser = UserModel(
    id: 1,
    name: 'Karu IGD',
    email: 'karu@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: [],
    unit: UnitModel(id: 3, nama: 'IGD', kode: 'IGD'),
  );

  const dummySummary = DashboardSummaryModel(
    hero: HeroMetricModel(
      judul: 'Pengeluaran Logistik & IPSRS',
      total: 0,
      satuan: 'Rp',
      labelTombol: 'Lihat',
      targetAksi: 'none',
      subMetrik: [],
    ),
    recentActivities: [],
  );

  testWidgets('HomeScreen renders Pengalihan & Mutasi Aset banner and taps to open PengalihanHubScreen', (tester) async {
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
          dashboardSummaryProvider.overrideWith((ref) => Future.value(dummySummary)),
          approvalPendingProvider.overrideWith((ref) => Future.value(const ApprovalPendingResponse(prList: [], amprahList: [], totalPr: 0, totalAmprah: 0))),
          daftarPengalihanProvider('aktif').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
          daftarPengalihanProvider('riwayat').overrideWith((ref) => Future.value(<PengalihanItemModel>[])),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify banner exists
    final bannerFinder = find.text('Pengalihan & Mutasi Aset');
    expect(bannerFinder, findsOneWidget);

    // Tap banner
    await tester.tap(bannerFinder);
    await tester.pumpAndSettle();

    // Verify it navigated to PengalihanHubScreen
    expect(find.byType(PengalihanHubScreen), findsOneWidget);
    expect(find.text('Pengalihan Aset RS'), findsOneWidget);
  });
}
