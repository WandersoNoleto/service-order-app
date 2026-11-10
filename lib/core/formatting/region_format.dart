import 'formatters.dart';

/// Regional format for money, dates and times, chosen independently of the
/// app language (e.g. English interface with Brazilian formats).
///
/// Money is always stored in cents; only its text changes.
sealed class RegionFormat {
  const RegionFormat();

  static const brazil = _BrazilFormat();
  static const unitedStates = _UnitedStatesFormat();

  String get currencySymbol;

  /// With the currency symbol: "R$ 1.234,56" / "$1,234.56".
  String money(int cents);

  /// Without the symbol, for tables and input fields: "1.234,56" / "1,234.56".
  String amount(int cents);

  /// What the user typed in a money field, or null when it is not valid.
  /// An empty text is zero.
  int? parseMoney(String text);

  /// "25/10/2026" / "10/25/2026"; null -> "".
  String date(DateTime? date);

  /// [hhmm] as stored ("14:30") -> "14:30" / "2:30 PM".
  String time(String hhmm);

  /// Time of a DateTime, same rule as [time].
  String timeOf(DateTime date) => time(formatTime(date));
}

class _BrazilFormat extends RegionFormat {
  const _BrazilFormat();

  @override
  String get currencySymbol => 'R\$';

  @override
  String money(int cents) => 'R\$ ${formatCents(cents)}';

  @override
  String amount(int cents) => formatCents(cents);

  @override
  int? parseMoney(String text) => parseCents(text);

  @override
  String date(DateTime? date) => formatDate(date);

  @override
  String time(String hhmm) => hhmm;
}

class _UnitedStatesFormat extends RegionFormat {
  const _UnitedStatesFormat();

  @override
  String get currencySymbol => '\$';

  @override
  String money(int cents) =>
      cents < 0 ? '-\$${amount(-cents)}' : '\$${amount(cents)}';

  @override
  String amount(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final dollars = (abs ~/ 100).toString();
    final rest = (abs % 100).toString().padLeft(2, '0');

    final grouped = StringBuffer();
    for (var i = 0; i < dollars.length; i++) {
      if (i > 0 && (dollars.length - i) % 3 == 0) grouped.write(',');
      grouped.write(dollars[i]);
    }
    return '${negative ? '-' : ''}$grouped.$rest';
  }

  /// "80" -> 8000, "80.5" -> 8050, "1,234.56" -> 123456, "$80" -> 8000.
  @override
  int? parseMoney(String text) {
    final cleaned = text.trim().replaceAll('\$', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return 0;

    final match = RegExp(r'^(\d{1,3}(?:,\d{3})*|\d+)(?:\.(\d{1,2}))?$')
        .firstMatch(cleaned);
    if (match == null) return null;

    final dollars = int.parse(match.group(1)!.replaceAll(',', ''));
    final cents = int.parse((match.group(2) ?? '0').padRight(2, '0'));
    return dollars * 100 + cents;
  }

  @override
  String date(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  @override
  String time(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return hhmm;

    final period = hour < 12 ? 'AM' : 'PM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${parts[1]} $period';
  }
}
