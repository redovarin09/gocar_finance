import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final NumberFormat _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Rp 287.500
  static String format(int amount) => _fmt.format(amount);

  /// Rp 287rb / Rp 1.2jt (ringkas untuk card kecil)
  static String formatCompact(int amount) {
    if (amount >= 1000000) {
      final double juta = amount / 1000000;
      final String num = juta % 1 == 0
          ? juta.toInt().toString()
          : juta.toStringAsFixed(1);
      return 'Rp ${num}jt';
    }
    if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return format(amount);
  }
}
