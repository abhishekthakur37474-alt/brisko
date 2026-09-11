import 'package:intl/intl.dart';

final inr = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);
final inrExact = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 2);

String rupees(num value) {
  if (value == value.roundToDouble()) return inr.format(value);
  return inrExact.format(value);
}
