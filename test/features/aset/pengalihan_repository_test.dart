import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/aset/data/repositories/pengalihan_repository.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'mock_token';
}

void main() {
  group('PengalihanRepository Tests', () {
    test('getDaftarPengalihan fetches list from API', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/aset/pengalihan' && options.queryParameters['tab'] == 'aktif') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'sukses': true,
                'pesan': 'OK',
                'data': [
                  {
                    'id': 101,
                    'kode': 'TRF-202610-001',
                    'tipe': 'ASET',
                    'tipe_asal': 'RUANGAN',
                    'asal_nama': 'IGD',
                    'tipe_tujuan': 'RUANGAN',
                    'tujuan_nama': 'ICU',
                    'status': 'DIAJUKAN',
                    'tanggal_pengalihan': '2026-10-07',
                    'nama_item': 'Infus Pump B.Braun',
                    'jumlah': 1,
                    'can_cancel': true,
                  }
                ],
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final client = DioClient(storageService: FakeSecureStorage(), customDio: dio);
      final repo = PengalihanRepository(client);

      final list = await repo.getDaftarPengalihan(tab: 'aktif');

      expect(list.length, 1);
      expect(list.first.kode, 'TRF-202610-001');
      expect(list.first.canCancel, isTrue);
    });

    test('submitPengalihan sends post request and returns response data', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/aset/pengalihan' && options.method == 'POST') {
            final data = options.data as Map<String, dynamic>;
            expect(data['unit_tujuan_id'], 4);
            expect(data['alasan'], 'Kebutuhan ICU');
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'sukses': true,
                'pesan': 'Berhasil',
                'data': {'id': 102, 'kode': 'TRF-202610-002', 'status': 'DIAJUKAN'},
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final client = DioClient(storageService: FakeSecureStorage(), customDio: dio);
      final repo = PengalihanRepository(client);

      final res = await repo.submitPengalihan({
        'tipe_tujuan': 'RUANGAN',
        'unit_tujuan_id': 4,
        'aset_ids': [10],
        'tanggal_pengalihan': '2026-10-07',
        'alasan': 'Kebutuhan ICU',
      });

      expect(res['kode'], 'TRF-202610-002');
    });
  });
}
