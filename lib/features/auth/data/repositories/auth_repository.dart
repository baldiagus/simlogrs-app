import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _client;
  final SecureStorageService _storage;

  /// Membuat repository dengan klien HTTP dan storage yang diperlukan.
  AuthRepository({
    required DioClient client,
    required SecureStorageService storage,
  })  : _client = client,
        _storage = storage;

  /// Login ke API, simpan token, lalu kembalikan data user (dari respons atau via `/auth/me`).
  Future<UserModel> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName ?? 'SIMLOG Mobile Client',
        },
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.sukses || apiResponse.data == null) {
        throw ApiException(message: apiResponse.pesan);
      }

      final data = apiResponse.data!;
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw ApiException(message: 'Token otentikasi tidak ditemukan dalam respons');
      }

      await _storage.saveToken(token);

      // Jika respons login langsung mengembalikan data user lengkap
      if (data['user'] is Map<String, dynamic>) {
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _storage.saveCachedUser(jsonEncode(user.toJson()));
        return user;
      }

      // Jika tidak, panggil endpoint /auth/me
      return await getMe();
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal melakukan login');
    }
  }

  /// Mengambil profil user saat ini dari `/auth/me` dan memperbarui cache lokal.
  Future<UserModel> getMe() async {
    try {
      final response = await _client.dio.get('/auth/me');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.sukses || apiResponse.data == null) {
        throw ApiException(message: apiResponse.pesan);
      }

      final user = UserModel.fromJson(apiResponse.data!);
      await _storage.saveCachedUser(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal mengambil profil pengguna');
    }
  }
  /// Mengganti password wajib (mis. setelah reset) dan menyimpan data user terbaru ke cache.
  Future<UserModel> gantiPasswordWajib({
    required String passwordSaatIni,
    required String passwordBaru,
    required String passwordBaruConfirmation,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/ganti-password',
        data: {
          'password_saat_ini': passwordSaatIni,
          'password_baru': passwordBaru,
          'password_baru_confirmation': passwordBaruConfirmation,
        },
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.sukses || apiResponse.data == null) {
        throw ApiException(message: apiResponse.pesan);
      }

      final data = apiResponse.data!;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.saveCachedUser(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memperbarui kata sandi');
    }
  }


  /// Logout ke server; error jaringan diabaikan agar data sesi lokal tetap terhapus.
  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (_) {
      // Abaikan error jaringan agar sesi lokal tetap terhapus
    } finally {
      await _storage.clearAll();
    }
  }

  /// Mengambil user dari cache lokal; null jika kosong atau JSON rusak.
  Future<UserModel?> getCachedUser() async {
    final cached = await _storage.getCachedUser();
    if (cached != null && cached.isNotEmpty) {
      try {
        return UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Mengecek apakah token tersimpan, sebagai penanda ada sesi yang bisa dilanjutkan.
  Future<bool> hasValidToken() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }
}
