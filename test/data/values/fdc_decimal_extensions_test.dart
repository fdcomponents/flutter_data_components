import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('num decimal extension creates inferred-scale FdcDecimal values', () {
    final whole = 100.decimal;
    final fractional = 100.25.decimal;

    expect(whole, isA<FdcDecimal>());
    expect(whole.toString(), '100');
    expect(whole.scale, 0);
    expect(fractional.toString(), '100.25');
    expect(fractional.scale, 2);
  });

  test('num decimalScale extension normalizes to requested scale', () {
    expect(100.decimalScale(2).toString(), '100.00');
    expect(1.235.decimalScale(2).toString(), '1.24');
  });

  test('string decimal extension preserves exact textual scale', () {
    final value = '100.2500'.decimal;

    expect(value, isA<FdcDecimal>());
    expect(value.toString(), '100.2500');
    expect(value.scale, 4);
  });

  test('string decimalScale extension rounds to requested scale', () {
    expect('100.255'.decimalScale(2).toString(), '100.26');
  });

  test('FdcDecimal zero and one helpers provide ergonomic fallbacks', () {
    expect(FdcDecimal.zero.toString(), '0');
    expect(FdcDecimal.one.toString(), '1');
    expect(FdcDecimal.zero + 100.decimal, 100.decimal);
  });
}
