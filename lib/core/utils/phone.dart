class PhoneUtil {
  static String digits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  static String normalize(String raw) {
    var d = digits(raw);
    if (d.startsWith('0')) d = d.replaceFirst(RegExp(r'^0+'), '');
    if (d.length == 10) d = '91$d';
    if (d.startsWith('91') && d.length == 12) return d;
    return d;
  }

  static bool isValidIndianMobile(String raw) {
    return RegExp(r'^91[6-9]\d{9}$').hasMatch(normalize(raw));
  }

  static String e164(String raw) => '+${normalize(raw)}';

  static String display(String raw) {
    final n = normalize(raw);
    if (n.length == 12) return '+${n.substring(0, 2)} ${n.substring(2)}';
    return raw;
  }
}
