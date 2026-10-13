import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';
import 'api_response.dart';

/// Klien HTTP berbasis Dio dengan base URL, token Bearer, dan pemetaan error API.
class DioClient {
  final Dio dio;
  final SecureStorageService storageService;
  void Function()? onUnauthorized;

  /// Membuat klien Dio; konfigurasi hanya lewat --dart-define (API_BASE_URL, CONNECT_TIMEOUT, RECEIVE_TIMEOUT).
  DioClient({
    required this.storageService,
    this.onUnauthorized,
    Dio? customDio,
  }) : dio = customDio ?? Dio() {
    final defaultLoopback = kIsWeb
        ? 'http://127.0.0.1:8000/api/v1'
        : (defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8000/api/v1'
            : 'http://127.0.0.1:8000/api/v1');

    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final baseUrl = envUrl.isNotEmpty ? envUrl : defaultLoopback;
    const connectTimeout = int.fromEnvironment('CONNECT_TIMEOUT', defaultValue: 15000);
    const receiveTimeout = int.fromEnvironment('RECEIVE_TIMEOUT', defaultValue: 15000);

    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: connectTimeout),
      receiveTimeout: const Duration(milliseconds: receiveTimeout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // SSL Certificate Pinning opsional untuk lingkungan produksi via --dart-define=SSL_FINGERPRINT=...
    const sslFingerprint = String.fromEnvironment('SSL_FINGERPRINT', defaultValue: '');
    if (!kIsWeb && sslFingerprint.isNotEmpty) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        /// Membuat HttpClient yang hanya menerima sertifikat dengan fingerprint SHA-256 sesuai SSL_FINGERPRINT.
        createHttpClient: () {
          final client = HttpClient();
          /// Callback sertifikat tak tepercaya: terima hanya bila sidik jari SHA-256 cocok dengan yang diharapkan.
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            final digest = sha256.convert(cert.der).toString().toUpperCase();
            final expected = sslFingerprint.toUpperCase().replaceAll(':', '').replaceAll(' ', '');
            return digest == expected;
          };
          return client;
        },
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        /// Menyisipkan header Bearer token ke setiap request selain login.
        onRequest: (options, handler) async {
          final isLoginPath = options.path.contains('/auth/login');
          if (!isLoginPath) {
            final token = await storageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        /// Menangani error respons: hapus token saat 401, lalu bungkus pesan error backend jadi ApiException.
        onError: (DioException error, handler) async {
          final path = error.requestOptions.path;
          final isAuthPath = path.contains('/auth/login') || path.contains('/auth/logout');

          if (error.response?.statusCode == 401 && !isAuthPath) {
            await storageService.deleteToken();
            onUnauthorized?.call();
          }

          final responseData = error.response?.data;
          String errorMessage = error.response == null
              ? _pesanTanpaRespons(error.type)
              : 'Terjadi kesalahan pada jaringan';
          Map<String, dynamic>? errors;

          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['pesan']?.toString() ??
                responseData['message']?.toString() ??
                errorMessage;
            if (responseData['errors'] is Map<String, dynamic>) {
              errors = responseData['errors'] as Map<String, dynamic>;
              final details = errors.values
                  .expand((e) => e is List ? e : [e])
                  .map((e) => e.toString())
                  .join('; ');
              if (details.isNotEmpty) {
                errorMessage = '$errorMessage: $details';
              }
            }
          }

          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException(
                message: errorMessage,
                statusCode: error.response?.statusCode,
                errors: errors,
                isNetworkError: error.response == null && _isGangguanJaringan(error.type),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Memilih pesan error berbahasa Indonesia sesuai jenis kegagalan saat server tidak memberi respons.
  static String _pesanTanpaRespons(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server terlalu lambat. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Server tidak dapat dihubungi. Periksa koneksi internet dan alamat server.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak dikenali.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      default:
        return 'Terjadi kesalahan pada jaringan';
    }
  }

  /// True bila jenis error berasal dari gangguan jaringan (timeout, koneksi gagal, atau tak dikenal).
  static bool _isGangguanJaringan(DioExceptionType type) {
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.connectionError ||
        type == DioExceptionType.unknown;
  }
}
