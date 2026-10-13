import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/dashboard/data/repositories/dashboard_repository.dart';

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

  /// Daftar path yang sudah diminta, berurutan.
  List<String> get paths => requests.map((r) => r.path).toList();

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

/// Balasan 500 standar untuk endpoint yang disimulasikan gagal.
ResponseBody serverError() =>
    jsonResponse({'sukses': false, 'pesan': 'Server belum siap'}, 500);

/// Membangun [DashboardRepository] di atas [DioClient] sungguhan dengan adapter palsu.
DashboardRepository buildRepo(FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = DioClient(storageService: FakeSecureStorageService(), customDio: dio);
  return DashboardRepository(client);
}

void main() {
  group('DashboardRepository.getSummary (endpoint terpadu)', () {
    test('mem-parse hero dan aktivitas dari /dashboard/summary tanpa memanggil fallback', () async {
      final adapter = FakeAdapter((o) => jsonResponse(envelope({
            'hero': {
              'judul': 'Total Antrean Kerja',
              'total': '12',
              'satuan': 'Tugas',
              'label_tombol': 'Kerjakan',
              'target_aksi': 'picking',
              'sub_metrik': [
                {'label': 'Picking', 'nilai': '8', 'warna': 'blue'},
                {'label': 'Inbound', 'nilai': '4'},
              ],
            },
            'aktivitas': [
              {
                'id': 5,
                'tipe': 'SPK',
                'judul': 'SPK-0005',
                'subjudul': 'Perbaikan AC',
                'timestamp': '2026-10-13T07:00:00Z',
                'waktu_lalu': '1 jam lalu',
                'status': 'DITUGASKAN',
                'kode': 'SPK-0005',
              },
            ],
          })));
      final repo = buildRepo(adapter);

      final summary = await repo.getSummary(canViewSpk: true);

      expect(adapter.paths, ['/dashboard/summary']);
      expect(summary.hero.total, 12); // string "12" dinormalisasi ke int
      expect(summary.hero.satuan, 'Tugas');
      expect(summary.hero.targetAksi, 'picking');
      expect(summary.hero.subMetrik.map((s) => s.label), ['Picking', 'Inbound']);
      expect(summary.hero.subMetrik[1].warna, 'text'); // default
      expect(summary.recentActivities, hasLength(1));
      expect(summary.recentActivities.single.type, 'spk'); // tipe di-lowercase
      expect(summary.recentActivities.single.waktuLalu, '1 jam lalu');
    });
  });

  group('DashboardRepository.getSummary (fallback)', () {
    final approvalJson = envelope({
      'pr': [
        {
          'id': 1,
          'nomor_pr': 'PR-001',
          'nama_unit': 'IGD',
          'tanggal_pengajuan': '2026-10-10',
        },
        {
          'id': 2,
          'nomor_pr': 'PR-002',
          'nama_unit': 'Farmasi',
          'tanggal_pengajuan': '2026-10-12',
        },
      ],
      'amprah': [
        {
          'id': 3,
          'nomor_permintaan': 'AMP-001',
          'nama_unit': 'Radiologi',
          'tanggal_permintaan': '2026-10-11',
        },
      ],
    });

    final spkJson = envelope([
      {'id': 1, 'status': 'DITUGASKAN'},
      {'id': 2, 'status': 'DITERIMA'},
      {'id': 3, 'status': 'SELESAI'},
    ]);

    ResponseBody route(RequestOptions o, {bool summaryFails = true}) {
      switch (o.path) {
        case '/dashboard/summary':
          return summaryFails ? serverError() : jsonResponse(envelope(null));
        case '/approval/pending':
          return jsonResponse(approvalJson);
        case '/maintenance/spk':
          return jsonResponse(spkJson);
      }
      return jsonResponse({'sukses': false, 'pesan': 'tidak dikenal'}, 404);
    }

    test('merakit hitungan dan aktivitas dari approval pending saat endpoint terpadu 500', () async {
      final adapter = FakeAdapter(route);
      final repo = buildRepo(adapter);

      final summary = await repo.getSummary();

      expect(adapter.paths, ['/dashboard/summary', '/approval/pending']);
      expect(summary.hero.judul, 'Total Antrean Approval');
      expect(summary.hero.total, 3); // 2 PR + 1 amprah
      expect(summary.prCount, 2);
      expect(summary.amprahCount, 1);
      expect(summary.activeSpkCount, 0);
      // Urut menurun menurut timestamp: PR-002 (10-12), AMP-001 (10-11), PR-001 (10-10).
      expect(summary.recentActivities.map((a) => a.title), ['PR-002', 'AMP-001', 'PR-001']);
      expect(summary.recentActivities.map((a) => a.type), ['pr', 'amprah', 'pr']);
    });

    test('canViewSpk=true hanya menghitung SPK berstatus DITUGASKAN/DITERIMA', () async {
      final adapter = FakeAdapter(route);
      final repo = buildRepo(adapter);

      final summary = await repo.getSummary(canViewSpk: true);

      expect(adapter.paths, contains('/maintenance/spk'));
      expect(summary.activeSpkCount, 2);
    });

    test('fallback juga dipakai bila /dashboard/summary membalas data non-objek', () async {
      final adapter = FakeAdapter((o) => route(o, summaryFails: false));
      final repo = buildRepo(adapter);

      final summary = await repo.getSummary();

      expect(adapter.paths, ['/dashboard/summary', '/approval/pending']);
      expect(summary.prCount, 2);
    });

    test('semua endpoint gagal menghasilkan ringkasan nol tanpa melempar', () async {
      final adapter = FakeAdapter((o) => serverError());
      final repo = buildRepo(adapter);

      final summary = await repo.getSummary(canViewSpk: true);

      expect(summary.hero.total, 0);
      expect(summary.prCount, 0);
      expect(summary.amprahCount, 0);
      expect(summary.activeSpkCount, 0);
      expect(summary.recentActivities, isEmpty);
    });
  });
}
