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
}
