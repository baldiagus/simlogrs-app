import 'package:dio/dio.dart';

import 'api_response.dart';

/// Maps failures to safe UI copy. Never exposes exception or server text.
/// [action] is a verb phrase, for example `memuat daftar notifikasi`.
String userErrorMessage(
  Object? error, {
  String? action,
  String? forbiddenMessage,
  String? notFoundMessage,
}) {
  if (error is DioException) {
    if (error.error is ApiException) {
      return userErrorMessage(
        error.error,
        action: action,
        forbiddenMessage: forbiddenMessage,
        notFoundMessage: notFoundMessage,
      );
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server belum merespons. Silakan coba beberapa saat lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badCertificate:
        return 'Koneksi aman ke server tidak dapat diverifikasi. Hubungi admin.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      default:
        return userErrorMessage(
          ApiException(message: '', statusCode: error.response?.statusCode),
          action: action,
          forbiddenMessage: forbiddenMessage,
          notFoundMessage: notFoundMessage,
        );
    }
  }
  if (error is ApiException) {
    if (error.statusCode == 401) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }
    if (error.statusCode == 403) {
      return forbiddenMessage ??
          'Anda tidak memiliki izin untuk melakukan tindakan ini. '
              'Hubungi admin untuk memeriksa hak akses Anda.';
    }
    if (error.statusCode == 404) {
      return notFoundMessage ??
          'Data tidak ditemukan atau sudah tidak tersedia. '
              'Muat ulang halaman untuk memperbarui data.';
    }
    if (error.isNetworkError) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    if (error.statusCode == 422 || error.statusCode == 400) {
      return 'Ada data yang belum lengkap atau tidak sesuai. '
          'Periksa kembali isian Anda.';
    }
    if (error.statusCode == 409) {
      return 'Data atau status transaksi telah berubah. '
          'Muat ulang data sebelum melanjutkan.';
    }
    if (error.statusCode == 429) {
      return 'Terlalu banyak permintaan. Tunggu beberapa saat sebelum mencoba lagi.';
    }
    if (error.statusCode != null && error.statusCode! >= 500) {
      return 'Layanan sedang mengalami kendala. Silakan coba beberapa saat lagi.';
    }
  }
  return action == null
      ? 'Terjadi kendala saat memproses permintaan Anda. Silakan coba lagi.'
      : 'Terjadi kendala saat $action. Silakan coba lagi.';
}
