/// Helpers for reading an outlet's `openTime` / `closeTime` (admin managed)
/// and deciding whether the store is currently accepting orders.
///
/// Times are stored as free text in the admin panel, so parsing is kept
/// forgiving: `11:00`, `9:5`, `11:00 PM` and `23:30` are all accepted.
class StoreHours {
  /// Minutes since midnight for a `HH:mm` style value, or `null` if unparseable.
  static int? parseMinutes(String value) {
    final raw = value.trim().toUpperCase();
    if (raw.isEmpty) return null;

    final isPm = raw.contains('PM');
    final isAm = raw.contains('AM');
    final cleaned = raw.replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = cleaned.split(':').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;

    var hour = int.tryParse(parts.first);
    if (hour == null) return null;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    if (isPm || isAm) {
      hour = hour % 12;
      if (isPm) hour += 12;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  /// True when [now] falls inside the [open, close) window.
  ///
  /// Handles overnight windows (e.g. `11:00` – `02:00`) and treats an equal
  /// open/close pair, or unparseable input, as always open so a misconfigured
  /// outlet never silently blocks ordering.
  static bool isOpenAt(DateTime now, String open, String close) {
    final openMinutes = parseMinutes(open);
    final closeMinutes = parseMinutes(close);
    if (openMinutes == null || closeMinutes == null) return true;
    if (openMinutes == closeMinutes) return true;

    final current = now.hour * 60 + now.minute;
    if (openMinutes < closeMinutes) {
      return current >= openMinutes && current < closeMinutes;
    }
    return current >= openMinutes || current < closeMinutes;
  }

  /// The next moment the store opens, based on its daily schedule.
  static DateTime nextOpeningAt(DateTime now, String open, String close) {
    final openMinutes = parseMinutes(open) ?? 0;
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      openMinutes ~/ 60,
      openMinutes % 60,
    );
    if (!today.isAfter(now)) return today.add(const Duration(days: 1));
    return today;
  }

  /// Formats a stored time as a 12-hour label, e.g. `11:00` -> `11:00 AM`.
  static String format12h(String value) {
    final minutes = parseMinutes(value);
    if (minutes == null) return value.trim();
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Label for the next opening, e.g. `Today 11:00 AM` / `Tomorrow 11:00 AM`.
  static String nextOpeningLabel(DateTime now, String open, String close) {
    final next = nextOpeningAt(now, open, close);
    final time = format12h(open);
    final sameDay = next.year == now.year && next.month == now.month && next.day == now.day;
    return sameDay ? 'Today $time' : 'Tomorrow $time';
  }
}
