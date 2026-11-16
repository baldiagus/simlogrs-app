import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/network/api_response.dart';
import '../../../lib/features/aset/presentation/utils/aset_error_message.dart';

void main() {
  test('asset errors expose actionable messages without server details', () {
    final cases = <(Object, String)>[
      (ApiException(message: 'SQL private detail', statusCode: 403), 'Anda tidak memiliki izin untuk melakukan tindakan ini. Hubungi admin untuk memeriksa hak akses Anda.'),
      (ApiException(message: 'token', statusCode: 401), 'Sesi Anda telah berakhir. Silakan masuk kembali.'),
      (ApiException(message: 'missing', statusCode: 404), 'Aset tidak ditemukan.'),
      (ApiException(message: 'socket', isNetworkError: true), 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'),
      (ApiException(message: 'stack trace', statusCode: 500), 'Layanan sedang mengalami kendala. Silakan coba beberapa saat lagi.'),
      (StateError('private detail'), 'Terjadi kendala saat memproses permintaan Anda. Silakan coba lagi.'),
    ];
    for (final (error, expected) in cases) {
      expect(asetErrorMessage(error), expected);
    }
  });

  test('return confirmation explains authorized providers without server details', () {
    expect(
      asetErrorMessage(
        ApiException(message: 'SQL private detail', statusCode: 403),
        context: AsetErrorContext.konfirmasiPengembalian,
      ),
      'Anda tidak berwenang mengonfirmasi pengembalian aset ini. '
      'Konfirmasi hanya dapat dilakukan oleh petugas dari ruangan atau '
      'gudang penyedia asal aset, atau admin yang berwenang.',
    );
  });

  test('return context preserves non-permission error messages', () {
    for (final status in [401, 404, 422, 500]) {
      final error = ApiException(message: 'private detail', statusCode: status);
      expect(
        asetErrorMessage(error, context: AsetErrorContext.konfirmasiPengembalian),
        asetErrorMessage(error),
      );
    }
  });
}
