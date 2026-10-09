import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/detail_amprah_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  testWidgets('DetailAmprahScreen displays partial delivery banner and backorder item metrics', (tester) async {
    const dummyAmprah = AmprahHeaderModel(
      id: 99,
      kode: 'REQ-202610-PARTIAL',
      unit: 'Rawat Inap 3',
      gudang: 'Gudang Logistik',
      pengaju: 'Karu Melati',
      tanggalPermintaan: '2026-10-06',
      urgensi: 'REGULER',
      status: 'DIKIRIM_SEBAGIAN',
      canCancel: false,
      jumlahItem: 1,
      items: [
        AmprahDetailItemModel(
          id: 10,
          barangId: 20,
          namaBarang: 'Infus Set Dewasa',
          kodeBarang: 'MED-INF-01',
          satuan: 'Pcs',
          jumlahDiminta: 10,
          jumlahDisetujui: 10,
          jumlahDikirim: 4,
        ),
      ],
    );
    const petugasGudangUser = UserModel(
      id: 2,
      name: 'Petugas Gudang',
      email: 'gudang@simlogrs.local',
      roles: ['petugas_gudang'],
      permissions: ['create_gudang_stok::picking::distribusi'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(petugasGudangUser)),
          detailAmprahProvider(99).overrideWith((ref) => Future.value(dummyAmprah)),
        ],
        child: const MaterialApp(
          home: DetailAmprahScreen(amprahId: 99, kodeAmprah: 'REQ-202610-PARTIAL'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify partial shipment notice exists
    expect(find.textContaining('dikirim sebagian', findRichText: true), findsWidgets);
    // Verify Terkirim and Sisa Hutang metrics
    expect(find.textContaining('Terkirim: 4'), findsOneWidget);
    expect(find.textContaining('Sisa: 6'), findsOneWidget);
    expect(find.text('Eksekusi Picking FEFO & Terbitkan SPPB'), findsOneWidget);
  });

  testWidgets('DetailAmprahScreen hides Picking FEFO button for Petugas Unit', (tester) async {
    const dummyAmprah = AmprahHeaderModel(
      id: 99,
      kode: 'REQ-202610-PARTIAL',
      unit: 'Rawat Inap 3',
      gudang: 'Gudang Logistik',
      pengaju: 'Karu Melati',
      tanggalPermintaan: '2026-10-06',
      urgensi: 'REGULER',
      status: 'DIKIRIM_SEBAGIAN',
      canCancel: false,
      jumlahItem: 1,
      items: [],
    );

    const petugasUnitUser = UserModel(
      id: 3,
      name: 'Ns. Siti',
      email: 'unit@simlogrs.local',
      roles: ['petugas_unit'],
      permissions: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(petugasUnitUser)),
          detailAmprahProvider(99).overrideWith((ref) => Future.value(dummyAmprah)),
        ],
        child: const MaterialApp(
          home: DetailAmprahScreen(amprahId: 99, kodeAmprah: 'REQ-202610-PARTIAL'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eksekusi Picking FEFO & Terbitkan SPPB'), findsNothing);
  });
}
