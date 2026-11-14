import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/po_model.dart';
import 'package:simlog_mobile/features/pengadaan/data/repositories/pengadaan_repository.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/terbitkan_po_sheet.dart';

const _pr = ApprovalItemModel(
  id: 31,
  tipe: 'PR',
  kode: 'PR-TEST-031',
  unit: 'IGD',
  pengaju: 'Pengaju Uji',
  tanggal: '2026-11-14',
  urgensi: 'REGULER',
  status: 'DITERUSKAN_KE_PENGADAAN',
  jumlahItem: 1,
  items: [
    ApprovalDetailItem(
      barangId: 12,
      namaBarang: 'Kertas A4',
      satuan: 'Rim',
      jumlah: 3,
      hargaBeliTerakhir: 45000,
    ),
  ],
);

const _vendors = [
  PemasokOptionModel(id: 7, kode: 'VND-A', nama: 'CV Sumber Makmur'),
  PemasokOptionModel(id: 19, kode: 'VND-B', nama: 'CV Sumber Makmur'),
];

Finder get _search => find.byWidgetPredicate((widget) =>
    widget is TextField &&
    widget.decoration?.hintText == 'Cari nama atau kode vendor...');

class _Storage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => null;
}

/// Menjalankan repository/notifier asli, hanya HTTP eksternal yang diganti.
class _Api implements HttpClientAdapter {
  List<PemasokOptionModel> vendors = _vendors;
  final orders = <Map<String, dynamic>>[];
  Completer<ResponseBody>? pendingVendors;
  int vendorStatus = 200;

  ResponseBody vendorResponse() => ResponseBody.fromString(
        jsonEncode({
          'data': vendors
              .map((v) => {
                    'id': v.id,
                    'nama': v.nama,
                    'kode': v.kode,
                  })
              .toList()
        }),
        vendorStatus,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        },
      );

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.method == 'GET' && options.path == '/pengadaan/pemasok') {
      return pendingVendors?.future ?? Future.value(vendorResponse());
    }
    if (options.method == 'POST' && options.path == '/pengadaan/po') {
      orders.add(Map<String, dynamic>.from(options.data as Map));
      // Respons gagal mempertahankan draft dan tidak memicu refresh layar lain.
      return ResponseBody.fromString(
        jsonEncode({'pesan': 'PO uji tidak diterbitkan.'}),
        422,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        },
      );
    }
    throw StateError(
        'Request tidak diharapkan: ${options.method} ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

Future<ProviderContainer> _openForm(WidgetTester tester, _Api api) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final dio = Dio()..httpClientAdapter = api;
  addTearDown(() => dio.close(force: true));
  final repository = PengadaanRepository(
    DioClient(storageService: _Storage(), customDio: dio),
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [
      pengadaanRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => TerbitkanPoSheet.show(context, _pr),
                  child: const Text('Buka form PO'),
                ),
              )),
    ),
  ));
  await tester.tap(find.text('Buka form PO'));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(TerbitkanPoSheet)),
    listen: false,
  );
}

Future<void> _choose(WidgetTester tester, String field, String code) async {
  await tester.ensureVisible(find.text(field));
  await tester.tap(find.text(field));
  await tester.pumpAndSettle();
  await tester.enterText(_search, code);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.tap(find.widgetWithText(ListTile, code));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('form PO membuka pencarian dan memilih vendor berdasarkan kode',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        pemasokListProvider.overrideWith((ref) async => _vendors),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TerbitkanPoSheet(prItem: _pr)),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih vendor rekanan...'));
    await tester.pumpAndSettle();

    expect(_search, findsOneWidget);
    await tester.enterText(_search, '  vNd-b  ');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('VND-A'), findsNothing);
    await tester.tap(find.text('VND-B'));
    await tester.pumpAndSettle();

    expect(_search, findsNothing);
    expect(find.textContaining('VND-B'), findsOneWidget);
    expect(find.text('45000'), findsOneWidget);
  });

  testWidgets(
      'batal menjaga draft; ganti vendor mengirim ID dan input yang benar',
      (tester) async {
    final api = _Api();
    await _openForm(tester, api);
    await _choose(tester, 'Pilih vendor rekanan...', 'VND-A');

    await tester.tap(find.byIcon(LucideIcons.calendar));
    await tester.pumpAndSettle();
    final month = tester
        .widget<CalendarDatePicker>(
          find.byType(CalendarDatePicker),
        )
        .initialDate!;
    await tester.tap(find.text('28'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final chosenDate = DateTime(month.year, month.month, 28);

    await tester.tap(find.text('Tempo 30 Hari'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tunai / Cash').last);
    await tester.pumpAndSettle();
    final notes = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText ==
            'Misal: Dikirim ke Gudang Sentral Lt.1...');
    await tester.enterText(notes, 'Kirim ke gudang pada jam kerja');
    await tester.enterText(find.widgetWithText(TextField, '45000'), '52000');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    await tester.tap(find.text('CV Sumber Makmur (VND-A)'));
    await tester.pumpAndSettle();
    await tester.enterText(_search, 'vnd-b');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byTooltip('Tutup').last);
    await tester.pumpAndSettle();
    expect(find.text('CV Sumber Makmur (VND-A)'), findsOneWidget);
    expect(find.text('52000'), findsOneWidget);
    expect(find.text('Kirim ke gudang pada jam kerja'), findsOneWidget);
    expect(find.text('Tunai / Cash'), findsOneWidget);
    expect(api.orders, isEmpty);

    await _choose(tester, 'CV Sumber Makmur (VND-A)', 'VND-B');
    await tester.tap(find.text('Konfirmasi Terbitkan PO'));
    await tester.pumpAndSettle();
    expect(api.orders, [
      {
        'permintaan_pengadaan_id': 31,
        'pemasok_id': 19,
        'estimasi_tanggal_kirim': chosenDate.toIso8601String().substring(0, 10),
        'syarat_pembayaran': 'TUNAI',
        'catatan': 'Kirim ke gudang pada jam kerja',
        'items': [
          {'barang_id': 12, 'jumlah': 3, 'harga_satuan': 52000.0}
        ],
      }
    ]);
    expect(find.textContaining('PO uji tidak diterbitkan.'), findsOneWidget);
    expect(find.text('52000'), findsOneWidget);
    expect(find.text('CV Sumber Makmur (VND-B)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'tanpa pilihan, loading, error, dan vendor hilang tidak mengirim PO',
      (tester) async {
    final api = _Api();
    final container = await _openForm(tester, api);
    await tester.tap(find.text('Konfirmasi Terbitkan PO'));
    await tester.pumpAndSettle();
    expect(api.orders, isEmpty);
    expect(
        find.textContaining('Pilih rekanan / vendor pemasok'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await _choose(tester, 'Pilih vendor rekanan...', 'VND-A');

    final pending = Completer<ResponseBody>();
    api.pendingVendors = pending;
    container.invalidate(pemasokListProvider);
    await tester.pump();
    await tester.tap(find.text('Konfirmasi Terbitkan PO'));
    await tester.pump();
    expect(api.orders, isEmpty);
    expect(find.textContaining('Daftar vendor belum siap'), findsOneWidget);

    api.vendorStatus = 503;
    pending.complete(api.vendorResponse());
    api.pendingVendors = null;
    await tester.pumpAndSettle();
    expect(find.text('Gagal Memuat Vendor'), findsOneWidget);
    await tester.tap(find.text('Konfirmasi Terbitkan PO'));
    await tester.pumpAndSettle();
    expect(api.orders, isEmpty);

    api.vendorStatus = 200;
    api.vendors = [_vendors.last];
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Vendor tidak tersedia. Pilih kembali.'), findsOneWidget);
    await tester.tap(find.text('Konfirmasi Terbitkan PO'));
    await tester.pumpAndSettle();
    expect(api.orders, isEmpty);
    expect(find.text('45000'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
