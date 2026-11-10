import 'package:flutter_test/flutter_test.dart';

import 'package:service_order_app/core/formatting/formatters.dart';

void main() {
  test('formatCents uses Brazilian separators', () {
    expect(formatCents(0), '0,00');
    expect(formatCents(8000), '80,00');
    expect(formatCents(38050), '380,50');
    expect(formatCents(123456789), '1.234.567,89');
  });

  test('parseCents accepts what users type', () {
    expect(parseCents(''), 0);
    expect(parseCents('80'), 8000);
    expect(parseCents('80,5'), 8050);
    expect(parseCents('80,50'), 8050);
    expect(parseCents('80.50'), 8050);
    expect(parseCents('1.234,56'), 123456);
    expect(parseCents('R\$ 160,00'), 16000);
  });

  test('parseCents rejects invalid amounts', () {
    expect(parseCents('abc'), isNull);
    expect(parseCents('80,555'), isNull);
    expect(parseCents('1,2,3'), isNull);
  });

  test('formatDate', () {
    expect(formatDate(null), '');
    expect(formatDate(DateTime(2026, 3, 5)), '05/03/2026');
  });

  String pt(DateTime date, DateTime now) => formatDayLabel(
        date,
        languageCode: 'pt',
        today: 'Hoje',
        yesterday: 'Ontem',
        now: now,
      );

  String en(DateTime date, DateTime now) => formatDayLabel(
        date,
        languageCode: 'en',
        today: 'Today',
        yesterday: 'Yesterday',
        now: now,
      );

  test('formatDayLabel uses today, yesterday and full dates', () {
    final now = DateTime(2026, 11, 3, 8);

    expect(pt(DateTime(2026, 11, 3, 23, 59), now), 'Hoje');
    expect(pt(DateTime(2026, 11, 2, 0, 1), now), 'Ontem');
    expect(pt(DateTime(2026, 10, 25, 14), now), '25 de outubro de 2026');
    expect(pt(DateTime(2025, 3, 1), now), '1 de março de 2025');
  });

  test('formatDayLabel in English', () {
    final now = DateTime(2026, 11, 3, 8);

    expect(en(DateTime(2026, 11, 3), now), 'Today');
    expect(en(DateTime(2026, 11, 2), now), 'Yesterday');
    expect(en(DateTime(2026, 10, 25), now), 'October 25, 2026');
  });

  test('formatDayLabel handles month and year boundaries', () {
    expect(pt(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), 'Ontem');
  });

  test('formatTime', () {
    expect(formatTime(DateTime(2026, 10, 5, 9, 7)), '09:07');
    expect(formatTime(DateTime(2026, 10, 5, 23, 45)), '23:45');
  });
}
