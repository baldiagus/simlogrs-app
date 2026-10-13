import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../providers/core_providers.dart';

/// Provider Riverpod untuk instans [FcmTokenRepository].
final fcmTokenRepositoryProvider = Provider<FcmTokenRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return FcmTokenRepository(client);
});

/// Repository untuk sinkronisasi dan penghapusan token FCM pada backend SIMLOG RS.
class FcmTokenRepository {
  final DioClient _client;

  /// Membuat instans [FcmTokenRepository] dengan ketergantungan klien HTTP [_client].
  FcmTokenRepository(this._client);

  /// Mengambil klien HTTP yang digunakan repository ini.
  DioClient get client => _client;

  /// Mengirimkan token FCM perangkat ke backend SIMLOG RS.
  /// Mengembalikan true bila server menerima token, false bila gagal (error dicatat, tidak dilempar).
  Future<bool> syncToken(String token) async {
    try {
      await _client.dio.post(
        '/auth/fcm-token',
        data: {
          'token': token,
          'device_type': 'android',
        },
      );
      return true;
    } on DioException catch (e) {
      debugPrint(
        'Gagal sinkronisasi token FCM (${e.response?.statusCode}): ${e.message}',
      );
    } catch (e) {
      debugPrint('Gagal sinkronisasi token FCM tak terduga: $e');
    }
    return false;
  }

  /// Menghapus token FCM aktif dari backend SIMLOG RS saat sesi pengguna berakhir.
  Future<void> deleteToken() async {
    try {
      await _client.dio.delete('/auth/fcm-token');
    } on DioException catch (e) {
      debugPrint(
        'Gagal menghapus token FCM (${e.response?.statusCode}): ${e.message}',
      );
    } catch (e) {
      debugPrint('Gagal menghapus token FCM tak terduga: $e');
    }
  }
}
