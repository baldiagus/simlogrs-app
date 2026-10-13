import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/master/data/repositories/master_repository.dart';

/// Storage palsu: hanya menyediakan token agar interceptor auth tidak menyentuh platform channel.
class _FakeSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'mock_token';
}

/// Membuat [MasterRepository] di atas Dio palsu; [responder] menentukan respons per request.
/// Respons berstatus >= 400 ditolak sebagai DioException agar melewati pemetaan error [DioClient].
MasterRepository _buildRepo(
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
  return MasterRepository(DioClient(storageService: _FakeSecureStorage(), customDio: dio));
}

Response<dynamic> _json(RequestOptions options, int status, Map<String, dynamic> body) =>
    Response(requestOptions: options, statusCode: status, data: body);

void main() {
  group('MasterRepository.getBarangLengkap', () {
    test('mem-parse komoditas dan menghitung total stok fisik', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {
          'sukses': true,
          'pesan': 'OK',
          'data': [
            {
              'id': 1,
              'kode': 'BRG-001',
              'nama': 'Sarung Tangan Latex',
              'tipe': 'HABIS_PAKAI',
              'tipe_label': 'Habis Pakai',
              'kategori': 'APD',
              'harga_beli_terakhir': '1500.50',
              'titik_pesan': 100,
              'stok_gudang': 60,
              'stok_ruangan': '30',
            },
            {
              'id': '2',
              'kode': 'AST-001',
              'nama': 'Tensimeter',
              'tipe': 'ASET',
              'stok_gudang': 2,
              'stok_ruangan': 99,
              'total_aset': 5,
            },
          ],
        }),
        calls: calls,
      );

      final hasil = await repo.getBarangLengkap();

      expect(calls.single.path, '/master/barang-lengkap');
      expect(hasil, hasLength(2));
      expect(hasil[0].hargaBeliTerakhir, 1500.50);
      expect(hasil[0].stokRuangan, 30);
      // HABIS_PAKAI: gudang + ruangan = 90 <= titik pesan 100.
      expect(hasil[0].totalStokFisik, 90);
      expect(hasil[0].isPerluPesan, isTrue);
      // ASET: total_aset + gudang = 7, stok ruangan diabaikan.
      expect(hasil[1].id, 2);
      expect(hasil[1].totalStokFisik, 7);
      expect(hasil[1].isHabis, isFalse);
    });

    test('query tipe hanya terkirim bila diisi', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {'sukses': true, 'pesan': 'OK', 'data': []}),
        calls: calls,
      );

      await repo.getBarangLengkap();
      await repo.getBarangLengkap(tipe: '');
      await repo.getBarangLengkap(tipe: 'ASET', kategoriId: 3, cari: '  tensi ');

      expect(calls[0].queryParameters.containsKey('tipe'), isFalse);
      expect(calls[0].queryParameters, isEmpty);
      expect(calls[1].queryParameters.containsKey('tipe'), isFalse);
      expect(calls[2].queryParameters, {'tipe': 'ASET', 'kategori_id': 3, 'cari': 'tensi'});
    });

    test('error server dipetakan ke ApiException dengan pesan dari server', () async {
      final repo = _buildRepo((o) => _json(o, 500, {'sukses': false, 'pesan': 'Katalog sedang tidak tersedia.'}));

      await expectLater(
        repo.getBarangLengkap(tipe: 'ASET'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Katalog sedang tidak tersedia.')
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('MasterRepository.getAsetLengkap', () {
    test('mem-parse register aset dan getter status', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {
          'sukses': true,
          'pesan': 'OK',
          'data': [
            {
              'id': 21,
              'kode_aset': 'AST-0021',
              'nomor_seri': 'SN-21',
              'nama_komoditas': 'Syringe Pump',
              'lokasi_tipe': 'GUDANG',
              'lokasi_nama': 'Gudang Alkes',
              'kondisi': 'BAIK',
              'status': 'DALAM_MAINTENANCE',
              'tanggal_perolehan': '2025-01-15',
              'nilai_perolehan': 8250000,
            },
          ],
        }),
        calls: calls,
      );

      final hasil = await repo.getAsetLengkap(lokasiTipe: 'GUDANG');

      expect(calls.single.path, '/master/aset-lengkap');
      expect(calls.single.queryParameters, {'lokasi_tipe': 'GUDANG'});
      expect(hasil.single.kodeAset, 'AST-0021');
      expect(hasil.single.lokasiNama, 'Gudang Alkes');
      expect(hasil.single.nilaiPerolehan, 8250000);
      expect(hasil.single.isMaintenance, isTrue);
      expect(hasil.single.isTersedia, isFalse);
    });

    test('query lokasi_tipe tidak terkirim bila kosong, filter lain ter-trim', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {'sukses': true, 'pesan': 'OK', 'data': []}),
        calls: calls,
      );

      await repo.getAsetLengkap(lokasiTipe: '', status: 'TERSEDIA', cari: '  pump ');

      expect(calls.single.queryParameters, {'status': 'TERSEDIA', 'cari': 'pump'});
    });

    test('error 403 dipetakan ke ApiException dengan pesan server', () async {
      final repo = _buildRepo((o) => _json(o, 403, {'sukses': false, 'pesan': 'Akses register aset ditolak.'}));

      await expectLater(
        repo.getAsetLengkap(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Akses register aset ditolak.')
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });

  group('MasterRepository.getDetailBarang', () {
    test('respons tanpa objek data melempar ApiException format tidak valid', () async {
      final repo = _buildRepo((o) => _json(o, 200, {'sukses': true, 'pesan': 'OK', 'data': []}));

      await expectLater(
        repo.getDetailBarang(1),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Format detail komoditas tidak valid')),
      );
    });
  });
}
