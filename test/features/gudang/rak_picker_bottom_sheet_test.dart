import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/rak_model.dart';
import 'package:simlog_mobile/features/gudang/data/repositories/gudang_repository.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/gudang_provider.dart';
import 'package:simlog_mobile/features/gudang/presentation/widgets/rak_picker_bottom_sheet.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(AuthState.authenticated(UserModel(
    id: 1,
    name: 'Penerima',
    email: 'penerima@example.test',
    roles: const ['petugas_gudang'],
    permissions: const ['create_gudang_stok::penerimaan::po'],
    gudang: const GudangModel(id: 10, nama: 'Gudang Penerima'),
  )));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository extends Fake implements GudangRepository {
  final warehouseCalls = <int?>[];
  final queries = <String?>[];
  Future<List<RakModel>> Function() load = () async => [];

  @override
  Future<List<RakModel>> getDaftarRak({String? cari, int? gudangId}) {
    warehouseCalls.add(gudangId);
    queries.add(cari);
    return load();
  }
}

RakModel _rack(int id, String kode, String nama, {
  int gudangId = 10,
  String namaGudang = 'Gudang dari rak',
  String status = 'AKTIF',
}) => RakModel(
  id: id,
  kode: kode,
  nama: nama,
  gudangId: gudangId,
  namaGudang: namaGudang,
  status: status,
  totalBarang: 0,
  totalAset: 0,
);

Future<ProviderContainer> _openPicker(
  WidgetTester tester,
  _Repository repository,
  List<RakModel?> results, {
  int? selectedRackId,
  String namaGudang = 'Gudang Penerima',
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gudangRepositoryProvider.overrideWithValue(repository),
      authStateProvider.overrideWith((_) => _Auth()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) => TextButton(
          onPressed: () async {
            results.add(await showModalBottomSheet<RakModel>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => RakPickerBottomSheet(
                gudangId: 10,
                namaGudang: namaGudang,
                selectedRackId: selectedRackId,
              ),
            ));
          },
          child: const Text('Buka rak'),
        )),
      ),
    ),
  ));
  final container = ProviderScope.containerOf(
    tester.element(find.text('Buka rak')),
  );
  await tester.tap(find.text('Buka rak'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  testWidgets('searches code and name locally from one character and clears',
      (tester) async {
    final alpha = _rack(1, 'ZXA-123', 'Alat Steril');
    final beta = _rack(2, 'BTB-456', 'Masker');
    final repository = _Repository()..load = () async => [alpha, beta];
    final results = <RakModel?>[];
    await _openPicker(tester, repository, results);

    expect(find.text('Pilih Rak Simpan'), findsOneWidget);
    expect(find.text('Cari kode atau nama rak...'), findsOneWidget);
    expect(find.text('ZXA-123 (Alat Steril)'), findsOneWidget);
    expect(find.text('BTB-456 (Masker)'), findsOneWidget);
    expect(find.byTooltip('Rak terpilih'), findsNothing);

    for (final query in ['z', 'zx', 'zXa', '  zXa-123  ', '  sTeRiL  ']) {
      await _search(tester, query);
      expect(find.text('ZXA-123 (Alat Steril)'), findsOneWidget);
      expect(find.text('BTB-456 (Masker)'), findsNothing);
      expect(results, isEmpty);
    }
    await _search(tester, 'ma');
    expect(find.text('BTB-456 (Masker)'), findsOneWidget);
    expect(find.text('ZXA-123 (Alat Steril)'), findsNothing);

    await tester.tap(find.byTooltip('Hapus teks'));
    await tester.pump();
    expect(find.text('ZXA-123 (Alat Steril)'), findsOneWidget);
    expect(find.text('BTB-456 (Masker)'), findsOneWidget);
    expect(repository.warehouseCalls, [10]);
    expect(repository.queries, [null]);
    expect(results, isEmpty);
  });

  testWidgets('uses rack warehouse metadata and same-warehouse fallback only',
      (tester) async {
    final repository = _Repository()..load = () async => [
      _rack(1, 'API', 'Metadata', namaGudang: 'Gudang API'),
      _rack(2, 'EMPTY', 'Kosong', namaGudang: ''),
      _rack(3, 'DASH', 'Strip', namaGudang: '-'),
      _rack(4, 'FOREIGN', 'Asing', gudangId: 20, namaGudang: ''),
      _rack(5, 'OFF', 'Nonaktif', status: 'NONAKTIF'),
    ];
    await _openPicker(tester, repository, []);

    expect(find.text('Gudang Penerima: Gudang Penerima'), findsOneWidget);
    expect(find.text('Gudang: Gudang API'), findsOneWidget);
    expect(find.text('Gudang: Gudang Penerima'), findsNWidgets(2));
    expect(find.text('FOREIGN (Asing)'), findsNothing);
    expect(find.text('OFF (Nonaktif)'), findsNothing);
    await _search(tester, 'foreign');
    expect(find.text('Rak Tidak Ditemukan'), findsOneWidget);
    expect(find.text('Gudang: Gudang Penerima'), findsNothing);
    expect(repository.warehouseCalls, [10]);
  });

  testWidgets('marks current choice without selecting and returns the tapped model',
      (tester) async {
    final alpha = _rack(1, 'A', 'Pertama');
    final beta = _rack(2, 'B', 'Kedua');
    final repository = _Repository()..load = () async => [alpha, beta];
    final results = <RakModel?>[];
    await _openPicker(tester, repository, results, selectedRackId: beta.id);

    final selectedRow = find.ancestor(
      of: find.text('B (Kedua)'), matching: find.byType(ListTile),
    );
    expect(find.descendant(
      of: selectedRow, matching: find.byTooltip('Rak terpilih'),
    ), findsOneWidget);
    expect(results, isEmpty);
    await _search(tester, 'pertama');
    expect(find.byTooltip('Rak terpilih'), findsNothing);
    expect(results, isEmpty);
    await tester.tap(find.text('A (Pertama)'));
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single, same(alpha));
    expect(find.text('Pilih Rak Simpan'), findsNothing);
  });

  for (final dismissal in ['close', 'back', 'barrier', 'drag']) {
    testWidgets('$dismissal cancels without choosing or retaining search',
        (tester) async {
      final rack = _rack(1, 'A', 'Pertama');
      final repository = _Repository()..load = () async => [rack];
      final results = <RakModel?>[];
      await _openPicker(tester, repository, results, selectedRackId: rack.id);
      await _search(tester, 'tidak cocok');
      expect(results, isEmpty);
      if (dismissal == 'close') {
        await tester.tap(find.byTooltip('Tutup'));
      } else if (dismissal == 'back') {
        await tester.binding.handlePopRoute();
      } else if (dismissal == 'barrier') {
        await tester.tapAt(const Offset(5, 5));
      } else {
        await tester.drag(find.text('Pilih Rak Simpan'), const Offset(0, 600));
      }
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(find.text('Pilih Rak Simpan'), findsNothing);

      await tester.tap(find.text('Buka rak'));
      await tester.pumpAndSettle();
      expect(find.text('A (Pertama)'), findsOneWidget);
      expect(find.byTooltip('Hapus teks'), findsNothing);
      expect(find.byTooltip('Rak terpilih'), findsOneWidget);
    });
  }

  testWidgets('separates no active racks from an unmatched search', (tester) async {
    final repository = _Repository()..load = () async => [
      _rack(1, 'OFF', 'Nonaktif', status: 'NONAKTIF'),
      _rack(2, 'OTHER', 'Asing', gudangId: 20),
    ];
    final container = await _openPicker(tester, repository, []);
    expect(find.text('Tidak ada rak aktif di gudang penerima.'), findsOneWidget);
    expect(find.text('Rak Tidak Ditemukan'), findsNothing);
    await _search(tester, 'a');
    expect(find.text('Tidak ada rak aktif di gudang penerima.'), findsOneWidget);

    repository.load = () async => [_rack(3, 'B', 'Baru')];
    container.invalidate(rakPenerimaanProvider(10));
    await tester.pumpAndSettle();
    await _search(tester, 'zzz');
    expect(find.text('Rak Tidak Ditemukan'), findsOneWidget);
    expect(find.text('Hapus atau ganti kata kunci pencarian.'), findsOneWidget);
    expect(find.text('Tidak ada rak aktif di gudang penerima.'), findsNothing);
    await tester.tap(find.byTooltip('Hapus teks'));
    await tester.pump();
    expect(find.text('B (Baru)'), findsOneWidget);
  });

  testWidgets('shows loading and error separately and retries the scoped provider',
      (tester) async {
    final pending = Completer<List<RakModel>>();
    final repository = _Repository()..load = () => pending.future;
    final results = <RakModel?>[];
    await _openPicker(tester, repository, results);
    expect(find.text('Memuat rak...'), findsOneWidget);
    expect(find.text('Rak Tidak Ditemukan'), findsNothing);
    expect(find.text('Tidak ada rak aktif di gudang penerima.'), findsNothing);
    pending.completeError(ApiException(message: 'Koneksi terputus'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal Memuat Rak'), findsOneWidget);
    expect(find.textContaining('Koneksi terputus'), findsOneWidget);
    expect(find.text('Rak Tidak Ditemukan'), findsNothing);

    repository.load = () async => [_rack(1, 'A', 'Pulih')];
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('A (Pulih)'), findsOneWidget);
    expect(find.text('Gagal Memuat Rak'), findsNothing);
    expect(repository.warehouseCalls, [10, 10]);
    expect(results, isEmpty);
  });

  testWidgets('refresh removes stale rows while retaining only the local query',
      (tester) async {
    final repository = _Repository()..load = () async => [_rack(1, 'A', 'Lama')];
    final results = <RakModel?>[];
    final container = await _openPicker(tester, repository, results, selectedRackId: 1);
    await _search(tester, 'a');
    final pending = Completer<List<RakModel>>();
    repository.load = () => pending.future;
    container.invalidate(rakPenerimaanProvider(10));
    await tester.pump();
    expect(find.text('A (Lama)'), findsNothing);
    expect(find.text('Memuat rak...'), findsOneWidget);
    expect(find.byTooltip('Rak terpilih'), findsNothing);

    pending.complete([_rack(2, 'AB', 'Baru')]);
    await tester.pumpAndSettle();
    expect(find.text('A (Lama)'), findsNothing);
    expect(find.text('AB (Baru)'), findsOneWidget);
    expect(find.byTooltip('Rak terpilih'), findsNothing);
    expect(results, isEmpty);
    expect(repository.warehouseCalls, [10, 10]);
  });

  testWidgets('320px with keyboard wraps long names and scrolls to a choice',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    const warehouse = 'Gudang Penerimaan Peralatan dan Bahan Medis Rumah Sakit';
    const name = 'Peralatan steril berukuran panjang untuk kebutuhan rumah sakit';
    final racks = List.generate(20, (index) => _rack(
      index + 1, 'RAK-$index', '$name $index', namaGudang: warehouse,
    ));
    final repository = _Repository()..load = () async => racks;
    final results = <RakModel?>[];
    await _openPicker(tester, repository, results, namaGudang: warehouse);
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await _search(tester, 'rak');
    expect(tester.takeException(), isNull);
    expect(find.text('Gudang Penerima: $warehouse'), findsOneWidget);
    final target = find.text('RAK-19 ($name 19)');
    final rackList = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );
    for (var attempt = 0; attempt < 40; attempt++) {
      if (target.evaluate().isNotEmpty &&
          tester.getBottomRight(target).dy <= 440) {
        break;
      }
      await tester.drag(rackList, const Offset(0, -180));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    expect(tester.getBottomRight(target).dy, lessThanOrEqualTo(440));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(results.single, same(racks.last));
  });
}
