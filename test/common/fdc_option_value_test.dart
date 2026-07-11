import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcOption', () {
    test('behaves as a value object', () {
      const option = FdcOption<int>(value: 1, label: 'One');
      const sameOption = FdcOption<int>(value: 1, label: 'One');

      expect(option, sameOption);
      expect(option.hashCode, sameOption.hashCode);
      expect(option, const FdcOption<Object?>(value: 1, label: 'One'));
      expect(option, isNot(const FdcOption<int>(value: 2, label: 'Two')));
    });

    test('includes value and label in equality', () {
      const base = FdcOption<String?>(value: null, label: 'None');

      expect(base, isNot(const FdcOption<String?>(value: 'A', label: 'None')));
      expect(
        base,
        isNot(const FdcOption<String?>(value: null, label: 'Empty')),
      );
    });
  });
}
