import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dbDateFormat = DateFormat('yyyy-MM-dd');

  static String rupiah(num? amount, {String fallback = 'Rp 0'}) {
    if (amount == null) return fallback;
    return _rupiahFormat.format(amount);
  }

  static String tanggal(DateTime? date, {String fallback = '-'}) {
    if (date == null) return fallback;
    return _displayDateFormat.format(date);
  }

  static String tanggalString(String? isoString, {String fallback = '-'}) {
    if (isoString == null || isoString.trim().isEmpty) return fallback;
    try {
      final parsed = DateTime.parse(isoString);
      return _displayDateFormat.format(parsed);
    } catch (_) {
      return isoString;
    }
  }

  static String tanggalDb(DateTime? date) {
    if (date == null) return '';
    return _dbDateFormat.format(date);
  }
}
