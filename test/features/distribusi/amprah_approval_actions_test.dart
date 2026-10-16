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
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/shared/widgets/app_quantity_stepper.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/detail_amprah_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repository palsu: daftar amprah berisi satu item sesuai status uji, dan aksi keputusan dicatat.
class FakeAmprahApprovalRepository implements DistribusiRepository {
  final String status;
  final bool canTutupSisa;
  final List<String> approvalCalls = [];
  List<Map<String, int>>? lastApprovedItems;
  int? tutupSisaId;
  FakeAmprahApprovalRepository(this.status, {this.canTutupSisa = false});

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
        canTutupSisa: canTutupSisa,
        jumlahItem: 1,
        items: const [
          AmprahDetailItemModel(
            id: 501,
            barangId: 101,
            namaBarang: 'Kasa Steril',
            kodeBarang: 'MED-KSA',
            satuan: 'Box',
            jumlahDiminta: 10,
            jumlahDisetujui: 10,
            stokTersedia: 8,
          ),
        ],
      ),
    ];
  }

  @override
  Future<AmprahHeaderModel> getDetailAmprah(int id) async {
    return AmprahHeaderModel(
      id: id,
      kode: 'REQ-202610-001',
      unit: 'Rawat Inap 3',
      gudang: 'Gudang Sentral',
      pengaju: 'Perawat Melati',
      tanggalPermintaan: '2026-10-06',
      urgensi: 'REGULER',
      status: status,
      canCancel: false,
      canTutupSisa: canTutupSisa,
      jumlahItem: 1,
      items: const [
        AmprahDetailItemModel(
          id: 501,
          barangId: 101,
          namaBarang: 'Kasa Steril',
          kodeBarang: 'MED-KSA',
          satuan: 'Box',
          jumlahDiminta: 10,
          jumlahDisetujui: 10,
          stokTersedia: 8,
        ),
      ],
    );
  }

  @override
  Future<List<SppbHeaderModel>> getSppbInbound() async => const [];

  @override
  Future<void> approveAmprah({
    required int id,
    required bool isSetujui,
    String? catatan,
    List<Map<String, int>>? items,
  }) async {
    approvalCalls.add('$id:$isSetujui:${catatan ?? ''}');
    lastApprovedItems = items;
  }

  @override
  Future<void> tutupSisaAmprah(int id) async {
    tutupSisaId = id;
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

Widget _buildDetail(UserModel user, FakeAmprahApprovalRepository repo, {int id = 7}) {
  return ProviderScope(
    key: ValueKey('$id-${user.id}'),
    overrides: [
      authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
      distribusiRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: DetailAmprahScreen(amprahId: id, kodeAmprah: 'REQ-202610-001'),
    ),
  );
}

Widget _buildModal(FakeAmprahApprovalRepository repo, AmprahHeaderModel amprah, bool isSetujui) {
  return ProviderScope(
    overrides: [
      distribusiRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AmprahApprovalModal(amprah: amprah, isSetujui: isSetujui),
      ),
    ),
  );
}

const _kepalaTeknisi = UserModel(
  id: 10,
  name: 'Kepala Teknisi',
  email: 'kepalateknisi@simlogrs.local',
  roles: ['kepala_teknisi'],
  permissions: ['update_layanan_unit::approval::karu'],
);

const _petugasUnit = UserModel(
  id: 11,
  name: 'Petugas Unit',
  email: 'petugasunit@simlogrs.local',
  roles: ['petugas_unit'],
  permissions: ['create_layanan_unit::permintaan::barang'],
);

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

  testWidgets('kepala teknisi tidak melihat aksi keputusan Meja 1 di hub', (tester) async {
    final repo = FakeAmprahApprovalRepository('DIAJUKAN');
    await tester.pumpWidget(_buildHub(_kepalaTeknisi, repo));
    await tester.pumpAndSettle();

    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);
  });

  testWidgets('AmprahApprovalModal Meja 2 sends items with adjusted quota on submit', (tester) async {
    final repo = FakeAmprahApprovalRepository('DISETUJUI_KARU');
    const item = AmprahDetailItemModel(
      id: 501,
      barangId: 101,
      namaBarang: 'Kasa Steril',
      kodeBarang: 'MED-KSA',
      satuan: 'Box',
      jumlahDiminta: 10,
      jumlahDisetujui: 0,
      stokTersedia: 8,
    );
    const amprah = AmprahHeaderModel(
      id: 7,
      kode: 'REQ-202610-001',
      unit: 'Rawat Inap 3',
      gudang: 'Gudang Sentral',
      pengaju: 'Perawat Melati',
      tanggalPermintaan: '2026-10-06',
      urgensi: 'REGULER',
      status: 'DISETUJUI_KARU',
      canCancel: false,
      jumlahItem: 1,
      items: [item],
    );

    await tester.pumpWidget(_buildModal(repo, amprah, true));
    await tester.pumpAndSettle();

    expect(find.text('Kasa Steril'), findsOneWidget);
    expect(find.textContaining('Stok Gudang: 8'), findsOneWidget);
    expect(
      find.textContaining('Kuota melebihi stok gudang (2 Box selisih dicatat sebagai backorder)'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ya, Setujui'));
    await tester.pumpAndSettle();
    expect(repo.lastApprovedItems, isNotNull);
    expect(repo.lastApprovedItems!.length, 1);
    expect(repo.lastApprovedItems!.first['id'], 501);
    expect(repo.lastApprovedItems!.first['jumlah_disetujui'], 10);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('AmprahApprovalModal Meja 1 sends NO items on submit', (tester) async {
    final repo = FakeAmprahApprovalRepository('DIAJUKAN');
    const item = AmprahDetailItemModel(
      id: 501,
      barangId: 101,
      namaBarang: 'Kasa Steril',
      kodeBarang: 'MED-KSA',
      satuan: 'Box',
      jumlahDiminta: 10,
      jumlahDisetujui: 0,
      stokTersedia: 8,
    );
    const amprah = AmprahHeaderModel(
      id: 7,
      kode: 'REQ-202610-001',
      unit: 'Rawat Inap 3',
      gudang: 'Gudang Sentral',
      pengaju: 'Perawat Melati',
      tanggalPermintaan: '2026-10-06',
      urgensi: 'REGULER',
      status: 'DIAJUKAN',
      canCancel: false,
      jumlahItem: 1,
      items: [item],
    );

    await tester.pumpWidget(_buildModal(repo, amprah, true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ya, Setujui'));
    await tester.pumpAndSettle();
    expect(repo.lastApprovedItems, isNull);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('AmprahApprovalModal Meja 2 blocks submit when every quota is 0', (tester) async {
    final repo = FakeAmprahApprovalRepository('DISETUJUI_KARU');
    const item = AmprahDetailItemModel(
      id: 501,
      barangId: 101,
      namaBarang: 'Kasa Steril',
      kodeBarang: 'MED-KSA',
      satuan: 'Box',
      jumlahDiminta: 1,
      jumlahDisetujui: 0,
      stokTersedia: 8,
    );
    const amprah = AmprahHeaderModel(
      id: 7,
      kode: 'REQ-202610-001',
      unit: 'Rawat Inap 3',
      gudang: 'Gudang Sentral',
      pengaju: 'Perawat Melati',
      tanggalPermintaan: '2026-10-06',
      urgensi: 'REGULER',
      status: 'DISETUJUI_KARU',
      canCancel: false,
      jumlahItem: 1,
      items: [item],
    );

    await tester.pumpWidget(_buildModal(repo, amprah, true));
    await tester.pumpAndSettle();

    final minusBtn = find.descendant(
      of: find.byType(AppQuantityStepper),
      matching: find.byIcon(LucideIcons.minus),
    );
    await tester.tap(minusBtn);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ya, Setujui'));
    await tester.pump();

    expect(find.text('Minimal satu barang harus disetujui, atau gunakan Tolak.'), findsOneWidget);
    expect(repo.approvalCalls, isEmpty);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('DetailAmprahScreen shows approval buttons only for the right role and status', (tester) async {
    // 1. Karu on DIAJUKAN -> shows Setujui & Tolak
    final repoDiajukan = FakeAmprahApprovalRepository('DIAJUKAN');
    await tester.pumpWidget(_buildDetail(_karu, repoDiajukan, id: 101));
    await tester.pumpAndSettle();
    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);

    // 2. Karu on DISETUJUI_KARU -> hides Setujui & Tolak
    final repoDisetujuiKaru = FakeAmprahApprovalRepository('DISETUJUI_KARU');
    await tester.pumpWidget(_buildDetail(_karu, repoDisetujuiKaru, id: 102));
    await tester.pumpAndSettle();
    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);

    // 3. Kepala Gudang on DISETUJUI_KARU -> shows Setujui & Tolak
    await tester.pumpWidget(_buildDetail(_kepalaGudang, repoDisetujuiKaru, id: 103));
    await tester.pumpAndSettle();
    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);

    // 4. Kepala Gudang on DIAJUKAN -> hides Setujui & Tolak
    await tester.pumpWidget(_buildDetail(_kepalaGudang, repoDiajukan, id: 104));
    await tester.pumpAndSettle();
    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);

    // 5. Kepala Teknisi on DIAJUKAN -> hides Setujui & Tolak
    await tester.pumpWidget(_buildDetail(_kepalaTeknisi, repoDiajukan, id: 105));
    await tester.pumpAndSettle();
    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);

    // 6. Petugas Unit on DIAJUKAN -> hides Setujui & Tolak
    await tester.pumpWidget(_buildDetail(_petugasUnit, repoDiajukan, id: 106));
    await tester.pumpAndSettle();
    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);
  });

  testWidgets('DetailAmprahScreen shows Tutup Sisa Hutang when canTutupSisa is true', (tester) async {
    final repo = FakeAmprahApprovalRepository('DIKIRIM_SEBAGIAN', canTutupSisa: true);
    await tester.pumpWidget(_buildDetail(_karu, repo));
    await tester.pumpAndSettle();

    expect(find.text('Tutup Sisa Hutang'), findsOneWidget);
  });

  testWidgets('provider tutupSisaAmprah calls repository and sets successMessage', (tester) async {
    final repo = FakeAmprahApprovalRepository('DIKIRIM_SEBAGIAN');
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          distribusiRepositoryProvider.overrideWithValue(repo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    final ok = await capturedRef.read(amprahActionProvider.notifier).tutupSisaAmprah(42);
    await tester.pumpAndSettle();

    expect(ok, isTrue);
    expect(repo.tutupSisaId, 42);
    expect(
      capturedRef.read(amprahActionProvider).successMessage,
      'Sisa barang terhutang telah ditutup.',
    );
  });
}
