import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/pengadaan/data/repositories/pengadaan_repository.dart';

/// Penyimpanan aman palsu agar interceptor token tidak menyentuh storage asli.
class _FakeStorage extends Fake implements SecureStorageService {
  /// Mengembalikan token palsu tetap.
  @override
  Future<String?> getToken() async => 'mock_token';
}

/// Adapter HTTP palsu: mencatat request terakhir dan membalas JSON sesuai [handler].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ({int status, Object? body}) Function(RequestOptions options) handler;
  RequestOptions? last;

  /// Membalas request dengan status dan body JSON dari [handler] tanpa jaringan.
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    final r = handler(options);
    return ResponseBody.fromString(
      jsonEncode(r.body),
      r.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  /// Tidak ada sumber daya yang perlu ditutup.
  @override
  void close({bool force = false}) {}
}

/// Membuat repository dengan adapter palsu yang membalas [status] dan [body].
(PengadaanRepository, _FakeAdapter) _buat(int status, Object? body) {
  final adapter = _FakeAdapter((_) => (status: status, body: body));
  final dio = Dio()..httpClientAdapter = adapter;
  final client = DioClient(storageService: _FakeStorage(), customDio: dio);
  return (PengadaanRepository(client), adapter);
}

void main() {
  group('PengadaanRepository.getKatalogBarang', () {
    test('parse JSON ke MasterBarangModel dan kirim filter tidak kosong', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': [
          {
            'id': '7',
            'kode': 'BRG-007',
            'nama': 'Kertas A4',
            'tipe': 'SPAREPART',
            'harga_estimasi': '45000',
            'stok_gudang': 12,
          },
        ],
      });

      final hasil = await repo.getKatalogBarang(cari: 'kertas', tipe: '');

      expect(hasil, hasLength(1));
      expect(hasil.first.id, 7);
      expect(hasil.first.nama, 'Kertas A4');
      expect(hasil.first.tipeLabel, 'Suku Cadang IPSRS');
      expect(hasil.first.hargaEstimasi, 45000.0);
      expect(hasil.first.stok, 12);
      expect(adapter.last!.path, '/master/barang');
      expect(adapter.last!.queryParameters, {'cari': 'kertas'});
    });

    test('lempar ApiException dengan pesan server saat status 500', () async {
      final (repo, _) = _buat(500, {'sukses': false, 'pesan': 'Katalog sedang dipelihara'});

      expect(
        repo.getKatalogBarang(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Katalog sedang dipelihara')
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('PengadaanRepository.getDaftarPr', () {
    test('parse header PR beserta item', () async {
      final (repo, _) = _buat(200, {
        'sukses': true,
        'data': [
          {
            'id': 3,
            'kode': 'PR-2026-003',
            'unit': 'IGD',
            'pengaju': 'Sari',
            'tanggal_permintaan': '2026-10-01',
            'urgensi': 'CITO',
            'status': 'DIAJUKAN',
            'jumlah_item': 1,
            'items': [
              {'id': 1, 'barang_id': 7, 'nama_barang': 'Kertas A4', 'satuan': 'Rim', 'jumlah': 5},
            ],
          },
        ],
      });

      final hasil = await repo.getDaftarPr();

      expect(hasil, hasLength(1));
      expect(hasil.first.kode, 'PR-2026-003');
      expect(hasil.first.isCito, isTrue);
      expect(hasil.first.isDiajukan, isTrue);
      expect(hasil.first.items.single.namaBarang, 'Kertas A4');
      expect(hasil.first.items.single.jumlah, 5);
    });

    test('mengembalikan list kosong bila data bukan list', () async {
      final (repo, _) = _buat(200, {'sukses': true, 'data': null});

      expect(await repo.getDaftarPr(), isEmpty);
    });
  });

  group('PengadaanRepository.submitPr', () {
    test('body POST tanpa status/auto_approve; status hasil diputuskan server', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': {'id': 9, 'kode': 'PR-9', 'status': 'DISETUJUI'},
      });

      final hasil = await repo.submitPr(
        unitId: 2,
        urgensi: 'REGULER',
        catatan: '',
        items: [
          {'barang_id': 7, 'jumlah': 5},
        ],
      );

      expect(hasil['kode'], 'PR-9');
      expect(hasil['status'], 'DISETUJUI');
      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.path, '/pengadaan/pr');
      final body = adapter.last!.data as Map<String, dynamic>;
      expect(body['unit_id'], 2);
      expect(body.containsKey('status'), isFalse);
      expect(body.containsKey('auto_approve'), isFalse);
      expect(body.containsKey('catatan'), isFalse);
      expect(body.containsKey('gudang_id'), isFalse);
    });

    test('body minimal hanya berisi urgensi dan items', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': {'id': 10},
      });

      await repo.submitPr(urgensi: 'REGULER', items: const []);

      final body = adapter.last!.data as Map<String, dynamic>;
      expect(body.keys, unorderedEquals(['urgensi', 'items']));
    });

    test('respons tanpa data Map memicu ApiException format tidak valid', () async {
      final (repo, _) = _buat(200, {'sukses': true, 'data': []});

      expect(
        repo.submitPr(urgensi: 'REGULER', items: const []),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Format respons pengajuan tidak valid')),
      );
    });

    test('error validasi 422 membawa pesan dan detail errors', () async {
      final (repo, _) = _buat(422, {
        'sukses': false,
        'pesan': 'Data tidak valid',
        'errors': {
          'items': ['Item wajib diisi'],
        },
      });

      expect(
        repo.submitPr(urgensi: 'REGULER', items: const []),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Data tidak valid: Item wajib diisi')
            .having((e) => e.statusCode, 'statusCode', 422)),
      );
    });
  });

  group('PengadaanRepository.getDaftarPemasok', () {
    test('parse pemasok dengan nilai bawaan untuk field kosong', () async {
      final (repo, _) = _buat(200, {
        'sukses': true,
        'data': [
          {'id': 4, 'kode': 'SUP-04', 'nama': 'PT Medika', 'kota': 'Bandung'},
        ],
      });

      final hasil = await repo.getDaftarPemasok();

      expect(hasil.single.id, 4);
      expect(hasil.single.nama, 'PT Medika');
      expect(hasil.single.kota, 'Bandung');
      expect(hasil.single.noTelepon, isNull);
    });
  });
}
