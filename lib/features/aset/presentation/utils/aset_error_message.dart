import '../../../../core/network/user_error_message.dart';

enum AsetErrorContext { umum, konfirmasiPengembalian }

/// Pesan aman untuk pengguna pada alur aset; detail exception tetap untuk log.
String asetErrorMessage(
  Object error, {
  AsetErrorContext context = AsetErrorContext.umum,
}) {
  return userErrorMessage(
    error,
    notFoundMessage: 'Aset tidak ditemukan.',
    forbiddenMessage: context == AsetErrorContext.konfirmasiPengembalian
        ? 'Anda tidak berwenang mengonfirmasi pengembalian aset ini. '
            'Konfirmasi hanya dapat dilakukan oleh petugas dari ruangan atau '
            'gudang penyedia asal aset, atau admin yang berwenang.'
        : null,
  );
}
