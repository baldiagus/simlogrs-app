import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/distribusi/data/repositories/distribusi_repository.dart';

class _FakeStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'mock_token';
}

void main() {
  group('DistribusiRepository approval & tutup-sisa endpoints', () {
    test('approveAmprah sends items for Meja 2 and omits items when null/empty', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      RequestOptions? capturedApprovalOptions;

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedApprovalOptions = options;
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'sukses': true, 'pesan': 'Disetujui'},
          ));
        },
      ));

      final client = DioClient(storageService: _FakeStorage(), customDio: dio);
      final repo = DistribusiRepository(client);

      // 1. With items
      await repo.approveAmprah(
        id: 12,
        isSetujui: true,
        catatan: 'Acc gudang',
        items: [
          {'id': 101, 'jumlah_disetujui': 5},
        ],
      );

      expect(capturedApprovalOptions?.path, '/approval/amprah/12');
      expect(capturedApprovalOptions?.data['aksi'], 'setujui');
      expect(capturedApprovalOptions?.data['catatan'], 'Acc gudang');
      expect(capturedApprovalOptions?.data['items'], [
        {'id': 101, 'jumlah_disetujui': 5},
      ]);

      // 2. Without items (Meja 1 or tolak)
      await repo.approveAmprah(
        id: 13,
        isSetujui: false,
        catatan: 'Stok tidak mencukupi',
      );

      expect(capturedApprovalOptions?.path, '/approval/amprah/13');
      expect(capturedApprovalOptions?.data['aksi'], 'tolak');
      expect(capturedApprovalOptions?.data['catatan'], 'Stok tidak mencukupi');
      expect(capturedApprovalOptions?.data.containsKey('items'), isFalse);
    });

    test('tutupSisaAmprah calls /distribusi/amprah/{id}/tutup-sisa with POST and no body', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      RequestOptions? capturedTutupSisaOptions;

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedTutupSisaOptions = options;
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'sukses': true, 'pesan': 'Sisa barang terhutang telah ditutup.'},
          ));
        },
      ));

      final client = DioClient(storageService: _FakeStorage(), customDio: dio);
      final repo = DistribusiRepository(client);

      await repo.tutupSisaAmprah(77);

      expect(capturedTutupSisaOptions?.path, '/distribusi/amprah/77/tutup-sisa');
      expect(capturedTutupSisaOptions?.method, 'POST');
      expect(capturedTutupSisaOptions?.data, isNull);
    });
  });
}
