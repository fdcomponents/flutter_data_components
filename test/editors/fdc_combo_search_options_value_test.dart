import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcComboSearchOptions', () {
    test('behaves as a value object', () {
      const options = FdcComboSearchOptions(
        searchable: true,
        searchableInline: true,
        mode: FdcComboSearchMode.contains,
      );
      const sameOptions = FdcComboSearchOptions(
        searchable: true,
        searchableInline: true,
        mode: FdcComboSearchMode.contains,
      );

      expect(options, sameOptions);
      expect(options.hashCode, sameOptions.hashCode);
      expect(options, isNot(const FdcComboSearchOptions()));
    });

    test('includes every public field in equality', () {
      const base = FdcComboSearchOptions();

      expect(base, isNot(const FdcComboSearchOptions(searchable: true)));
      expect(base, isNot(const FdcComboSearchOptions(searchableInline: true)));
      expect(
        base,
        isNot(const FdcComboSearchOptions(mode: FdcComboSearchMode.contains)),
      );
    });

    test('copyWith keeps omitted values and replaces provided values', () {
      const base = FdcComboSearchOptions(searchable: true);

      expect(base.copyWith(), base);
      expect(
        base.copyWith(searchableInline: true),
        const FdcComboSearchOptions(searchable: true, searchableInline: true),
      );
      expect(
        base.copyWith(mode: FdcComboSearchMode.contains),
        const FdcComboSearchOptions(
          searchable: true,
          mode: FdcComboSearchMode.contains,
        ),
      );
    });
  });
}
