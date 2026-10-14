import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/data/models/sppb_model.dart';
import 'package:simlog_mobile/features/distribusi/data/repositories/distribusi_repository.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/amprah_hub_screen.dart';
import 'package:simlog_mobile/features/distribusi/presentation/widgets/amprah_approval_modal.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repository palsu: daftar amprah berisi satu item sesuai status uji, dan aksi keputusan dicatat.
class FakeAmprahApprovalRepository implements DistribusiRepository {
  final String status;
  final List<String> approvalCalls = [];

  FakeAmprahApprovalRepository(this.status);

  @override
  Future<List<AmprahHeaderModel>> getDaftarAmprah({String? status, String? urgensi}) async {
    return [
      AmprahHeaderModel(
        id: 7,
        kode: 'REQ-202610-001',
        unit: 'Rawat Inap 3',
        gudang: 'Gudang Sentral',
        pengaju: 'Perawat Melati',
        tanggalPermintaan: '2026-10-06',
        urgensi: 'REGULER',
        status: this.status,
        canCancel: false,
        jumlahItem: 0,
        items: const [],
      ),
    ];
  }

  @override
  Future<List<SppbHeaderModel>> getSppbInbound() async => const [];

  @override
  Future<void> approveAmprah({required int id, required bool isSetujui, String? catatan}) async {
    approvalCalls.add('$id:$isSetujui:${catatan ?? ''}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Membangun layar Amprah Hub untuk [user] dengan repository palsu [repo].
Widget _buildHub(UserModel user, FakeAmprahApprovalRepository repo) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
      distribusiRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(home: AmprahHubScreen()),
  );
}

const _karu = UserModel(
  id: 6,
  name: 'dr. Pratama, Sp.EM',
  email: 'karu@simlogrs.local',
  unit: UnitModel(id: 3, nama: 'Rawat Inap 3'),
  roles: ['kepala_unit'],
  permissions: ['update_layanan_unit::approval::karu', 'page_KepalaUnitDashboard'],
);

const _kepalaGudang = UserModel(
  id: 8,
  name: 'Kepala Gudang',
  email: 'kepalagudang@simlogrs.local',
  roles: ['kepala_gudang'],
  permissions: ['update_gudang_stok::distribusi::approval'],
);

const _petugasGudang = UserModel(
  id: 4,
  name: 'Joko Wahyudi, A.Md.',
  email: 'petugasgudang@simlogrs.local',
  roles: ['petugas_gudang'],
  permissions: ['page_GudangDashboard', 'create_gudang_stok::picking::distribusi'],
);

void main() {
  testWidgets('karu melihat aksi Setujui dan Tolak untuk amprah DIAJUKAN (Meja 1)', (tester) async {
    final repo = FakeAmprahApprovalRepository('DIAJUKAN');
    await tester.pumpWidget(_buildHub(_karu, repo));
    await tester.pumpAndSettle();

    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });

  testWidgets('kepala gudang melihat aksi Meja 2 untuk amprah DISETUJUI_KARU', (tester) async {
    final repo = FakeAmprahApprovalRepository('DISETUJUI_KARU');
    await tester.pumpWidget(_buildHub(_kepalaGudang, repo));
    await tester.pumpAndSettle();

    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });

  testWidgets('petugas gudang tidak melihat aksi keputusan amprah', (tester) async {
    final repo = FakeAmprahApprovalRepository('DISETUJUI_KARU');
    await tester.pumpWidget(_buildHub(_petugasGudang, repo));
    await tester.pumpAndSettle();

    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);
  });

  testWidgets('tolak tanpa alasan ditolak validasinya dan tidak memanggil API', (tester) async {
    final repo = FakeAmprahApprovalRepository('DIAJUKAN');
    await tester.pumpWidget(_buildHub(_karu, repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    expect(find.byType(AmprahApprovalModal), findsOneWidget);

    await tester.tap(find.text('Ya, Tolak'));
    await tester.pump();

    expect(find.text('Alasan penolakan wajib diisi!'), findsOneWidget);
    expect(repo.approvalCalls, isEmpty);

    await tester.pump(const Duration(seconds: 4));
  });
}
