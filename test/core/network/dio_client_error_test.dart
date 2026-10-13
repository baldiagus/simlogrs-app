import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';

class FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'mock_token';

  @override
  Future<void> deleteToken() async {}
}

/// Adapter palsu: melempar [DioException] bertipe tertentu atau membalas JSON dengan status tertentu.
class FakeAdapter implements HttpClientAdapter {
  final DioExceptionType? throwType;
  final int status;
  final Map<String, dynamic>? body;

  FakeAdapter.throwing(DioExceptionType this.throwType)
      : status = 0,
        body = null;

  FakeAdapter.json(this.status, Map<String, dynamic> this.body) : throwType = null;

  /// Menjalankan request palsu tanpa jaringan sesuai konfigurasi adapter.
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwType != null) {
      throw DioException(requestOptions: options, type: throwType!);
    }
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

/// Mengirim GET lewat [DioClient] dengan adapter palsu dan mengembalikan ApiException hasil interceptor.
Future<ApiException> _ambilError(FakeAdapter adapter) async {
  final dio = Dio()..httpClientAdapter = adapter;
  DioClient(storageService: FakeSecureStorageService(), customDio: dio);
  try {
    await dio.get('/apa-saja');
  } on DioException catch (e) {
    return e.error as ApiException;
  }
  fail('DioException tidak dilempar');
}

void main() {
  group('DioClient onError', () {
    test('connectionError -> pesan server tidak dapat dihubungi, isNetworkError true', () async {
      final e = await _ambilError(FakeAdapter.throwing(DioExceptionType.connectionError));
      expect(e.message, 'Server tidak dapat dihubungi. Periksa koneksi internet dan alamat server.');
      expect(e.isNetworkError, isTrue);
      expect(e.statusCode, isNull);
    });

    test('connectionTimeout -> pesan koneksi lambat, isNetworkError true', () async {
      final e = await _ambilError(FakeAdapter.throwing(DioExceptionType.connectionTimeout));
      expect(e.message, 'Koneksi ke server terlalu lambat. Coba lagi.');
      expect(e.isNetworkError, isTrue);
      expect(e.statusCode, isNull);
    });

    test('respons 422 -> pesan dari server, isNetworkError false', () async {
      final e = await _ambilError(FakeAdapter.json(422, {'pesan': 'x'}));
      expect(e.message, 'x');
      expect(e.isNetworkError, isFalse);
      expect(e.statusCode, 422);
    });
  });
}
