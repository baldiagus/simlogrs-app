import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/gudang/data/repositories/persediaan_repository.dart';

/// Storage palsu: hanya menyediakan token agar interceptor auth tidak menyentuh platform channel.
class _FakeSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'mock_token';
}

/// Membuat [PersediaanRepository] di atas Dio palsu; [responder] menentukan respons per request.
/// Respons berstatus >= 400 ditolak sebagai DioException agar melewati pemetaan error [DioClient].
PersediaanRepository _buildRepo(
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
  return PersediaanRepository(DioClient(storageService: _FakeSecureStorage(), customDio: dio));
}

Response<dynamic> _json(RequestOptions options, int status, Map<String, dynamic> body) =>
    Response(requestOptions: options, statusCode: status, data: body);

void main() {
  group('PersediaanRepository.getDaftarOpname', () {
    test('mem-parse sesi opname beserta detail bersarang dan filter status', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {
          'sukses': true,
          'pesan': 'OK',
          'data': [
            {
              'id': 5,
              'kode': 'OPN-202610-005',
              'gudang_id': 2,
              'gudang_nama': 'Gudang Farmasi',
              'tanggal_opname': '2026-10-10',
              'status': 'PROSES_COUNT',
              'total_item': 2,
              'total_terhitung': '1',
              'total_selisih': -3,
              'details': [
                {
                  'id': 50,
                  'stok_batch_id': 500,
                  'barang_id': 8,
                  'nama_barang': 'Paracetamol',
                  'jumlah_sistem': 40,
                  'jumlah_fisik': 37,
                  'selisih': -3,
                },
                {
                  'id': 51,
                  'stok_batch_id': '501',
                  'barang_id': '9',
                  'jumlah_sistem': 10,
                },
              ],
            },
          ],
        }),
        calls: calls,
      );

      final hasil = await repo.getDaftarOpname(status: 'PROSES_COUNT');

      expect(calls.single.path, '/gudang/opname/sesi');
      expect(calls.single.queryParameters, {'status': 'PROSES_COUNT'});
      final sesi = hasil.single;
      expect(sesi.kode, 'OPN-202610-005');
      expect(sesi.isBerjalan, isTrue);
      expect(sesi.totalTerhitung, 1);
      expect(sesi.totalSelisih, -3);
      expect(sesi.details, hasLength(2));
      expect(sesi.details[0].isSudahHitung, isTrue);
      expect(sesi.details[0].jumlahFisik, 37);
      // Blind count: item belum dihitung tidak punya jumlah fisik.
      expect(sesi.details[1].isSudahHitung, isFalse);
      expect(sesi.details[1].stokBatchId, 501);
    });

    test('error server dipetakan ke ApiException dengan pesan dari server', () async {
      final repo = _buildRepo((o) => _json(o, 403, {'sukses': false, 'pesan': 'Hanya staf gudang yang boleh melihat opname.'}));

      await expectLater(
        repo.getDaftarOpname(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Hanya staf gudang yang boleh melihat opname.')
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });

  group('PersediaanRepository.simpanHitungFisik', () {
    test('POST ke /gudang/opname/<id>/count dengan items dan finalisasi', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo(
        (o) => _json(o, 200, {'sukses': true, 'pesan': 'Hitung fisik tersimpan'}),
        calls: calls,
      );
      final items = [
        {'detail_id': 50, 'jumlah_fisik': 37, 'catatan': 'rusak 3'},
        {'detail_id': 51, 'jumlah_fisik': 10, 'catatan': ''},
      ];

      await repo.simpanHitungFisik(opnameId: 5, items: items, finalisasi: true);

      expect(calls.single.method, 'POST');
      expect(calls.single.path, '/gudang/opname/5/count');
      final body = calls.single.data as Map<String, dynamic>;
      expect(body['items'], items);
      expect(body['finalisasi'], isTrue);
    });

    test('finalisasi default false (simpan draft)', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo((o) => _json(o, 200, {'sukses': true, 'pesan': 'OK'}), calls: calls);

      await repo.simpanHitungFisik(opnameId: 6, items: const []);

      final body = calls.single.data as Map<String, dynamic>;
      expect(body['finalisasi'], isFalse);
      expect(body['items'], isEmpty);
    });

    test('sesi sudah final: ApiException membawa pesan dan detail validasi server', () async {
      final repo = _buildRepo(
        (o) => _json(o, 422, {
          'sukses': false,
          'pesan': 'Sesi opname tidak dapat diubah',
          'errors': {
            'status': ['Sesi sudah menunggu approval']
          },
        }),
      );

      await expectLater(
        repo.simpanHitungFisik(opnameId: 5, items: const [], finalisasi: true),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Sesi opname tidak dapat diubah: Sesi sudah menunggu approval')
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.isNetworkError, 'isNetworkError', isFalse)),
      );
    });
  });

  group('PersediaanRepository.inisiasiOpname', () {
    test('catatan hanya dikirim bila diisi', () async {
      final calls = <RequestOptions>[];
      final repo = _buildRepo((o) => _json(o, 201, {'sukses': true, 'pesan': 'OK'}), calls: calls);

      await repo.inisiasiOpname(gudangId: 2, tanggalOpname: '2026-10-13');
      await repo.inisiasiOpname(gudangId: 2, tanggalOpname: '2026-10-13', catatan: 'Opname akhir bulan');

      expect(calls[0].path, '/gudang/opname/inisiasi');
      expect(calls[0].data, {'gudang_id': 2, 'tanggal_opname': '2026-10-13'});
      expect(calls[1].data, {
        'gudang_id': 2,
        'tanggal_opname': '2026-10-13',
        'catatan': 'Opname akhir bulan',
      });
    });
  });
}
