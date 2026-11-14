import '../../../../core/network/api_response.dart';

/// Pesan aman untuk pengguna pada alur aset; detail exception tetap untuk log.
String asetErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 403) return 'Anda tidak memiliki akses.';
    if (error.statusCode == 401) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }
    if (error.statusCode == 404) return 'Aset tidak ditemukan.';
    if (error.isNetworkError) {
      return 'Tidak dapat terhubung. Periksa koneksi internet Anda.';
    }
    if (error.statusCode == 422) {
      return 'Data tidak valid. Periksa kembali isian Anda.';
    }
  }
  return 'Terjadi kendala. Silakan coba lagi.';
}
