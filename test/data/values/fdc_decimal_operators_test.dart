import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

FdcDecimal d(String value, {int scale = 2}) {
  return FdcDecimal.parseNormalized(value, scale: scale);
}

void main() {
  test('FdcDecimal arithmetic operators keep decimal-safe scale semantics', () {
    expect((d('10.50') + d('2.25')).toString(), '12.75');
    expect((d('10.50') - d('2.25')).toString(), '8.25');
    expect((d('10.50') * d('2.00')).toString(), '21.0000');
    expect((d('10.00') / d('4.00')).toString(), '2.500000000000');
    expect((-d('10.50')).toString(), '-10.50');
  });

  test('FdcDecimal division result can be used in chained expressions', () {
    final result = (d('10.00') / d('4.00')) + d('1.25');

    expect(result, isA<FdcDecimal>());
    expect(result.toString(), '3.750000000000');
  });

  test('FdcDecimal supports modulo and integer division operators', () {
    expect((d('10', scale: 0) % d('3', scale: 0)).toString(), '1');
    expect((d('10.50') % d('0.20')).toString(), '0.10');
    expect(d('10', scale: 0) ~/ d('3', scale: 0), 3);
    expect(d('10.50') ~/ d('0.20'), 52);
  });

  test('FdcDecimal modulo and integer division reject zero divisors', () {
    expect(() => d('10', scale: 0) % d('0', scale: 0), throwsUnsupportedError);
    expect(() => d('10', scale: 0) ~/ d('0', scale: 0), throwsUnsupportedError);
  });

  test('FdcDecimal supports comparison operators across different scales', () {
    final onePointTwo = FdcDecimal.parseNormalized('1.2', scale: 1);
    final onePointTwenty = FdcDecimal.parseNormalized('1.20', scale: 2);
    final two = FdcDecimal.parseNormalized('2', scale: 0);

    expect(onePointTwo == onePointTwenty, isTrue);
    expect(onePointTwo.hashCode, onePointTwenty.hashCode);
    expect(two > onePointTwenty, isTrue);
    expect(onePointTwenty < two, isTrue);
    expect(onePointTwenty >= onePointTwo, isTrue);
    expect(onePointTwenty <= onePointTwo, isTrue);
    expect(onePointTwenty.compareTo(onePointTwo), 0);
  });

  test(
    'FdcDecimal supports comparisons with finite num operands but equality stays decimal-only',
    () {
      final amount = d('12.50');
      const Object rawDouble = 12.5;
      final Object rawAmount = amount;

      expect(amount == rawDouble, isFalse);
      expect(12.5 == rawAmount, isFalse);
      expect(amount == 12.5.decimal, isTrue);
      expect(amount > 12, isTrue);
      expect(amount >= 12.5, isTrue);
      expect(amount < 13, isTrue);
      expect(amount <= 12.5, isTrue);
    },
  );

  test('FdcDecimal integer helper methods use numeric semantics', () {
    expect(d('12.50').round(), 13);
    expect(d('12.49').round(), 12);
    expect(d('-12.50').round(), -13);
    expect(d('12.90').floor(), 12);
    expect(d('-12.10').floor(), -13);
    expect(d('12.10').ceil(), 13);
    expect(d('-12.90').ceil(), -12);
    expect(d('12.90').truncate(), 12);
    expect(d('-12.90').truncate(), -12);
    expect(d('-12.90').abs().toString(), '12.90');
  });

  test(
    'FdcDecimal clamp returns decimal bounds without converting to double',
    () {
      expect(d('12.50').clamp(d('10.00'), d('20.00')).toString(), '12.50');
      expect(d('9.99').clamp(d('10.00'), d('20.00')).toString(), '10.00');
      expect(d('25.00').clamp(d('10.00'), d('20.00')).toString(), '20.00');
    },
  );

  test('FdcDecimal equality is symmetric and hash-safe for map/set keys', () {
    final decimal = d('1.00');
    const Object rawInt = 1;
    final Object rawDecimal = decimal;

    expect(decimal == rawInt, isFalse);
    expect(1 == rawDecimal, isFalse);
    expect(decimal == 1.decimal, isTrue);
    expect(<Object>{decimal, 1}.length, 2);
  });
}
