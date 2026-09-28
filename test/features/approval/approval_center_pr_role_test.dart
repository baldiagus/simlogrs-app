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

  const karuUser = UserModel(
    id: 2,
    name: 'Karu IGD',
    email: 'kepalaunit@simlogrs.local',
    roles: ['kepala_unit'],
    permissions: ['update_pengadaan::permintaan::pengadaan'],
  );

  const mockPending = ApprovalPendingResponse(
    prList: [
      ApprovalItemModel(
        id: 101,
        tipe: 'PR',
        kode: 'PR-2026-001',
        unit: 'Instalasi Gawat Darurat',
        pengaju: 'Ns. Budi',
        tanggal: '28/09/2026',
        urgensi: 'REGULER',
        status: 'DIAJUKAN',
        jumlahItem: 1,
        items: [
          ApprovalDetailItem(
            barangId: 10,
            namaBarang: 'Kasa Steril 16x16',
            jumlah: 50,
            satuan: 'Box',
          ),
        ],
      ),
      ApprovalItemModel(
        id: 102,
        tipe: 'PR',
        kode: 'PR-2026-002',
        unit: 'Gudang Logistik',
        pengaju: 'Hendra Kusuma',
        tanggal: '28/09/2026',
        urgensi: 'CITO',
        status: 'DISETUJUI',
        jumlahItem: 1,
        items: [
          ApprovalDetailItem(
            barangId: 11,
            namaBarang: 'Spuit 5cc Terumo',
            jumlah: 100,
            satuan: 'Box',
          ),
        ],
      ),
      ApprovalItemModel(
        id: 103,
        tipe: 'PR',
        kode: 'PR-2026-003',
        unit: 'Rawat Inap Bedah',
        pengaju: 'dr. Anton',
        tanggal: '28/09/2026',
        urgensi: 'REGULER',
        status: 'DITERUSKAN_KE_PENGADAAN',
        jumlahItem: 1,
        items: [
          ApprovalDetailItem(
            barangId: 12,
            namaBarang: 'Catheter Foley 16Fr',
            jumlah: 30,
            satuan: 'Pcs',
          ),
        ],
      ),
    ],
    amprahList: [],
    totalPr: 3,
    totalAmprah: 0,
  );

  testWidgets('Role Pengadaan hanya melihat PR DISETUJUI & DITERUSKAN_KE_PENGADAAN dengan aksi Terbitkan PO', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(pengadaanUser)),
          approvalPendingProvider.overrideWith((ref) => Future.value(mockPending)),
          poListProvider.overrideWith((ref) => Future.value(<PesananPembelianModel>[])),
        ],
        child: const MaterialApp(
          home: ApprovalCenterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // PR DIAJUKAN tidak boleh muncul untuk role Pengadaan
    expect(find.text('PR-2026-001'), findsNothing);

    // PR DISETUJUI dan DITERUSKAN harus muncul
    expect(find.text('PR-2026-002'), findsOneWidget);
    expect(find.text('PR-2026-003'), findsOneWidget);

    // Aksi yang muncul HANYA Terbitkan PO, BUKAN aksi Setujui PR internal
    expect(find.text('Terbitkan PO (Pesanan Pembelian)'), findsNWidgets(2));
    expect(find.text('Setujui'), findsNothing);
  });

  testWidgets('Role Karu IGD melihat PR DIAJUKAN dengan aksi Setujui & Tolak', (tester) async {
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

    // PR DIAJUKAN harus tampil
    expect(find.text('PR-2026-001'), findsOneWidget);

    // Aksi Setujui dan Tolak harus tampil untuk PR DIAJUKAN
    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });
}
