import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/network/api_response.dart';
import '../../../lib/features/aset/presentation/utils/aset_error_message.dart';

void main() {
  test('asset errors expose actionable messages without server details', () {
    final cases = <(Object, String)>[
      (ApiException(message: 'SQL private detail', statusCode: 403), 'Anda tidak memiliki akses.'),
      (ApiException(message: 'token', statusCode: 401), 'Sesi Anda telah berakhir. Silakan masuk kembali.'),
      (ApiException(message: 'missing', statusCode: 404), 'Aset tidak ditemukan.'),
      (ApiException(message: 'socket', isNetworkError: true), 'Tidak dapat terhubung. Periksa koneksi internet Anda.'),
      (ApiException(message: 'stack trace', statusCode: 500), 'Terjadi kendala. Silakan coba lagi.'),
      (StateError('private detail'), 'Terjadi kendala. Silakan coba lagi.'),
    ];
    for (final (error, expected) in cases) {
      expect(asetErrorMessage(error), expected);
    }
  });
}
