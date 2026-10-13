import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/anggaran/data/repositories/anggaran_repository.dart';

/// Storage palsu: hanya menyediakan token agar interceptor Bearer berjalan tanpa platform channel.
class FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'mock_token';
}

/// Adapter HTTP palsu: mencatat setiap request dan membalas lewat [responder] tanpa jaringan.
class FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) responder;
  final List<RequestOptions> requests = [];

  FakeAdapter(this.responder);

  /// Mencatat request lalu mengembalikan balasan dari [responder].
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return responder(options);
  }

  /// Tidak ada sumber daya yang perlu ditutup.
  @override
  void close({bool force = false}) {}
}

/// Membuat balasan JSON dengan [status] HTTP tertentu.
ResponseBody jsonResponse(Object body, [int status = 200]) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Membungkus [data] dalam envelope standar API {sukses, pesan, data, meta}.
Map<String, dynamic> envelope(Object? data) => {
      'sukses': true,
      'pesan': 'OK',
      'data': data,
      'meta': {'versi_api': 'v1.0'},
    };

/// Membangun [AnggaranRepository] di atas [DioClient] sungguhan dengan adapter palsu.
AnggaranRepository buildRepo(FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = DioClient(storageService: FakeSecureStorageService(), customDio: dio);
  return AnggaranRepository(client);
}

void main() {
  group('AnggaranRepository.getScreeningAnggaran', () {
    final screeningJson = envelope({
      'tahun': '2026',
      'ringkasan': {
        'total_pagu': 1500000000,
        'total_realisasi_distribusi': 400000000.5,
        'total_realisasi_sparepart': 100000000,
        'total_realisasi_global': 500000000.5,
        'total_sisa_global': 999999999.5,
        'serapan_global_persen': 33.33,
      },
      'unit_anggarans': [
        {
          'id': 1,
          'kode': 'AGR-001',
          'pos_anggaran': 'Logistik Medis',
          'unit_id': 9,
          'unit_nama': 'IGD',
          'unit_kode': 'IGD',
          'pagu': 200000000,
          'realisasi': 190000000,
          'sisa': 10000000,
          'serapan': 95.0,
          'status': 'Kritis',
          'beban_distribusi': 150000000,
          'beban_sparepart': 40000000,
        },
      ],
      'sparepart_anggaran': {
        'id': 2,
        'kode': 'AGR-SP',
        'pos_anggaran': 'Sparepart',
        'pagu': 100000000,
        'realisasi': 60000000,
        'sisa': 40000000,
        'serapan': 60,
        'status': 'Waspada',
      },
      'top_aset': [],
      'riwayat_sparepart': [],
    });

    test('mem-parse ringkasan, unit, dan sparepart; tahun default 2026 dikirim', () async {
      final adapter = FakeAdapter((o) => jsonResponse(screeningJson));
      final repo = buildRepo(adapter);

      final model = await repo.getScreeningAnggaran();

      final req = adapter.requests.single;
      expect(req.path, '/anggaran/realisasi');
      expect(req.queryParameters, {'tahun': '2026'});
      expect(model.tahun, '2026');
      expect(model.ringkasan.totalPagu, 1500000000.0);
      expect(model.ringkasan.totalRealisasiDistribusi, 400000000.5);
      expect(model.ringkasan.serapanGlobalPersen, 33.33);
      expect(model.unitAnggarans, hasLength(1));
      expect(model.unitAnggarans.single.unitNama, 'IGD');
      expect(model.unitAnggarans.single.unitId, 9);
      expect(model.unitAnggarans.single.status, 'Kritis');
      expect(model.unitAnggarans.single.bebanSparepart, 40000000.0);
      expect(model.sparepartAnggaran?.serapan, 60.0);
      expect(model.topAset, isEmpty);
    });

    test('mengirim tahun kustom ke queryParameters', () async {
      final adapter = FakeAdapter((o) => jsonResponse(screeningJson));
      final repo = buildRepo(adapter);

      await repo.getScreeningAnggaran(tahun: '2025');

      expect(adapter.requests.single.queryParameters, {'tahun': '2025'});
    });

    test('sub-objek yang hilang menjadi default aman', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({'tahun': '2026'})));
      final repo = buildRepo(adapter);

      final model = await repo.getScreeningAnggaran();

      expect(model.ringkasan.totalPagu, 0.0);
      expect(model.unitAnggarans, isEmpty);
      expect(model.sparepartAnggaran, isNull);
    });

    test('melempar ApiException format tidak valid bila data null', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope(null)));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getScreeningAnggaran(),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', 'Format data pagu & realisasi tidak valid')),
      );
    });

    test('500 diubah menjadi ApiException dengan pesan dari server', () async {
      final adapter = FakeAdapter((o) => jsonResponse({
            'sukses': false,
            'pesan': 'Gagal menghitung realisasi anggaran',
          }, 500));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getScreeningAnggaran(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Gagal menghitung realisasi anggaran')
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('AnggaranRepository.getUnitDetail', () {
    test('mem-parse drilldown unit beserta riwayat SPPB dan servis', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({
            'unit': {'id': 9, 'kode': 'IGD', 'nama': 'Instalasi Gawat Darurat'},
            'tahun': '2025',
            'beban_distribusi': 150000000,
            'beban_sparepart': 40000000,
            'total_pengeluaran': 190000000,
            'riwayat_sppb': [
              {
                'id': 11,
                'kode': 'SPPB-0011',
                'tanggal_kirim': '2025-03-02',
                'gudang_nama': 'Gudang Farmasi',
                'status': 'SELESAI',
                'total_item': 5,
                'total_nilai': 2500000,
              },
            ],
            'riwayat_servis': [
              {
                'id': 21,
                'spk_kode': 'SPK-0021',
                'aset_nama': 'Ventilator',
                'sparepart_nama': 'Filter HEPA',
                'jumlah': 2,
                'subtotal': 1200000,
                'tanggal': '2025-04-10',
              },
            ],
          })));
      final repo = buildRepo(adapter);

      final detail = await repo.getUnitDetail(9, tahun: '2025');

      final req = adapter.requests.single;
      expect(req.path, '/anggaran/unit/9');
      expect(req.queryParameters, {'tahun': '2025'});
      expect(detail.unitNama, 'Instalasi Gawat Darurat');
      expect(detail.totalPengeluaran, 190000000.0);
      expect(detail.riwayatSppb.single.kode, 'SPPB-0011');
      expect(detail.riwayatSppb.single.totalItem, 5);
      expect(detail.riwayatServis.single.sparepartNama, 'Filter HEPA');
      expect(detail.riwayatServis.single.subtotal, 1200000.0);
    });

    test('404 diubah menjadi ApiException dengan pesan dari server', () async {
      final adapter = FakeAdapter((o) => jsonResponse({
            'sukses': false,
            'pesan': 'Unit tidak ditemukan',
          }, 404));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getUnitDetail(404),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Unit tidak ditemukan')
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('timeout tanpa respons ditandai isNetworkError', () async {
      final adapter = FakeAdapter((o) => throw DioException(
            requestOptions: o,
            type: DioExceptionType.receiveTimeout,
          ));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getUnitDetail(9),
        throwsA(isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)
            .having((e) => e.message, 'message', contains('terlalu lambat'))),
      );
    });
  });
}
