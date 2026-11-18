import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/sheets/trail_detail_sheet.dart';

class _DetailRepository extends Fake implements AuditRepository {
  _DetailRepository(this.logs);
  final Map<int, AuditTrailItemModel> logs;
  final List<int> requests = [];
  int failuresRemaining = 0;

  @override
  Future<AuditTrailItemModel> getAuditTrailDetail(int id) async {
    requests.add(id);
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw Exception('Connection unavailable');
    }
    return logs[id]!;
  }
}

AuditTrailItemModel _log({
  int id = 3632,
  String action = 'UBAH',
  String waktu = '18 Nov 2026 09:00',
  Map<String, dynamic>? before = const {'status': 'DIPINJAM'},
  Map<String, dynamic>? after = const {'status': 'SELESAI'},
}) => AuditTrailItemModel(
  id: id,
  penggunaNama: 'Operator Satu',
  penggunaNip: '123',
  peran: 'super_admin',
  aksi: action,
  referensiJenis: 'PermintaanPeminjaman',
  referensiId: 5,
  ipAddress: '127.0.0.1',
  device: 'Perangkat uji',
  waktu: waktu,
  timestamp: '',
  hasDataSebelum: before != null,
  hasDataSesudah: after != null,
  dataSebelum: before,
  dataSesudah: after,
);

Future<void> _open(WidgetTester tester, _DetailRepository repo, {double scale = 1}) async {
  tester.view.physicalSize = const Size(343, 762);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [auditRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const TrailDetailSheet(logId: 3632),
        ),
        child: const Text('Buka detail'),
      ))),
    ),
  ));
  await tester.tap(find.text('Buka detail'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('recorded time is readable without shifting its clock', (tester) async {
    await _open(tester, _DetailRepository({3632: _log(waktu: '16/11/2026 10:27:06')}));
    expect(find.text('Waktu: 16 Nov 2026, 10:27:06'), findsOneWidget);
  });

  testWidgets('friendly read-only detail, compact height, technical disclosure and close', (tester) async {
    final repo = _DetailRepository({3632: _log()});
    await _open(tester, repo);
    expect(find.text('Detail Aktivitas'), findsOneWidget);
    expect(find.text('Catatan #3632'), findsOneWidget);
    expect(find.text('Peminjaman aset #5'), findsOneWidget);
    expect(find.text('Super Admin'), findsOneWidget);
    expect(find.text('Dipinjam'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Sebelumnya'), findsOneWidget);
    expect(find.text('Sesudahnya'), findsOneWidget);
    expect(find.text('Aktivitas: Diubah'), findsOneWidget);
    expect(find.text('UBAH'), findsNothing);
    expect(find.text('PermintaanPeminjaman'), findsNothing);
    expect(find.text('super_admin'), findsNothing);
    expect(find.text('{status: DIPINJAM}'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(tester.getTopLeft(find.text('Sebelumnya')).dy,
        tester.getTopLeft(find.text('Sesudahnya')).dy);
    expect(tester.getTopLeft(find.text('Sebelumnya')).dx,
        lessThan(tester.getTopLeft(find.text('Sesudahnya')).dx));
    expect(tester.getTopLeft(find.text('Detail Aktivitas')).dy, greaterThan(0));
    await tester.ensureVisible(find.text('Informasi teknis'));
    await tester.tap(find.text('Informasi teknis'));
    await tester.pumpAndSettle();
    expect(find.text('PermintaanPeminjaman'), findsOneWidget);
    expect(find.text('super_admin'), findsOneWidget);
    expect(repo.requests, [3632]);
    expect(find.byType(SelectableText), findsWidgets);
    // Expansion may grow the sheet and move its top edge. Only compare
    // header positions after that growth has settled, while content scrolls.
    final headerY = tester.getTopLeft(find.text('Detail Aktivitas')).dy;
    await tester.drag(find.text('Informasi teknis'), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Detail Aktivitas')).dy, headerY);
    Navigator.of(tester.element(find.byType(TrailDetailSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Detail Aktivitas'), findsNothing);
    expect(find.text('Buka detail'), findsOneWidget);
  });

  testWidgets('unknown codes are available only after opening technical details', (tester) async {
    final repo = _DetailRepository({3632: _log(
      before: {'secret_code': 'LEGACY_VALUE'},
      after: {'secret_code': 'NEW_VALUE'},
    )});
    await _open(tester, repo);
    expect(find.text('Bidang tambahan'), findsOneWidget);
    expect(find.text('LEGACY_VALUE'), findsNothing);
    expect(find.text('NEW_VALUE'), findsNothing);
    await tester.ensureVisible(find.text('Informasi teknis'));
    await tester.tap(find.text('Informasi teknis'));
    await tester.pumpAndSettle();
    expect(find.text('secret_code'), findsNWidgets(2));
    expect(find.text('LEGACY_VALUE'), findsOneWidget);
    expect(find.text('NEW_VALUE'), findsOneWidget);
    expect(repo.requests, [3632]);
  });

  testWidgets('missing snapshots are not described as creation or deletion', (tester) async {
    final repo = _DetailRepository({3632: _log(before: null, after: null)});
    await _open(tester, repo);
    expect(find.text('Rincian perubahan tidak tersedia'), findsOneWidget);
    expect(find.textContaining('Data ditambahkan'), findsNothing);
    expect(find.textContaining('Data dihapus'), findsNothing);
  });

  testWidgets('unchanged snapshots have an honest empty state', (tester) async {
    final repo = _DetailRepository({3632: _log(after: {'status': 'DIPINJAM'})});
    await _open(tester, repo);
    expect(find.text('Tidak ada perbedaan pada data yang tercatat'), findsOneWidget);
  });

  testWidgets('absence, null, empty, zero and false have different labels', (tester) async {
    final repo = _DetailRepository({3632: _log(
      before: {'catatan': null, 'jumlah': 0, 'aktif': false, 'nama': ''},
      after: {'jumlah': 1, 'aktif': true, 'nama': 'Baru'},
    )});
    await _open(tester, repo);
    expect(find.text('Tidak diisi (null)'), findsOneWidget);
    expect(find.text('Tidak tercatat'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Tidak (false)'), findsOneWidget);
    expect(find.text('Teks kosong'), findsOneWidget);
    expect(find.text('Ya (true)'), findsOneWidget);
  });

  testWidgets('unknown status does not acquire an invented business meaning', (tester) async {
    final repo = _DetailRepository({3632: _log(after: {'status': 'FUTURE_STATUS'})});
    await _open(tester, repo);
    expect(find.text('Nilai lain (lihat informasi teknis)'), findsOneWidget);
    expect(find.text('FUTURE_STATUS'), findsNothing);
    await tester.ensureVisible(find.text('Informasi teknis'));
    await tester.tap(find.text('Informasi teknis'));
    await tester.pumpAndSettle();
    expect(find.text('FUTURE_STATUS'), findsOneWidget);
  });

  testWidgets('addition keeps recorded values and honestly labels unavailable before data', (tester) async {
    final repo = _DetailRepository({3632: _log(action: 'TAMBAH', before: null)});
    await _open(tester, repo);
    expect(find.text('Aktivitas: Ditambahkan'), findsOneWidget);
    expect(find.text('Tidak tercatat'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.textContaining('Aktivitas penambahan data.'), findsOneWidget);
  });

  testWidgets('short empty detail is not forced to three quarters of the screen', (tester) async {
    final repo = _DetailRepository({3632: _log(before: null, after: null)});
    await _open(tester, repo);
    expect(tester.getTopLeft(find.text('Detail Aktivitas')).dy, greaterThan(762 * .25));
  });

  testWidgets('nested long detail scrolls without overflow at large text', (tester) async {
    final repo = _DetailRepository({3632: _log(
      before: {'details': List.generate(20, (index) => {'jumlah': index})},
      after: {'details': List.generate(20, (index) => {'jumlah': index + 1})},
    )});
    await _open(tester, repo, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Informasi teknis'));
    await tester.pumpAndSettle();
    expect(find.text('Informasi teknis').hitTestable(), findsOneWidget);
    expect(repo.requests, [3632]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry reloads only when requested and keeps error dismissible', (tester) async {
    final repo = _DetailRepository({3632: _log()})..failuresRemaining = 1;
    await _open(tester, repo);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Detail Aktivitas'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.pump();
    expect(repo.requests, [3632]);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Dipinjam'), findsOneWidget);
    expect(repo.requests, [3632, 3632]);
    await tester.ensureVisible(find.text('Informasi teknis'));
    await tester.tap(find.text('Informasi teknis'));
    await tester.pumpAndSettle();
    expect(repo.requests, [3632, 3632]);
  });

  testWidgets('long values and enlarged text use vertical comparisons', (tester) async {
    final repo = _DetailRepository({3632: _log(
      before: {'catatan': 'Catatan panjang yang perlu ruang penuh agar tetap terbaca'},
      after: {'catatan': 'Catatan pengganti yang juga panjang dan tidak boleh dipotong'},
    )});
    await _open(tester, repo);
    expect(tester.getTopLeft(find.text('Sebelumnya')).dy,
        lessThan(tester.getTopLeft(find.text('Sesudahnya')).dy));
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(TrailDetailSheet))).pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, _DetailRepository({3632: _log()}), scale: 2);
    expect(tester.getTopLeft(find.text('Sebelumnya')).dy,
        lessThan(tester.getTopLeft(find.text('Sesudahnya')).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing log identity reloads once, ordinary rebuilds do not', (tester) async {
    final repo = _DetailRepository({3632: _log(), 3633: _log(id: 3633)});
    final id = ValueNotifier<int>(3632);
    addTearDown(id.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [auditRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: Scaffold(body: ValueListenableBuilder<int>(
        valueListenable: id,
        builder: (_, value, __) => TrailDetailSheet(logId: value),
      ))),
    ));
    await tester.pumpAndSettle();
    id.value = 3633;
    await tester.pumpAndSettle();
    expect(find.text('Catatan #3633'), findsOneWidget);
    expect(repo.requests, [3632, 3633]);
  });
}
