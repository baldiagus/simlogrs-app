import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/approval/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/approval/presentation/providers/approval_provider.dart';
import 'package:simlog_mobile/features/approval/presentation/screens/approval_center_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const kepalaGudangUser = UserModel(
    id: 3,
    name: 'Ahmad Faisal, S.T.',
    email: 'kepalagudang@simlogrs.local',
    roles: ['kepala_gudang'],
    permissions: ['update_gudang_stok::distribusi::approval', 'page_KepalaGudangDashboard'],
    gudang: GudangModel(id: 1, nama: 'Gudang Sentral Logistik Non-Medis', kode: 'GUD_SENTRAL'),
  );

  const karuUser = UserModel(
    id: 2,
    name: 'Ns. Dewi Sartika, S.Kep',
    email: 'kepalaunit@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: ['update_layanan_unit::approval::karu', 'page_KepalaUnitDashboard'],
    unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
  );

  const mockPending = ApprovalPendingResponse(
    prList: [],
    amprahList: [
      ApprovalItemModel(
        id: 201,
        tipe: 'AMPRAH',
        kode: 'REQ-202609-001',
        unit: 'Instalasi Gawat Darurat',
        pengaju: 'Ns. Budi Santoso',
        tanggal: '29/09/2026',
        urgensi: 'REGULER',
        status: 'DIAJUKAN',
        jumlahItem: 1,
        items: [
          ApprovalDetailItem(
            barangId: 1,
            namaBarang: 'HVS A4',
            jumlah: 3,
            satuan: 'Box',
          ),
        ],
      ),
      ApprovalItemModel(
        id: 202,
        tipe: 'AMPRAH',
        kode: 'REQ-202609-002',
        unit: 'Rawat Inap Bedah',
        pengaju: 'dr. Anton',
        tanggal: '29/09/2026',
        urgensi: 'CITO',
        status: 'DISETUJUI_KARU',
        jumlahItem: 1,
        items: [
          ApprovalDetailItem(
            barangId: 2,
            namaBarang: 'Spuit 5cc',
            jumlah: 10,
            satuan: 'Box',
          ),
        ],
      ),
    ],
    totalPr: 0,
    totalAmprah: 2,
  );

  testWidgets('Kepala Gudang hanya melihat amprah DISETUJUI_KARU dan menyembunyikan DIAJUKAN', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(kepalaGudangUser)),
          approvalPendingProvider.overrideWith((ref) => Future.value(mockPending)),
        ],
        child: const MaterialApp(
          home: ApprovalCenterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pindah ke tab Amprah Ruangan
    await tester.tap(find.text('Amprah Ruangan'));
    await tester.pumpAndSettle();

    // REQ-202609-002 (DISETUJUI_KARU) harus muncul
    expect(find.text('REQ-202609-002'), findsOneWidget);
    expect(find.text('Rawat Inap Bedah'), findsOneWidget);

    // REQ-202609-001 (DIAJUKAN) TIDAK BOLEH muncul untuk Kepala Gudang
    expect(find.text('REQ-202609-001'), findsNothing);
  });

  testWidgets('Admin Logistik melihat tab Amprah berisi DISETUJUI_KARU dengan tombol Setujui dan Tolak', (tester) async {
    const adminLogistikUser = UserModel(
      id: 4,
      name: 'Admin Logistik',
      email: 'adminlogistik@simlogrs.local',
      roles: ['admin_logistik'],
      permissions: [],
      gudang: GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD_SENTRAL'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(adminLogistikUser)),
          approvalPendingProvider.overrideWith((ref) => Future.value(mockPending)),
        ],
        child: const MaterialApp(home: ApprovalCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amprah'));
    await tester.pumpAndSettle();

    expect(find.text('REQ-202609-002'), findsOneWidget);
    expect(find.text('REQ-202609-001'), findsNothing);
    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });

  testWidgets('Kepala Ruangan hanya melihat amprah DIAJUKAN dan menyembunyikan DISETUJUI_KARU', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(karuUser)),
          approvalPendingProvider.overrideWith((ref) => Future.value(mockPending)),
        ],
        child: const MaterialApp(
          home: ApprovalCenterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pindah ke tab Amprah Ruangan
    await tester.tap(find.text('Amprah Ruangan'));
    await tester.pumpAndSettle();

    // REQ-202609-001 (DIAJUKAN) harus muncul
    expect(find.text('REQ-202609-001'), findsOneWidget);
    expect(find.text('Instalasi Gawat Darurat'), findsOneWidget);

    // REQ-202609-002 (DISETUJUI_KARU) TIDAK BOLEH muncul di antrean Karu
    expect(find.text('REQ-202609-002'), findsNothing);
  });
}
