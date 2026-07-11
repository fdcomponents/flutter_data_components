import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGridOptions', () {
    test('behaves as a value object', () {
      const options = FdcGridOptions(
        readOnly: true,
        allowColumnFiltering: false,
        autoEdit: false,
        confirmDelete: false,
        defaultColumnWidth: 180,
        rowHeight: 38,
        horizontalScrollMode: FdcGridHorizontalScrollMode.smooth,
        scrollbars: FdcGridScrollbars.vertical,
      );
      const sameOptions = FdcGridOptions(
        readOnly: true,
        allowColumnFiltering: false,
        autoEdit: false,
        confirmDelete: false,
        defaultColumnWidth: 180,
        rowHeight: 38,
        horizontalScrollMode: FdcGridHorizontalScrollMode.smooth,
        scrollbars: FdcGridScrollbars.vertical,
      );

      expect(options, sameOptions);
      expect(options.hashCode, sameOptions.hashCode);
      expect(options, isNot(const FdcGridOptions()));
    });

    test('includes every public option in equality', () {
      const base = FdcGridOptions();

      expect(base, isNot(const FdcGridOptions(readOnly: true)));
      expect(base, isNot(const FdcGridOptions(allowColumnSorting: true)));
      expect(base, isNot(const FdcGridOptions(allowColumnFiltering: false)));
      expect(base, isNot(const FdcGridOptions(allowColumnReordering: true)));
      expect(base, isNot(const FdcGridOptions(allowColumnResize: false)));
      expect(base, isNot(const FdcGridOptions(autoEdit: false)));
      expect(base, isNot(const FdcGridOptions(confirmDelete: false)));
      expect(base, isNot(const FdcGridOptions(defaultColumnWidth: 180)));
      expect(base, isNot(const FdcGridOptions(rowHeight: 38)));
      expect(
        base,
        isNot(
          const FdcGridOptions(
            verticalScrollMode: FdcGridVerticalScrollMode.smooth,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const FdcGridOptions(
            horizontalScrollMode: FdcGridHorizontalScrollMode.smooth,
          ),
        ),
      );
      expect(
        base,
        isNot(const FdcGridOptions(scrollbars: FdcGridScrollbars.none)),
      );
    });

    test('keeps optional interaction features opt-in by default', () {
      const options = FdcGridOptions();

      expect(options.allowColumnSorting, isFalse);
      expect(options.allowColumnReordering, isFalse);
      expect(const FdcGridHeaderFilters().visible, isFalse);
      expect(const FdcGridColumnPinning().enabled, isFalse);
      expect(const FdcGridRowIndicator().visible, isFalse);
    });

    test('asserts invalid layout dimensions in debug builds', () {
      const tooSmallColumnWidth = FdcGridOptions.minimumDefaultColumnWidth - 1;
      const tooSmallRowHeight = FdcGridOptions.minimumRowHeight - 1;
      const infinite = double.infinity;
      const nan = double.nan;

      expect(
        () => FdcGridOptions(defaultColumnWidth: tooSmallColumnWidth),
        throwsAssertionError,
      );
      expect(
        () => FdcGridOptions(defaultColumnWidth: infinite),
        throwsAssertionError,
      );
      expect(
        () => FdcGridOptions(defaultColumnWidth: nan),
        throwsAssertionError,
      );
      expect(
        () => FdcGridOptions(rowHeight: tooSmallRowHeight),
        throwsAssertionError,
      );
      expect(() => FdcGridOptions(rowHeight: infinite), throwsAssertionError);
      expect(() => FdcGridOptions(rowHeight: nan), throwsAssertionError);
    });

    test('validates layout dimensions in runtime code paths', () {
      const tooSmallColumnWidth = FdcGridOptions.minimumDefaultColumnWidth - 1;
      const tooSmallRowHeight = FdcGridOptions.minimumRowHeight - 1;

      expect(
        () => FdcGridOptions.validateDimensions(
          defaultColumnWidth: tooSmallColumnWidth,
          rowHeight: FdcGridOptions.fallbackRowHeight,
        ),
        throwsArgumentError,
      );
      expect(
        () => FdcGridOptions.validateDimensions(
          defaultColumnWidth: double.infinity,
          rowHeight: FdcGridOptions.fallbackRowHeight,
        ),
        throwsArgumentError,
      );
      expect(
        () => FdcGridOptions.validateDimensions(
          defaultColumnWidth: FdcGridOptions.fallbackDefaultColumnWidth,
          rowHeight: tooSmallRowHeight,
        ),
        throwsArgumentError,
      );
      expect(
        () => FdcGridOptions.validateDimensions(
          defaultColumnWidth: FdcGridOptions.fallbackDefaultColumnWidth,
          rowHeight: double.nan,
        ),
        throwsArgumentError,
      );
      expect(() => const FdcGridOptions().validate(), returnsNormally);
    });

    test('resolves unsafe layout dimensions for runtime safety', () {
      expect(
        FdcGridOptions.resolveDefaultColumnWidth(double.nan),
        FdcGridOptions.fallbackDefaultColumnWidth,
      );
      expect(
        FdcGridOptions.resolveDefaultColumnWidth(double.infinity),
        FdcGridOptions.fallbackDefaultColumnWidth,
      );
      expect(
        FdcGridOptions.resolveDefaultColumnWidth(-10),
        FdcGridOptions.minimumDefaultColumnWidth,
      );
      expect(
        FdcGridOptions.resolveDefaultColumnWidth(10),
        FdcGridOptions.minimumDefaultColumnWidth,
      );
      expect(FdcGridOptions.resolveDefaultColumnWidth(90), 90);

      expect(
        FdcGridOptions.resolveRowHeight(double.nan),
        FdcGridOptions.fallbackRowHeight,
      );
      expect(
        FdcGridOptions.resolveRowHeight(double.infinity),
        FdcGridOptions.fallbackRowHeight,
      );
      expect(
        FdcGridOptions.resolveRowHeight(-4),
        FdcGridOptions.minimumRowHeight,
      );
      expect(
        FdcGridOptions.resolveRowHeight(10),
        FdcGridOptions.minimumRowHeight,
      );
      expect(FdcGridOptions.resolveRowHeight(36), 36);
    });
  });
  group('FdcGridColumnPinning', () {
    test('behaves as a value object', () {
      const pinning = FdcGridColumnPinning(
        startPinnedGroupLabel: 'Identity',
        unpinnedGroupLabel: 'General',
        endPinnedGroupLabel: 'Financial',
      );
      const samePinning = FdcGridColumnPinning(
        startPinnedGroupLabel: 'Identity',
        unpinnedGroupLabel: 'General',
        endPinnedGroupLabel: 'Financial',
      );

      expect(pinning, samePinning);
      expect(pinning.hashCode, samePinning.hashCode);
      expect(pinning, isNot(const FdcGridColumnPinning()));
    });
  });
}
