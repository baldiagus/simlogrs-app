import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';

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

/// Membangun [AuditRepository] di atas [DioClient] sungguhan dengan adapter palsu.
AuditRepository buildRepo(FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = DioClient(storageService: FakeSecureStorageService(), customDio: dio);
  return AuditRepository(client);
}

void main() {
  group('AuditRepository.getSummary', () {
    test('memetakan JSON ringkasan ke AuditSummaryModel', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({
            'capa': {
              'total_temuan': 12,
              'total_closed': 5,
              'total_in_progress': 4,
              'total_in_review': 3,
              'mayor_open': 2,
              'overdue': 1,
              'closing_rate': 41.5,
            },
            'kepatuhan_po': {
              'tanpa_pr': 3,
              'terlambat': 2,
              'selisih_rcv': 1,
              'total_anomali': 6,
            },
            'selisih_opname': {'sesi_berselisih': 2, 'penyesuaian_menunggu': 4},
            'total_log_audit': 980,
          })));
      final repo = buildRepo(adapter);

      final summary = await repo.getSummary();

      expect(adapter.requests.single.path, '/audit/summary');
      expect(adapter.requests.single.headers['Authorization'], 'Bearer mock_token');
      expect(summary.totalTemuan, 12);
      expect(summary.closingRate, 41.5);
      expect(summary.poTanpaPr, 3);
      expect(summary.totalPoAnomali, 6);
      expect(summary.penyesuaianMenunggu, 4);
      expect(summary.totalLogAudit, 980);
    });

    test('melempar ApiException dengan pesan server saat 500', () async {
      final adapter = FakeAdapter((o) => jsonResponse({
            'sukses': false,
            'pesan': 'Database audit sedang tidak tersedia',
          }, 500));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getSummary(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Database audit sedang tidak tersedia')
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.isNetworkError, 'isNetworkError', false)),
      );
    });

    test('melempar ApiException format tidak valid bila data bukan objek', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope(null)));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getSummary(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Format ringkasan audit tidak valid')),
      );
    });
  });

  group('AuditRepository.getAuditTrail', () {
    final trailJson = envelope({
      'items': [
        {
          'id': 101,
          'pengguna_nama': 'Budi Santoso',
          'pengguna_nip': '19800101',
          'peran': 'staf_gudang',
          'aksi': 'UPDATE',
          'referensi_jenis': 'Barang',
          'referensi_id': 55,
          'ip_address': '10.0.0.5',
          'device': 'Chrome',
          'waktu': '2 jam lalu',
          'timestamp': '2026-10-13T08:00:00Z',
          'has_data_sebelum': true,
          'has_data_sesudah': true,
        },
        {'id': 102},
      ],
    });

    test('mengirim page dan filter di queryParameters, lalu mem-parse item', () async {
      final adapter = FakeAdapter((o) => jsonResponse(trailJson));
      final repo = buildRepo(adapter);

      final items = await repo.getAuditTrail(
        aksi: 'UPDATE',
        entitas: 'Barang',
        search: '  budi  ',
        page: 3,
      );

      final req = adapter.requests.single;
      expect(req.path, '/audit/trail');
      expect(req.queryParameters, {
        'aksi': 'UPDATE',
        'entitas': 'Barang',
        'search': 'budi',
        'page': 3,
      });
      expect(items, hasLength(2));
      expect(items[0].id, 101);
      expect(items[0].penggunaNama, 'Budi Santoso');
      expect(items[0].referensiId, 55);
      expect(items[0].hasDataSebelum, isTrue);
      // Field kosong memakai default model.
      expect(items[1].penggunaNama, 'Sistem');
      expect(items[1].hasDataSesudah, isFalse);
    });

    test('hanya mengirim page=1 bila tanpa filter dan mengabaikan string kosong', () async {
      final adapter = FakeAdapter((o) => jsonResponse(trailJson));
      final repo = buildRepo(adapter);

      await repo.getAuditTrail(aksi: '', search: '   ');

      expect(adapter.requests.single.queryParameters, {'page': 1});
    });

    test('mengembalikan daftar kosong bila items tidak ada di respons', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({'total': 0})));
      final repo = buildRepo(adapter);

      expect(await repo.getAuditTrail(), isEmpty);
    });

    test('403 diubah menjadi ApiException dengan pesan dari server', () async {
      final adapter = FakeAdapter((o) => jsonResponse({
            'sukses': false,
            'pesan': 'Anda tidak berhak mengakses audit trail',
          }, 403));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getAuditTrail(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Anda tidak berhak mengakses audit trail')
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('gagal koneksi ditandai isNetworkError', () async {
      final adapter = FakeAdapter((o) => throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
          ));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getAuditTrail(),
        throwsA(isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', true)
            .having((e) => e.statusCode, 'statusCode', isNull)),
      );
    });
  });

  group('AuditRepository.getAuditTrailDetail', () {
    test('mem-parse snapshot data sebelum/sesudah dari path berisi id', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({
            'id': 7,
            'aksi': 'UPDATE',
            'has_data_sebelum': true,
            'has_data_sesudah': true,
            'data_sebelum': {'stok': 10},
            'data_sesudah': {'stok': 8},
          })));
      final repo = buildRepo(adapter);

      final detail = await repo.getAuditTrailDetail(7);

      expect(adapter.requests.single.path, '/audit/trail/7');
      expect(detail.dataSebelum, {'stok': 10});
      expect(detail.dataSesudah, {'stok': 8});
    });

    test('404 diubah menjadi ApiException dengan pesan server', () async {
      final adapter = FakeAdapter((o) => jsonResponse({
            'sukses': false,
            'pesan': 'Log audit tidak ditemukan',
          }, 404));
      final repo = buildRepo(adapter);

      await expectLater(
        repo.getAuditTrailDetail(999),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Log audit tidak ditemukan')
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('AuditRepository.getRegisterTemuan', () {
    test('mengirim filter + page dan mem-parse TemuanCapaModel', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({
            'items': [
              {
                'id': 3,
                'kode': 'TMN-2026-003',
                'tanggal_audit': '2026-10-01',
                'objek_audit': 'Gudang Farmasi',
                'ringkasan': 'Stok kadaluarsa belum dimusnahkan',
                'tingkat_risiko': 'Mayor',
                'due_date_capa': '2026-10-20',
                'status_capa': 'Open',
                'is_overdue': true,
                'bukti_perbaikan': ['foto1.jpg', 'foto2.jpg'],
              },
            ],
          })));
      final repo = buildRepo(adapter);

      final temuan = await repo.getRegisterTemuan(status: 'Open', risiko: 'Mayor', page: 2);

      final req = adapter.requests.single;
      expect(req.path, '/audit/temuan-capa');
      expect(req.queryParameters, {'status': 'Open', 'risiko': 'Mayor', 'page': 2});
      expect(temuan.single.kode, 'TMN-2026-003');
      expect(temuan.single.tingkatRisiko, 'Mayor');
      expect(temuan.single.isOverdue, isTrue);
      expect(temuan.single.buktiPerbaikan, ['foto1.jpg', 'foto2.jpg']);
      expect(temuan.single.gudang, isNull);
    });
  });
}
