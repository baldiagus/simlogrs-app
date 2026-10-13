import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/notifikasi/data/repositories/notifikasi_repository.dart';

/// Storage palsu: hanya menyediakan token agar interceptor Bearer berjalan tanpa platform channel.
class FakeSecureStorageService extends Fake implements SecureStorageService {
  /// Mengembalikan token tiruan.
  @override
  Future<String?> getToken() async => 'mock_token';
}

/// Adapter HTTP palsu: mencatat request dan membalas lewat [responder] tanpa jaringan.
class FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) responder;
  final List<RequestOptions> requests = [];

  /// Membuat [FakeAdapter] dengan [responder].
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

/// Membungkus [data] dalam envelope standar API.
Map<String, dynamic> envelope(Object? data) => {
      'sukses': true,
      'pesan': 'OK',
      'data': data,
      'meta': {'versi_api': 'v1.0'},
    };

/// Membangun [NotifikasiRepository] di atas [DioClient] sungguhan dengan adapter palsu.
NotifikasiRepository buildRepo(FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = DioClient(storageService: FakeSecureStorageService(), customDio: dio);
  return NotifikasiRepository(client);
}

/// Pengujian [NotifikasiRepository] terhadap kontrak endpoint /notifikasi.
void main() {
  group('getDaftar', () {
    test('memetakan items, paginasi, dan belum_dibaca; mengirim query yang benar', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({
            'items': [
              {
                'id': 12,
                'judul': 'Pengajuan PR Baru',
                'pesan': 'PR-2026-0005',
                'tipe': 'APPROVAL_PR',
                'referensi_id': '14',
                'tautan': '/kepala-unit/approval',
                'dibaca': false,
                'dibuat_pada': '2026-10-13T10:15:00+07:00',
              },
              {'id': 11, 'judul': 'Lama', 'pesan': 'x', 'tipe': null, 'dibaca': true},
            ],
            'paginasi': {'total': 25, 'per_halaman': 2, 'halaman_ini': 2, 'total_halaman': 13},
            'belum_dibaca': 4,
          })));
      final res = await buildRepo(adapter).getDaftar(page: 2, hanyaBelumDibaca: true);

      expect(adapter.requests.single.path, '/notifikasi');
      expect(adapter.requests.single.queryParameters['page'], 2);
      expect(adapter.requests.single.queryParameters['hanya_belum_dibaca'], 1);
      expect(res.belumDibaca, 4);
      expect(res.halaman.items, hasLength(2));
      expect(res.halaman.items.first.tipe, 'APPROVAL_PR');
      expect(res.halaman.items.last.tipe, 'UMUM');
      expect(res.halaman.meta.total, 25);
      expect(res.halaman.meta.halamanIni, 2);
      expect(res.halaman.meta.hasMore, isTrue);
    });

    test('data tanpa items menghasilkan halaman kosong', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope(<String, dynamic>{})));
      final res = await buildRepo(adapter).getDaftar();
      expect(res.halaman.items, isEmpty);
      expect(res.belumDibaca, 0);
    });
  });

  group('tandaiDibaca', () {
    test('POST /notifikasi/{id}/dibaca dan mengembalikan belum_dibaca', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({'belum_dibaca': 3})));
      final sisa = await buildRepo(adapter).tandaiDibaca(12);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/notifikasi/12/dibaca');
      expect(sisa, 3);
    });

    test('404 dilempar sebagai ApiException dengan statusCode 404', () async {
      final adapter = FakeAdapter((o) => jsonResponse(
            {'sukses': false, 'pesan': 'Notifikasi tidak ditemukan'},
            404,
          ));
      await expectLater(
        buildRepo(adapter).tandaiDibaca(99),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Notifikasi tidak ditemukan')
            .having((e) => e.isNetworkError, 'isNetworkError', isFalse)),
      );
    });
  });

  group('bacaSemua', () {
    test('POST /notifikasi/baca-semua', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({'belum_dibaca': 0})));
      await buildRepo(adapter).bacaSemua();
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/notifikasi/baca-semua');
    });
  });

  test('gagal koneksi menandai isNetworkError true', () async {
    final adapter = FakeAdapter((o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        ));
    await expectLater(
      buildRepo(adapter).getDaftar(),
      throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
    );
  });
}
