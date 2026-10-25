/// Brazilian formatting helpers for money and dates.
library;

/// 123456 -> "1.234,56"
String formatCents(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final reais = (abs ~/ 100).toString();
  final centavos = (abs % 100).toString().padLeft(2, '0');

  final grouped = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) grouped.write('.');
    grouped.write(reais[i]);
  }
  return '${negative ? '-' : ''}$grouped,$centavos';
}

/// Parses what the user typed in a money field.
///
/// "80" -> 8000, "80,5" -> 8050, "1.234,56" -> 123456, "" -> 0.
/// A single dot followed by 1-2 digits ("80.50") is read as the decimal
/// separator, since some keyboards only offer the dot.
/// Returns null when the text is not a valid amount.
int? parseCents(String text) {
  var cleaned = text.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (cleaned.isEmpty) return 0;

  if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(cleaned)) {
    cleaned = cleaned.replaceFirst('.', ',');
  }

  final match = RegExp(r'^(\d{1,3}(?:\.\d{3})*|\d+)(?:,(\d{1,2}))?$')
      .firstMatch(cleaned);
  if (match == null) return null;

  final reais = int.parse(match.group(1)!.replaceAll('.', ''));
  final centavos = int.parse((match.group(2) ?? '0').padRight(2, '0'));
  return reais * 100 + centavos;
}

/// DateTime(2026, 10, 5) -> "05/10/2026"; null -> "".
String formatDate(DateTime? date) {
  if (date == null) return '';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
