import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/maintenance/data/repositories/maintenance_repository.dart';

/// Penyimpanan aman palsu agar interceptor token tidak menyentuh storage asli.
class _FakeStorage extends Fake implements SecureStorageService {
  /// Mengembalikan token palsu tetap.
  @override
  Future<String?> getToken() async => 'mock_token';
}

/// Adapter HTTP palsu: mencatat request terakhir dan membalas JSON tanpa jaringan.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);

  final int status;
  final Object? body;
  RequestOptions? last;

  /// Membalas setiap request dengan [status] dan [body] JSON tetap.
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
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
(MaintenanceRepository, _FakeAdapter) _buat(int status, Object? body) {
  final adapter = _FakeAdapter(status, body);
  final dio = Dio()..httpClientAdapter = adapter;
  final client = DioClient(storageService: _FakeStorage(), customDio: dio);
  return (MaintenanceRepository(client), adapter);
}

void main() {
  group('MaintenanceRepository.getDaftarTiketUnit', () {
    test('parse tiket dan saring filter SEMUA/kosong dari query', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': [
          {
            'id': '11',
            'kode': 'TKT-011',
            'status': 'DILAPORKAN',
            'prioritas': 'CITO',
            'deskripsi_masalah': 'Monitor mati',
            'unit': 'ICU',
            'pelapor': 'Budi',
            'can_cancel': true,
            'aset': {'nama': 'Monitor Pasien', 'kode_aset': 'AST-1'},
            'penugasan_aktif': {'kode_spk': 'SPK-1', 'nama_teknisi': 'Andi'},
          },
        ],
      });

      final hasil = await repo.getDaftarTiketUnit(status: 'SEMUA', prioritas: 'CITO', cari: '  monitor ');

      expect(hasil.single.id, 11);
      expect(hasil.single.isCito, isTrue);
      expect(hasil.single.isDilaporkan, isTrue);
      expect(hasil.single.canCancel, isTrue);
      expect(hasil.single.namaAset, 'Monitor Pasien');
      expect(hasil.single.penugasanAktif?.namaTeknisi, 'Andi');
      expect(adapter.last!.queryParameters, {'prioritas': 'CITO', 'cari': 'monitor'});
    });

    test('error 403 menjadi ApiException dengan pesan dari server', () async {
      final (repo, _) = _buat(403, {'sukses': false, 'pesan': 'Akses ditolak'});

      expect(
        repo.getDaftarTiketUnit(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Akses ditolak')
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });

  group('MaintenanceRepository.getAsetUnitTersedia', () {
    test('parse aset dengan nilai bawaan untuk field kosong', () async {
      final (repo, _) = _buat(200, {
        'sukses': true,
        'data': [
          {'id': 5, 'kode_aset': 'AST-5', 'nama': 'Infus Pump'},
        ],
      });

      final hasil = await repo.getAsetUnitTersedia();

      expect(hasil.single.kodeAset, 'AST-5');
      expect(hasil.single.kondisi, 'BAIK');
      expect(hasil.single.status, 'TERSEDIA');
    });
  });

  group('MaintenanceRepository.batalTiketUnit', () {
    test('sukses false dari server dilempar sebagai ApiException', () async {
      final (repo, adapter) = _buat(200, {'sukses': false, 'pesan': 'Tiket sudah ditugaskan'});

      await expectLater(
        repo.batalTiketUnit(4),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Tiket sudah ditugaskan')),
      );
      expect(adapter.last!.path, '/maintenance/tiket/4/batal');
      expect(adapter.last!.method, 'POST');
    });
  });

  group('MaintenanceRepository.submitLaporCepat', () {
    test('tanpa foto: body Map JSON dengan deskripsi di-trim dan prioritas', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': {'id': 21, 'kode': 'TKT-021'},
      });

      final hasil = await repo.submitLaporCepat(
        asetId: 8,
        kodeAset: '',
        deskripsiMasalah: '  AC bocor  ',
        prioritas: 'TINGGI',
      );

      expect(hasil['kode'], 'TKT-021');
      expect(adapter.last!.path, '/maintenance/lapor-cepat');
      final body = adapter.last!.data;
      expect(body, isA<Map<String, dynamic>>());
      expect(body, {
        'aset_id': 8,
        'deskripsi_masalah': 'AC bocor',
        'prioritas': 'TINGGI',
      });
    });

    test('dengan foto: body FormData berisi field foto dan field teks', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': {'id': 22},
      });
      final foto = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'a.jpg', path: 'a.jpg');

      await repo.submitLaporCepat(
        kodeAset: ' AST-9 ',
        deskripsiMasalah: ' Kabel putus ',
        prioritas: 'SEDANG',
        foto: foto,
      );

      final body = adapter.last!.data;
      expect(body, isA<FormData>());
      final form = body as FormData;
      final fields = Map.fromEntries(form.fields);
      expect(fields['deskripsi_masalah'], 'Kabel putus');
      expect(fields['kode_aset'], 'AST-9');
      expect(fields['prioritas'], 'SEDANG');
      expect(fields.containsKey('aset_id'), isFalse);
      expect(form.files.map((f) => f.key), ['foto']);
      expect(form.files.single.value.filename, 'a.jpg');
      expect(form.files.single.value.length, 3);
    });

    test('respons tanpa data Map memicu ApiException format tidak valid', () async {
      final (repo, _) = _buat(200, {'sukses': true, 'data': null});

      expect(
        repo.submitLaporCepat(deskripsiMasalah: 'Rusak', prioritas: 'RENDAH'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Format respons lapor cepat tidak valid')),
      );
    });

    test('error 422 membawa pesan server dan detail validasi', () async {
      final (repo, _) = _buat(422, {
        'sukses': false,
        'pesan': 'Validasi gagal',
        'errors': {
          'deskripsi_masalah': ['Deskripsi terlalu pendek'],
        },
      });

      expect(
        repo.submitLaporCepat(deskripsiMasalah: 'x', prioritas: 'RENDAH'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Validasi gagal: Deskripsi terlalu pendek')
            .having((e) => e.statusCode, 'statusCode', 422)),
      );
    });
  });
  group('MaintenanceRepository.getSpkList', () {
    test('berhasil memparsing PagedResponse berisi spk dan metadata paginasi', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': {
          'spk': [
            {
              'id': 101,
              'kode_spk': 'SPK-2026-001',
              'status': 'DITUGASKAN',
              'prioritas': 'CITO',
              'deskripsi': 'Perbaikan ventilator',
            },
          ],
          'paginasi': {
            'total': 45,
            'per_halaman': 15,
            'halaman_ini': 1,
            'total_halaman': 3,
          },
        },
      });

      final hasil = await repo.getSpkList(status: 'DITUGASKAN', page: 1);

      expect(hasil.items.length, 1);
      expect(hasil.items.first.id, 101);
      expect(hasil.items.first.kodeSpk, 'SPK-2026-001');
      expect(hasil.meta.total, 45);
      expect(hasil.meta.halamanIni, 1);
      expect(hasil.meta.totalHalaman, 3);
      expect(hasil.meta.hasMore, isTrue);
      expect(adapter.last!.queryParameters, {'status': 'DITUGASKAN', 'page': 1});
    });

    test('error dio dilempar sebagai ApiException', () async {
      final (repo, _) = _buat(500, {'sukses': false, 'pesan': 'Server Error'});

      expect(
        repo.getSpkList(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
