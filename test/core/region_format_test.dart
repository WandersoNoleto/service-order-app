import 'package:flutter_test/flutter_test.dart';

import 'package:service_order_app/core/formatting/region_format.dart';

void main() {
  const br = RegionFormat.brazil;
  const us = RegionFormat.unitedStates;

  test('money', () {
    expect(br.money(123456), 'R\$ 1.234,56');
    expect(us.money(123456), '\$1,234.56');
    expect(br.amount(8000), '80,00');
    expect(us.amount(8000), '80.00');
    expect(us.money(-500), '-\$5.00');
  });

  test('parse money typed in each format', () {
    expect(br.parseMoney('1.234,56'), 123456);
    expect(us.parseMoney('1,234.56'), 123456);
    expect(us.parseMoney('\$80'), 8000);
    expect(us.parseMoney('80.5'), 8050);
    expect(us.parseMoney(''), 0);
    expect(us.parseMoney('80,50'), isNull);
    expect(us.parseMoney('abc'), isNull);
  });

  test('dates', () {
    final date = DateTime(2026, 10, 5);
    expect(br.date(date), '05/10/2026');
    expect(us.date(date), '10/05/2026');
    expect(us.date(null), '');
  });

  test('times', () {
    expect(br.time('14:30'), '14:30');
    expect(us.time('14:30'), '2:30 PM');
    expect(us.time('00:05'), '12:05 AM');
    expect(us.time('12:00'), '12:00 PM');
    expect(us.timeOf(DateTime(2026, 1, 1, 9, 7)), '9:07 AM');
  });
}
