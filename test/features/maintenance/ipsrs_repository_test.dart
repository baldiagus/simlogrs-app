import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/maintenance/data/repositories/ipsrs_repository.dart';

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
(IpsrsRepository, _FakeAdapter) _buat(int status, Object? body) {
  final adapter = _FakeAdapter(status, body);
  final dio = Dio()..httpClientAdapter = adapter;
  final client = DioClient(storageService: _FakeStorage(), customDio: dio);
  return (IpsrsRepository(client), adapter);
}

void main() {
  group('IpsrsRepository.getJadwalPreventif', () {
    test('parse jadwal dan hanya kirim filter yang terisi', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': [
          {
            'id': 2,
            'kode': 'JPV-002',
            'aset_id': '8',
            'kode_aset': 'AST-8',
            'nama_sarana': 'Ventilator',
            'interval_nilai': 3,
            'interval_tipe': 'BULAN',
            'tanggal_berikutnya': '2026-11-01',
            'sisa_hari': 19,
            'status_jadwal': 'OVERDUE',
            'teknisi_id': 4,
          },
        ],
      });

      final hasil = await repo.getJadwalPreventif(status: '', teknisiId: 4, cari: ' vent ');

      expect(hasil.single.id, 2);
      expect(hasil.single.asetId, 8);
      expect(hasil.single.namaSarana, 'Ventilator');
      expect(hasil.single.intervalNilai, 3);
      expect(hasil.single.sisaHari, 19);
      expect(hasil.single.isOverdue, isTrue);
      expect(hasil.single.teknisiId, 4);
      expect(hasil.single.teknisiNama, 'Teknisi IPSRS');
      expect(adapter.last!.path, '/maintenance/preventif/jadwal');
      expect(adapter.last!.queryParameters, {'teknisi_id': 4, 'cari': 'vent'});
    });

    test('error 500 menjadi ApiException dengan pesan dari server', () async {
      final (repo, _) = _buat(500, {'sukses': false, 'pesan': 'Server bermasalah'});

      expect(
        repo.getJadwalPreventif(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Server bermasalah')
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('IpsrsRepository.simpanJadwalPreventif', () {
    test('mengirim payload lengkap dan menghilangkan field opsional kosong', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': {'id': 30},
      });

      final hasil = await repo.simpanJadwalPreventif(
        asetId: 8,
        jenisMaintenance: 'Kalibrasi',
        intervalNilai: 6,
        intervalTipe: 'BULAN',
        tanggalBerikutnya: '2026-12-01',
        catatan: '',
      );

      expect(hasil['id'], 30);
      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.data, {
        'aset_id': 8,
        'jenis_maintenance': 'Kalibrasi',
        'interval_nilai': 6,
        'interval_tipe': 'BULAN',
        'tanggal_berikutnya': '2026-12-01',
      });
    });

    test('error 422 membawa pesan dan detail validasi', () async {
      final (repo, _) = _buat(422, {
        'sukses': false,
        'pesan': 'Validasi gagal',
        'errors': {
          'tanggal_berikutnya': ['Tanggal tidak boleh lampau'],
        },
      });

      expect(
        repo.simpanJadwalPreventif(
          asetId: 8,
          jenisMaintenance: 'Kalibrasi',
          intervalNilai: 6,
          intervalTipe: 'BULAN',
          tanggalBerikutnya: '2020-01-01',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Validasi gagal: Tanggal tidak boleh lampau')),
      );
    });
  });

  group('IpsrsRepository.eksekusiPreventif', () {
    test('mengembalikan data Map, atau Map kosong bila data tidak ada', () async {
      final (repoAda, adapter) = _buat(200, {
        'sukses': true,
        'data': {'kode_spk': 'SPK-77'},
      });
      expect((await repoAda.eksekusiPreventif(2))['kode_spk'], 'SPK-77');
      expect(adapter.last!.path, '/maintenance/preventif/2/eksekusi');

      final (repoKosong, _) = _buat(200, {'sukses': true});
      expect(await repoKosong.eksekusiPreventif(2), isEmpty);
    });
  });

  group('IpsrsRepository.getRekamMedisAset', () {
    test('parse identitas, riwayat servis, suku cadang, dan jadwal preventif', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': {
          'identitas': {'kode_aset': 'AST-8'},
          'riwayat_servis': [
            {
              'id': 1,
              'kode_tiket': 'TKT-1',
              'diagnosa': 'Sensor rusak',
              'suku_cadang': [
                {'nama_barang': 'Sensor O2', 'nomor_batch': 'B-1', 'jumlah': '2'},
              ],
            },
          ],
          'jadwal_preventif': [
            {'id': 2},
          ],
        },
      });

      final hasil = await repo.getRekamMedisAset(8);

      expect(adapter.last!.path, '/maintenance/rekam-medis/8');
      expect(hasil.identitas['kode_aset'], 'AST-8');
      expect(hasil.riwayatServis.single.kodeTiket, 'TKT-1');
      expect(hasil.riwayatServis.single.sukuCadang.single.jumlah, 2);
      expect(hasil.riwayatServis.single.teknisi, '-');
      expect(hasil.jadwalPreventif, hasLength(1));
    });

    test('respons tanpa data Map memicu ApiException format tidak valid', () async {
      final (repo, _) = _buat(200, {'sukses': true, 'data': []});

      expect(
        repo.getRekamMedisAset(8),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Format data rekam medis tidak valid')),
      );
    });
  });

  group('IpsrsRepository.getKatalogRekamMedis', () {
    test('parse katalog aset dan kirim filter kondisi', () async {
      final (repo, adapter) = _buat(200, {
        'sukses': true,
        'data': [
          {'id': 8, 'kode_aset': 'AST-8', 'nama_sarana': 'Ventilator', 'total_servis': '3'},
        ],
      });

      final hasil = await repo.getKatalogRekamMedis(kondisi: 'RUSAK');

      expect(hasil.single.namaSarana, 'Ventilator');
      expect(hasil.single.totalServis, 3);
      expect(hasil.single.kondisi, 'BAIK');
      expect(adapter.last!.queryParameters, {'kondisi': 'RUSAK'});
    });
  });
}
