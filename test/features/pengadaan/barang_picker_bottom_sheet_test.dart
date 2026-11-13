import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/maintenance/presentation/widgets/sparepart_picker_sheet.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/master_barang_model.dart';
import 'package:simlog_mobile/features/pengadaan/data/repositories/pengadaan_repository.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/screens/form_pengajuan_pr_screen.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/barang_picker_bottom_sheet.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/pr_cart_item_tile.dart';

typedef _Request = ({String? cari, String? tipe, int page, int perHalaman});

class _Repository extends Fake implements PengadaanRepository {
  _Repository(this.respond);

  final FutureOr<PagedResponse<MasterBarangModel>> Function(_Request) respond;
  final requests = <_Request>[];

  @override
  Future<PagedResponse<MasterBarangModel>> getKatalogBarang({
    String? cari,
    String? tipe,
    int page = 1,
    int perHalaman = 50,
  }) async {
    final request = (cari: cari, tipe: tipe, page: page, perHalaman: perHalaman);
    requests.add(request);
    return respond(request);
  }
}

class _AuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _AuthNotifier() : super(AuthState.authenticated(const UserModel(
    id: 1,
    name: 'Petugas IGD',
    email: 'petugas@example.test',
    roles: ['petugas_unit'],
    permissions: [],
    unit: UnitModel(id: 1, nama: 'IGD', kode: 'IGD'),
  )));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MasterBarangModel _barang(int id, String nama, {String tipe = 'HABIS_PAKAI', int stok = 0}) =>
    MasterBarangModel(
      id: id,
      kode: 'BRG-$id',
      nama: nama,
      tipe: tipe,
      kategori: 'Umum',
      satuan: 'Pcs',
      merek: '-',
      hargaEstimasi: 1000,
      stok: stok,
    );

PagedResponse<MasterBarangModel> _page(List<MasterBarangModel> items, {int page = 1, int pages = 1}) =>
    PagedResponse(
      items: items,
      meta: PaginationMeta(
        total: pages == 1 ? items.length : 51,
        perHalaman: 50,
        halamanIni: page,
        totalHalaman: pages,
      ),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openPicker(
  WidgetTester tester,
  _Repository repository, {
  required ValueChanged<MasterBarangModel> onSelected,
  bool maintenance = false,
}) async {
  _phone(tester);
  await tester.pumpWidget(ProviderScope(
    overrides: [pengadaanRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      return TextButton(
        onPressed: () {
          if (maintenance) {
            SparepartPickerSheet.show(context, onSelected: onSelected);
          } else {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => BarangPickerBottomSheet(onBarangSelected: onSelected),
            );
          }
        },
        child: const Text('Buka katalog'),
      );
    }))),
  ));
  await tester.tap(find.text('Buka katalog'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one/two/three letters search after debounce; clear cancels pending text', (tester) async {
    final repository = _Repository((request) => _page([
      _barang(1, request.cari?.isNotEmpty == true ? 'Hasil ${request.cari}' : 'Katalog awal'),
    ]));
    await _openPicker(tester, repository, onSelected: (_) {});
    expect(find.text('Katalog Master Barang'), findsOneWidget);
    expect(find.text('Katalog awal'), findsOneWidget);
    expect(find.byTooltip('Tutup'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is TextField &&
        widget.decoration?.hintText == 'Cari nama barang atau kode SKU...'), findsOneWidget);

    for (final query in ['p', 'po', 'pom']) {
      final before = repository.requests.length;
      await tester.enterText(find.byType(TextField), query);
      await tester.pump(const Duration(milliseconds: 299));
      expect(repository.requests, hasLength(before));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(repository.requests, hasLength(before + 1));
      expect(repository.requests.last.cari, query);
      expect(repository.requests.last.tipe, isNull);
      expect(repository.requests.last.page, 1);
      expect(find.text('Hasil $query'), findsOneWidget);
    }

    await tester.enterText(find.byType(TextField), 'teks tertunda');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Hapus teks'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(find.text('Katalog awal'), findsOneWidget);
    expect(repository.requests.where((request) => request.cari == 'teks tertunda'), isEmpty);
    expect(repository.requests.last.cari, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial failure offers retry instead of claiming the catalogue is empty', (tester) async {
    var attempts = 0;
    final repository = _Repository((_) {
      if (attempts++ == 0) throw ApiException(message: 'Katalog gagal');
      return _page([_barang(1, 'Katalog pulih')]);
    });
    await _openPicker(tester, repository, onSelected: (_) {});

    expect(find.text('Gagal Memuat Katalog'), findsOneWidget);
    expect(find.text('Barang Tidak Ditemukan'), findsNothing);
    await tester.tap(find.textContaining('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Katalog pulih'), findsOneWidget);
    expect(find.text('Gagal Memuat Katalog'), findsNothing);
    expect(repository.requests.map((request) => request.page), [1, 1]);
  });

  testWidgets('next-page failure keeps rows visible and manual retry requests the same page', (tester) async {
    var nextAttempts = 0;
    final repository = _Repository((request) {
      if (request.page == 1) {
        return _page(List.generate(50, (index) => _barang(index + 1, 'Barang ${index + 1}')), pages: 2);
      }
      if (nextAttempts++ == 0) throw ApiException(message: 'Halaman gagal');
      return _page([_barang(51, 'Barang halaman kedua')], page: 2, pages: 2);
    });
    await _openPicker(tester, repository, onSelected: (_) {});
    final list = find.descendant(of: find.byType(BarangPickerBottomSheet), matching: find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down));
    await tester.scrollUntilVisible(find.text('Barang 50'), 500, scrollable: list, maxScrolls: 25);
    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Coba Lagi'), findsOneWidget);
    expect(find.text('Barang 50'), findsOneWidget);
    expect(find.text('Gagal Memuat Katalog'), findsNothing);
    expect(repository.requests.map((request) => request.page), [1, 2]);
    await tester.tap(find.textContaining('Coba Lagi'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Barang halaman kedua'), 300, scrollable: list);

    expect(find.text('Barang halaman kedua'), findsOneWidget);
    expect(find.textContaining('Coba Lagi'), findsNothing);
    expect(repository.requests.map((request) => request.page), [1, 2, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll loads beyond 50 and allows selecting a zero-stock ASET master', (tester) async {
    final asset = _barang(51, 'Ventilator master baru', tipe: 'ASET');
    final repository = _Repository((request) => request.page == 1
        ? _page(List.generate(50, (index) => _barang(index + 1, 'Barang ${index + 1}')), pages: 2)
        : _page([asset], page: 2, pages: 2));
    MasterBarangModel? selected;
    await _openPicker(tester, repository, onSelected: (barang) => selected = barang);
    final list = find.descendant(of: find.byType(BarangPickerBottomSheet), matching: find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down));

    await tester.scrollUntilVisible(find.text(asset.nama), 500, scrollable: list, maxScrolls: 25);
    await tester.pumpAndSettle();
    expect(repository.requests.map((request) => request.page), [1, 2]);
    expect(repository.requests.every((request) => request.tipe == null), isTrue);
    await tester.tap(find.text(asset.nama));
    await tester.pumpAndSettle();

    expect(selected, same(asset));
    expect(selected!.stok, 0);
    expect(selected!.tipe, 'ASET');
    expect(find.byType(BarangPickerBottomSheet), findsNothing);
    expect(find.text('Buka katalog'), findsOneWidget);
  });

  testWidgets('PR selection permits a zero-stock consumable and invokes callback once', (tester) async {
    final barang = _barang(1, 'Kertas stok kosong');
    final repository = _Repository((_) => _page([barang]));
    final selected = <MasterBarangModel>[];
    await _openPicker(tester, repository, onSelected: selected.add);

    await tester.tap(find.text(barang.nama));
    await tester.pumpAndSettle();

    expect(selected, [barang]);
    expect(find.byType(BarangPickerBottomSheet), findsNothing);
  });

  testWidgets('maintenance requests only SPAREPART, rejects empty stock and keeps positive stock selectable', (tester) async {
    final empty = _barang(1, 'Filter kosong', tipe: 'SPAREPART');
    final available = _barang(2, 'Filter tersedia', tipe: 'SPAREPART', stok: 4);
    final repository = _Repository((_) => _page([empty, available, _barang(3, 'Aset bukan sparepart', tipe: 'ASET')]));
    final selected = <MasterBarangModel>[];
    await _openPicker(tester, repository, onSelected: selected.add, maintenance: true);
    expect(repository.requests.single.tipe, 'SPAREPART');
    expect(find.text('Katalog Suku Cadang'), findsOneWidget);
    expect(find.text('Aset bukan sparepart'), findsNothing);
    expect(find.text('Stok: 0'), findsOneWidget);
    expect(find.text('Stok: 4'), findsOneWidget);

    await tester.tap(find.text(empty.nama));
    await tester.pump();
    expect(selected, isEmpty);
    expect(find.byType(BarangPickerBottomSheet), findsOneWidget);
    expect(find.textContaining('Stok suku cadang Filter kosong di gudang habis'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text(available.nama));
    await tester.pumpAndSettle();

    expect(selected, [available]);
    expect(find.byType(BarangPickerBottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the picker cancels pending search without selecting an item', (tester) async {
    final repository = _Repository((_) => _page([_barang(1, 'Kertas')]));
    final selected = <MasterBarangModel>[];
    await _openPicker(tester, repository, onSelected: selected.add);
    await tester.enterText(find.byType(TextField), 'belum selesai');
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(selected, isEmpty);
    expect(repository.requests, hasLength(1));
    expect(find.byType(BarangPickerBottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PR form adds zero-stock item and picking it again increments the same cart row', (tester) async {
    _phone(tester);
    final barang = _barang(1, 'Kertas untuk pengajuan');
    final repository = _Repository((_) => _page([barang]));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        pengadaanRepositoryProvider.overrideWithValue(repository),
        authStateProvider.overrideWith((ref) => _AuthNotifier()),
      ],
      child: const MaterialApp(home: FormPengajuanPrScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Pengajuan PR Baru'), findsOneWidget);
    expect(find.text('0 Barang (0 Jenis)'), findsOneWidget);
    expect(find.text('Kirim Pengajuan PR'), findsOneWidget);
    await tester.ensureVisible(find.text('Pilih dari Katalog'));
    await tester.tap(find.text('Pilih dari Katalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BarangPickerBottomSheet), matching: find.text(barang.nama)));
    await tester.pumpAndSettle();

    expect(find.byType(PrCartItemTile), findsOneWidget);
    expect(find.text(barang.nama), findsOneWidget);
    expect(find.text('1 Barang (1 Jenis)'), findsOneWidget);
    await tester.ensureVisible(find.text('Tambah'));
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BarangPickerBottomSheet), matching: find.text(barang.nama)));
    await tester.pumpAndSettle();

    expect(find.byType(PrCartItemTile), findsOneWidget);
    expect(find.text('2 Barang (1 Jenis)'), findsOneWidget);
    expect(repository.requests.every((request) => request.tipe == null), isTrue);
    expect(tester.takeException(), isNull);
  });
}
