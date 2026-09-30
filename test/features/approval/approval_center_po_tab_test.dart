import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/approval/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/approval/presentation/providers/approval_provider.dart';
import 'package:simlog_mobile/features/approval/presentation/screens/approval_center_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/po_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const pengadaanUser = UserModel(
    id: 1,
    name: 'Staf Pengadaan',
    email: 'pengadaan@simlogrs.local',
    roles: ['pengadaan'],
    permissions: ['create_pengadaan::pesanan::pembelian'],
  );

  final mockPos = [
    const PesananPembelianModel(
      id: 1,
      kode: 'PO-2026-001',
      pemasokId: 1,
      namaPemasok: 'CV Graha Logistik Medis',
      kodePemasok: 'VND-001',
      tanggalPo: '2026-09-30',
      estimasiTanggalKirim: '2026-10-07',
      totalBiaya: 1000000,
      syaratPembayaran: 'TEMPO_30_HARI',
      status: 'DITERIMA_LENGKAP',
      pembuat: 'Staf Pengadaan',
      totalItem: 1,
      items: [],
    ),
    const PesananPembelianModel(
      id: 2,
      kode: 'PO-2026-002',
      pemasokId: 1,
      namaPemasok: 'CV Graha Logistik Medis',
      kodePemasok: 'VND-001',
      tanggalPo: '2026-09-30',
      estimasiTanggalKirim: '2026-10-07',
      totalBiaya: 5000000,
      syaratPembayaran: 'TEMPO_30_HARI',
      status: 'DITERIMA_LENGKAP',
      pembuat: 'Staf Pengadaan',
      totalItem: 1,
      items: [],
    ),
    const PesananPembelianModel(
      id: 3,
      kode: 'PO-2026-003',
      pemasokId: 2,
      namaPemasok: 'CV Sinar Chemindo Higienis',
      kodePemasok: 'VND-002',
      tanggalPo: '2026-09-30',
      estimasiTanggalKirim: '2026-10-07',
      totalBiaya: 100000,
      syaratPembayaran: 'TEMPO_30_HARI',
      status: 'DITERIMA_LENGKAP',
      pembuat: 'Staf Pengadaan',
      totalItem: 1,
      items: [],
    ),
    const PesananPembelianModel(
      id: 4,
      kode: 'PO-2026-004',
      pemasokId: 3,
      namaPemasok: 'PT Medika Farma Sejahtera',
      kodePemasok: 'VND-003',
      tanggalPo: '2026-09-30',
      estimasiTanggalKirim: '2026-10-07',
      totalBiaya: 500000,
      syaratPembayaran: 'TEMPO_30_HARI',
      status: 'DITERBITKAN',
      pembuat: 'Staf Pengadaan',
      totalItem: 1,
      items: [],
    ),
    const PesananPembelianModel(
      id: 5,
      kode: 'PO-2026-005',
      pemasokId: 3,
      namaPemasok: 'PT Medika Farma Sejahtera',
      kodePemasok: 'VND-003',
      tanggalPo: '2026-09-30',
      estimasiTanggalKirim: '2026-10-07',
      totalBiaya: 200000,
      syaratPembayaran: 'TEMPO_30_HARI',
      status: 'DITERBITKAN',
      pembuat: 'Staf Pengadaan',
      totalItem: 1,
      items: [],
    ),
  ];

  testWidgets('ApprovalCenterScreen tab Pesanan PO highlights only actionable count (2 instead of 5)', (tester) async {
    const mockPending = ApprovalPendingResponse(
      prList: [],
      amprahList: [],
      totalPr: 0,
      totalAmprah: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(pengadaanUser)),
          approvalPendingProvider.overrideWith((ref) => Future.value(mockPending)),
          poActionableCountProvider.overrideWith((ref) => Future.value(2)),
          poListProvider.overrideWith((ref) {
            final filter = ref.watch(poStatusFilterProvider);
            if (filter == 'DITERBITKAN') {
              return Future.value(mockPos.where((p) => p.status == 'DITERBITKAN').toList());
            }
            return Future.value(mockPos);
          }),
        ],
        child: const MaterialApp(
          home: ApprovalCenterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Tab 2 badge shows 2 (only actionable POs: DITERBITKAN), NOT 5 (all POs)
    expect(find.text('Pesanan (PO)'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Switch to Tab 2
    await tester.tap(find.text('Pesanan (PO)'));
    await tester.pumpAndSettle();

    // Filter chip and each actionable PO card has 'Perlu Tindakan'
    expect(find.text('Perlu Tindakan'), findsNWidgets(3));
    // DITERBITKAN POs are displayed and have 'Perlu Tindakan' highlight & action button
    expect(find.text('PO-2026-004'), findsOneWidget);
    expect(find.text('PO-2026-005'), findsOneWidget);
    expect(find.text('Tandai Dikirim Vendor'), findsNWidgets(2));

    // Completed POs (DITERIMA LENGKAP) are not shown in default 'Perlu Tindakan' list
    expect(find.text('PO-2026-001'), findsNothing);
    expect(find.text('PO-2026-002'), findsNothing);
    expect(find.text('PO-2026-003'), findsNothing);
  });
}
