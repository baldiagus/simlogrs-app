import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/gudang/data/repositories/gudang_repository.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'fake_token';
}

void main() {
  test('GudangRepository.tolakPenerimaanPo sends rejection request with alasan', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/gudang/penerimaan-po/tolak' && options.method == 'POST') {
          final data = options.data as Map<String, dynamic>;
          expect(data['pesanan_pembelian_id'], 15);
          expect(data['nomor_surat_jalan'], 'SJ-VENDOR-999');
          expect(data['alasan_penolakan'], 'Kemasan rusak basah dan segel terbuka');
          
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'sukses': true,
              'pesan': 'Kiriman fisik berhasil ditolak.',
              'data': {
                'nomor_dokumen': 'RCV-REJ-202610-001',
                'status': 'DITOLAK',
              },
            },
          ));
        }
        return handler.next(options);
      },
    ));

    final client = DioClient(storageService: FakeSecureStorage(), customDio: dio);
    final repo = GudangRepository(client);

    final res = await repo.tolakPenerimaanPo(
      poId: 15,
      nomorSuratJalan: 'SJ-VENDOR-999',
      alasanPenolakan: 'Kemasan rusak basah dan segel terbuka',
      items: [
        {'barang_id': 1, 'jumlah_rusak': 5},
      ],
    );

    expect(res['status'], 'DITOLAK');
    expect(res['nomor_dokumen'], 'RCV-REJ-202610-001');
  });
}
