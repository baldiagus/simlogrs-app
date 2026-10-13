import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/aset/data/repositories/aset_repository.dart';

/// Storage palsu: hanya menyediakan token agar interceptor auth tidak menyentuh platform channel.
class _FakeSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'mock_token';
}

/// Membuat [AsetRepository] di atas Dio palsu; [responder] menentukan respons per request.
/// Respons berstatus >= 400 ditolak sebagai DioException agar melewati pemetaan error [DioClient].
AsetRepository _buildRepo(
  Response<dynamic> Function(RequestOptions options) responder, {
  List<RequestOptions>? calls,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      calls?.add(options);
      final response = responder(options);
      if ((response.statusCode ?? 200) >= 400) {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: response,
            type: DioExceptionType.badResponse,
          ),
          true,
        );
      }
      return handler.resolve(response);
    },
  ));
  return AsetRepository(DioClient(storageService: _FakeSecureStorage(), customDio: dio));
}

Response<dynamic> _json(RequestOptions options, int status, Map<String, dynamic> body) =>
    Response(requestOptions: options, statusCode: status, data: body);

Map<String, dynamic> _asetJson() => {
      'id': 7,
      'kode_aset': 'AST-0007',
      'nomor_seri': 'SN-123',
      'nama_komoditas': 'Infus Pump',
      'kategori': 'Alkes',
      'merek': 'B.Braun',
      'spesifikasi': 'Volumetrik',
      'status': 'DIPINJAM',
      'kondisi': 'RUSAK_RINGAN',
      'lokasi_tercatat': 'IGD',
      'penanggung_jawab': 'Ns. Sari',
      'nilai_perolehan': '15000000',
      'tanggal_perolehan': '2024-03-01',
      'total_riwayat_servis': 2,
      'peminjaman_aktif': {
        'peminjaman_id': 9,
        'kode_pinjam': 'PJM-009',
        'unit_peminjam': 'ICU',
        'is_overdue': true,
      },
      'unit_id': 3,
    };

void main() {
  group('AsetRepository.scanQr', () {
    test('mengirim kode ter-trim dan mem-parse detail aset', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {'sukses': true, 'pesan': 'OK', 'data': _asetJson()}),
        calls: calls,
      );

      final aset = await repo.scanQr('  AST-0007 ');

      expect(calls.single.path, '/aset/scan-qr');
      expect(calls.single.method, 'POST');
      expect((calls.single.data as Map<String, dynamic>)['kode_aset'], 'AST-0007');
      expect(aset.id, 7);
      expect(aset.kodeAset, 'AST-0007');
      expect(aset.nilaiPerolehan, 15000000);
      expect(aset.isDipinjam, isTrue);
      expect(aset.isRusak, isTrue);
      expect(aset.peminjamanAktif?.kodePinjam, 'PJM-009');
      expect(aset.peminjamanAktif?.isOverdue, isTrue);
      expect(aset.unitId, 3);
    });

    test('melempar ApiException berisi pesan server saat aset tidak ditemukan', () async {
      final repo = _buildRepo(
        (o) => _json(o, 404, {'sukses': false, 'pesan': 'Aset dengan kode tersebut tidak ditemukan.'}),
      );

      await expectLater(
        repo.scanQr('XXX'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Aset dengan kode tersebut tidak ditemukan.')
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.isNetworkError, 'isNetworkError', isFalse)),
      );
    });

    test('melempar ApiException format tidak valid bila data bukan objek', () async {
      final repo = _buildRepo((o) => _json(o, 200, {'sukses': true, 'pesan': 'OK', 'data': null}));

      await expectLater(
        repo.scanQr('AST-1'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Format data aset tidak valid')),
      );
    });
  });

  group('AsetRepository.getDetailAset', () {
    test('memanggil /aset/detail/<id> dan mem-parse model', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {'sukses': true, 'pesan': 'OK', 'data': _asetJson()}),
        calls: calls,
      );

      final aset = await repo.getDetailAset(7);

      expect(calls.single.path, '/aset/detail/7');
      expect(calls.single.method, 'GET');
      expect(aset.namaKomoditas, 'Infus Pump');
      expect(aset.servisTerakhir, isNull);
      expect(aset.riwayatPeminjaman, isEmpty);
    });

    test('error 403 dipetakan ke ApiException dengan pesan server', () async {
      final repo = _buildRepo((o) => _json(o, 403, {'sukses': false, 'pesan': 'Anda tidak berhak mengakses aset ini.'}));

      await expectLater(
        repo.getDetailAset(7),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Anda tidak berhak mengakses aset ini.')
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });

  group('AsetRepository.getKatalogTersedia', () {
    test('mem-parse daftar katalog dan hanya mengirim filter yang diisi', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {
          'sukses': true,
          'pesan': 'OK',
          'data': [
            {
              'id': 11,
              'kode_aset': 'AST-0011',
              'nama_komoditas': 'Ventilator',
              'tipe_penyedia': 'RUANGAN',
              'penyedia_id': 4,
              'nama_penyedia': 'ICU',
            },
            {'id': '12', 'kode_aset': 'AST-0012'},
          ],
        }),
        calls: calls,
      );

      final hasil = await repo.getKatalogTersedia(cari: '  vent ', tujuan: 'PINJAM');

      expect(calls.single.path, '/aset/katalog-tersedia');
      expect(calls.single.queryParameters, {'cari': 'vent', 'tujuan': 'PINJAM'});
      expect(hasil, hasLength(2));
      expect(hasil[0].namaPenyedia, 'ICU');
      expect(hasil[0].penyediaId, 4);
      expect(hasil[0].isGudang, isFalse);
      // Field kosong memakai default model; id string tetap ter-parse.
      expect(hasil[1].id, 12);
      expect(hasil[1].tipePenyedia, 'GUDANG');
      expect(hasil[1].isGudang, isTrue);
    });

    test('pencarian kosong tidak dikirim sebagai query dan data non-list menghasilkan list kosong', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {'sukses': true, 'pesan': 'OK', 'data': null}),
        calls: calls,
      );

      final hasil = await repo.getKatalogTersedia(cari: '   ');

      expect(calls.single.queryParameters, isEmpty);
      expect(hasil, isEmpty);
    });

    test('error server dipetakan ke ApiException dengan pesan dan detail validasi', () async {
      final repo = _buildRepo(
        (o) => _json(o, 422, {
          'sukses': false,
          'pesan': 'Parameter tidak valid',
          'errors': {
            'tujuan': ['Tujuan harus PINJAM atau ALIH']
          },
        }),
      );

      await expectLater(
        repo.getKatalogTersedia(tujuan: 'X'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Parameter tidak valid: Tujuan harus PINJAM atau ALIH')
            .having((e) => e.errors?['tujuan'], 'errors.tujuan', isNotNull)),
      );
    });
  });
}
