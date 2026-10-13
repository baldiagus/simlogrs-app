import 'package:dio/dio.dart';
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
    const defaultLoopback = 'http://127.0.0.1:8000/api/v1';

    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const baseUrl = envUrl != '' ? envUrl : defaultLoopback;
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
          String errorMessage = 'Terjadi kesalahan pada jaringan';
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
              ),
            ),
          );
        },
      ),
    );
  }

}
