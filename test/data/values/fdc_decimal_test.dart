import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FdcDecimal stores exact fixed-scale decimal text', () {
    final value = FdcDecimal.parseNormalized('1.005', scale: 2);

    expect(value.toString(), '1.01');
    expect(value.scaledValue, BigInt.from(101));
    expect(value.scale, 2);
  });

  test('FdcDecimal compares values with different scales numerically', () {
    final left = FdcDecimal.parseNormalized('1.20', scale: 2);
    final right = FdcDecimal.parseNormalized('1.2000', scale: 4);

    expect(left, right);
    expect(left.compareTo(right), 0);
  });

  test('FdcDecimal rounds half away from zero when reducing fixed scale', () {
    final positive = FdcDecimal.parseNormalized('123.5', scale: 0);
    final negative = FdcDecimal.parseNormalized('-123.5', scale: 0);

    expect(positive.toString(), '124');
    expect(negative.toString(), '-124');
  });

  test('decimal field stores runtime value as FdcDecimal', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(name: 'amount', precision: 6, scale: 2),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'amount': '1.005'},
        ],
      ),
    );
    await dataSet.open();

    final value = dataSet.fieldByName('amount').value;

    expect(value, isA<FdcDecimal>());
    expect(dataSet.fieldByName('amount').asDecimal?.toString(), '1.01');
    expect(dataSet.fieldByName('amount').asNum, 1.01);
  });
  test('rejects invalid normalized decimal text before rounding', () {
    expect(FdcDecimal.tryParseNormalized('abc', scale: 2), isNull);
    expect(FdcDecimal.tryParseNormalized('12x.34', scale: 2), isNull);
    expect(FdcDecimal.tryParseNormalized('-', scale: 2), isNull);
    expect(FdcDecimal.tryParseNormalized('.', scale: 2), isNull);
    expect(FdcDecimal.tryParseNormalized('-.', scale: 2), isNull);
    expect(
      () => FdcDecimal.parseNormalized('abc', scale: 2),
      throwsFormatException,
    );
    expect(
      () => FdcDecimal.parseNormalized('-', scale: 2),
      throwsFormatException,
    );
  });

  test(
    'FdcDecimal multiplication rounds result scale when operand scales exceed maximum',
    () {
      final left = '0.12345678901234567890'.decimal;
      final right = '0.12345678901234567890'.decimal;

      final result = left * right;

      expect(result.scale, 38);
      expect(result.toString(), '0.01524157875323883675019051998750190521');
    },
  );

  group('roundTo', () {
    test('uses half away from zero by default', () {
      expect('1.225'.decimal.roundTo(2).toString(), '1.23');
      expect('-1.225'.decimal.roundTo(2).toString(), '-1.23');
    });

    test('supports half even midpoint rounding', () {
      expect(
        '1.225'.decimal.roundTo(2, mode: FdcRoundingMode.halfEven).toString(),
        '1.22',
      );
      expect(
        '1.235'.decimal.roundTo(2, mode: FdcRoundingMode.halfEven).toString(),
        '1.24',
      );
      expect(
        '1.245'.decimal.roundTo(2, mode: FdcRoundingMode.halfEven).toString(),
        '1.24',
      );
      expect(
        '1.255'.decimal.roundTo(2, mode: FdcRoundingMode.halfEven).toString(),
        '1.26',
      );
    });

    test('supports half even rounding for negative values', () {
      expect(
        '-2.5'.decimal.roundTo(0, mode: FdcRoundingMode.halfEven).toString(),
        '-2',
      );
      expect(
        '-3.5'.decimal.roundTo(0, mode: FdcRoundingMode.halfEven).toString(),
        '-4',
      );
    });

    test('distinguishes exact midpoint from nearby values', () {
      expect(
        '1.2249'.decimal.roundTo(2, mode: FdcRoundingMode.halfEven).toString(),
        '1.22',
      );
      expect(
        '1.2251'.decimal.roundTo(2, mode: FdcRoundingMode.halfEven).toString(),
        '1.23',
      );
    });

    test('supports explicit half up rounding', () {
      expect('1.225'.decimal.roundTo(2).toString(), '1.23');
      expect('-1.225'.decimal.roundTo(2).toString(), '-1.23');
      expect('1.224'.decimal.roundTo(2).toString(), '1.22');
    });

    test('supports half down midpoint rounding', () {
      expect(
        '1.225'.decimal.roundTo(2, mode: FdcRoundingMode.halfDown).toString(),
        '1.22',
      );
      expect(
        '-1.225'.decimal.roundTo(2, mode: FdcRoundingMode.halfDown).toString(),
        '-1.22',
      );
      expect(
        '1.2251'.decimal.roundTo(2, mode: FdcRoundingMode.halfDown).toString(),
        '1.23',
      );
      expect(
        '-1.2251'.decimal.roundTo(2, mode: FdcRoundingMode.halfDown).toString(),
        '-1.23',
      );
    });

    test('increases scale without changing the value', () {
      final rounded = '1.2'.decimal.roundTo(4, mode: FdcRoundingMode.halfEven);

      expect(rounded.toString(), '1.2000');
      expect(rounded.scale, 4);
    });

    test('returns the same instance when scale is unchanged', () {
      final value = '1.20'.decimal;

      expect(identical(value.roundTo(2), value), isTrue);
    });

    test('rejects target scale outside supported range', () {
      final value = '1.2'.decimal;

      expect(() => value.roundTo(-1), throwsRangeError);
      expect(() => value.roundTo(39), throwsRangeError);
    });
  });
}
