import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/notifications/fcm_token_repository.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';

/// Layanan secure storage tiruan untuk pengujian tanpa dependensi platform nyata.
class FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  /// Mengembalikan token otentikasi tiruan untuk header HTTP.
  Future<String?> getToken() async => 'mock_bearer_token';

  @override
  /// Menyimulasikan penghapusan token otentikasi tanpa efek samping.
  Future<void> deleteToken() async {}
}

/// Adapter HTTP tiruan untuk merekam request Dio dan mengembalikan respons yang ditentukan.
class FakeHttpClientAdapter implements HttpClientAdapter {
  /// Daftar riwayat request yang diterima oleh adapter tiruan.
  final List<RequestOptions> recordedRequests = [];

  /// Kode status HTTP yang akan dikembalikan pada respons.
  int statusCode;

  /// Payload JSON respons yang akan dikembalikan kepada pemanggil.
  Map<String, dynamic> responseBody;

  /// Jenis DioException yang sengaja dilempar jika disetel.
  DioExceptionType? throwType;

  /// Membuat instans [FakeHttpClientAdapter] dengan status, body, atau jenis error tertentu.
  FakeHttpClientAdapter({
    this.statusCode = 200,
    this.responseBody = const {'message': 'OK'},
    this.throwType,
  });

  @override
  /// Menangani eksekusi request HTTP tiruan dan mengembalikan [ResponseBody] atau error.
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recordedRequests.add(options);

    if (throwType != null) {
      throw DioException(
        requestOptions: options,
        type: throwType!,
      );
    }

    return ResponseBody.fromString(
      jsonEncode(responseBody),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  /// Menutup adapter tiruan tanpa melepas sumber daya eksternal.
  void close({bool force = false}) {}
}

/// Membuat instans [FcmTokenRepository] yang terhubung ke adapter HTTP tiruan [adapter].
FcmTokenRepository _createRepository(FakeHttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = DioClient(
    storageService: FakeSecureStorageService(),
    customDio: dio,
  );
  return FcmTokenRepository(client);
}

/// Kumpulan pengujian unit untuk fungsionalitas [FcmTokenRepository].
void main() {
  group('FcmTokenRepository syncToken', () {
    test('mengirim POST ke /auth/fcm-token dengan body token dan device_type android', () async {
      final adapter = FakeHttpClientAdapter(
        statusCode: 200,
        responseBody: {'status': 'success', 'message': 'Token tersimpan'},
      );
      final repository = _createRepository(adapter);

      await repository.syncToken('fcm_token_dummy_xyz123');

      expect(adapter.recordedRequests.length, 1);
      final request = adapter.recordedRequests.first;
      expect(request.method, 'POST');
      expect(request.path, contains('/auth/fcm-token'));
      expect(request.data, {
        'token': 'fcm_token_dummy_xyz123',
        'device_type': 'android',
      });
    });

    test('tetap sukses tanpa melempar uncaught exception saat server membalas 404 Not Found', () async {
      final adapter = FakeHttpClientAdapter(
        statusCode: 404,
        responseBody: {'message': 'Endpoint fcm-token belum diimplementasikan di server'},
      );
      final repository = _createRepository(adapter);

      expect(
        () async => await repository.syncToken('fcm_token_dummy_xyz123'),
        returnsNormally,
      );
    });

    test('tetap aman tanpa melempar fatal exception saat terjadi gangguan koneksi jaringan', () async {
      final adapter = FakeHttpClientAdapter(
        throwType: DioExceptionType.connectionError,
      );
      final repository = _createRepository(adapter);

      expect(
        () async => await repository.syncToken('fcm_token_dummy_xyz123'),
        returnsNormally,
      );
    });
  });

  group('FcmTokenRepository deleteToken', () {
    test('mengirim DELETE ke /auth/fcm-token', () async {
      final adapter = FakeHttpClientAdapter(
        statusCode: 200,
        responseBody: {'status': 'success', 'message': 'Token dihapus'},
      );
      final repository = _createRepository(adapter);

      await repository.deleteToken();

      expect(adapter.recordedRequests.length, 1);
      final request = adapter.recordedRequests.first;
      expect(request.method, 'DELETE');
      expect(request.path, contains('/auth/fcm-token'));
    });

    test('tetap aman tanpa melempar exception saat server merespons 404 atau 500 saat deleteToken', () async {
      final adapter = FakeHttpClientAdapter(
        statusCode: 404,
        responseBody: {'message': 'Token tidak ditemukan'},
      );
      final repository = _createRepository(adapter);

      expect(
        () async => await repository.deleteToken(),
        returnsNormally,
      );
    });
  });
}
