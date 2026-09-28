import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../storage/secure_storage_service.dart';
import 'api_response.dart';
class DioClient {
  final Dio dio;
  final SecureStorageService storageService;
  void Function()? onUnauthorized;

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
    final dotenvUrl = dotenv.isInitialized ? dotenv.maybeGet('API_BASE_URL') : null;
    final baseUrl = envUrl.isNotEmpty
        ? envUrl
        : (dotenvUrl != null && dotenvUrl.isNotEmpty ? dotenvUrl : defaultLoopback);
    final connectTimeout = int.tryParse(
          (dotenv.isInitialized ? dotenv.maybeGet('CONNECT_TIMEOUT') : null) ?? '15000',
        ) ??
        15000;
    final receiveTimeout = int.tryParse(
          (dotenv.isInitialized ? dotenv.maybeGet('RECEIVE_TIMEOUT') : null) ?? '15000',
        ) ??
        15000;

    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(milliseconds: connectTimeout),
      receiveTimeout: Duration(milliseconds: receiveTimeout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    storageService.getServerUrl().then((savedUrl) {
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        dio.options.baseUrl = savedUrl.trim();
      }
    });
    // SSL Certificate Pinning opsional untuk lingkungan produksi via --dart-define=SSL_FINGERPRINT=...
    const sslFingerprint = String.fromEnvironment('SSL_FINGERPRINT', defaultValue: '');
    if (!kIsWeb && sslFingerprint.isNotEmpty) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
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
        onError: (DioException error, handler) async {
          final path = error.requestOptions.path;
          final isAuthPath = path.contains('/auth/login') || path.contains('/auth/logout');

          if (error.response?.statusCode == 401 && !isAuthPath) {
            await storageService.deleteToken();
            onUnauthorized?.call();
          }

          final responseData = error.response?.data;
          String errorMessage = 'Terjadi kesalahan pada jaringan';
          Map<String, dynamic>? errors;

          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['pesan']?.toString() ??
                responseData['message']?.toString() ??
                errorMessage;
            if (responseData['errors'] is Map<String, dynamic>) {
              errors = responseData['errors'] as Map<String, dynamic>;
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
              ),
            ),
          );
        },
      ),
    );
  }

  void setBaseUrl(String url) {
    dio.options.baseUrl = url.trim();
  }
}
