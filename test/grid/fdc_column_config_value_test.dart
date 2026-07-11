import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGridCellStyle', () {
    test('behaves as a value object', () {
      const style = FdcGridCellStyle(
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        backgroundColor: Colors.amber,
        alignment: Alignment.centerRight,
      );
      const sameStyle = FdcGridCellStyle(
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        backgroundColor: Colors.amber,
        alignment: Alignment.centerRight,
      );

      expect(style, sameStyle);
      expect(style.hashCode, sameStyle.hashCode);
      expect(style, isNot(style.copyWith(backgroundColor: Colors.green)));
    });

    test('copyWith keeps omitted values and replaces provided values', () {
      const base = FdcGridCellStyle(
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        backgroundColor: Colors.amber,
      );

      expect(base.copyWith(), base);
      expect(
        base.copyWith(alignment: Alignment.center),
        const FdcGridCellStyle(
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          backgroundColor: Colors.amber,
          alignment: Alignment.center,
        ),
      );
    });
  });

  group('FdcColumnSummary', () {
    test('behaves as a value object', () {
      const summary = FdcColumnSummary(
        aggregate: FdcAggregate.sum,
        label: 'Total',
        labelVisible: false,
        labelAlignment: FdcSummaryLabelAlignment.startAligned,
        allowAggregateChange: true,
        style: FdcGridSummaryCellStyle(backgroundColor: Colors.black12),
      );
      const sameSummary = FdcColumnSummary(
        aggregate: FdcAggregate.sum,
        label: 'Total',
        labelVisible: false,
        labelAlignment: FdcSummaryLabelAlignment.startAligned,
        allowAggregateChange: true,
        style: FdcGridSummaryCellStyle(backgroundColor: Colors.black12),
      );

      expect(summary, sameSummary);
      expect(summary.hashCode, sameSummary.hashCode);
      expect(summary, isNot(summary.copyWith(aggregate: FdcAggregate.avg)));
    });

    test('copyWith keeps omitted values and replaces provided values', () {
      const base = FdcColumnSummary(
        aggregate: FdcAggregate.sum,
        label: 'Total',
      );

      expect(base.copyWith(), base);
      expect(
        base.copyWith(allowAggregateChange: true),
        const FdcColumnSummary(
          aggregate: FdcAggregate.sum,
          label: 'Total',
          allowAggregateChange: true,
        ),
      );
    });
  });

  group('FdcColumnFilterConfig', () {
    test('behaves as a value object with list fields', () {
      const config = FdcColumnFilterConfig(
        editor: FdcFilterEditor.combo,
        values: <FdcOption<Object?>>[
          FdcOption<Object?>(value: 'A', label: 'Active'),
        ],
        defaultOperator: FdcFilterOperator.equals,
        operators: <FdcFilterOperator>[FdcFilterOperator.equals],
        caseSensitive: true,
        comboSearchable: true,
        comboSearchHintText: 'Find',
        comboMaxPopupItems: 12,
      );
      const sameConfig = FdcColumnFilterConfig(
        editor: FdcFilterEditor.combo,
        values: <FdcOption<Object?>>[
          FdcOption<Object?>(value: 'A', label: 'Active'),
        ],
        defaultOperator: FdcFilterOperator.equals,
        operators: <FdcFilterOperator>[FdcFilterOperator.equals],
        caseSensitive: true,
        comboSearchable: true,
        comboSearchHintText: 'Find',
        comboMaxPopupItems: 12,
      );

      expect(config, sameConfig);
      expect(config.hashCode, sameConfig.hashCode);
      expect(config, isNot(config.copyWith(comboMaxPopupItems: 20)));
    });

    test('copyWith keeps omitted values and replaces provided values', () {
      const base = FdcColumnFilterConfig(enabled: false);

      expect(base.copyWith(), base);
      expect(
        base.copyWith(enabled: true, editor: FdcFilterEditor.combo),
        const FdcColumnFilterConfig(editor: FdcFilterEditor.combo),
      );
    });
  });

  group('FdcGridSummaryCellStyle', () {
    test('behaves as a value object', () {
      const style = FdcGridSummaryCellStyle(
        backgroundColor: Colors.black12,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 8),
      );
      const sameStyle = FdcGridSummaryCellStyle(
        backgroundColor: Colors.black12,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 8),
      );

      expect(style, sameStyle);
      expect(style.hashCode, sameStyle.hashCode);
      expect(style, isNot(style.copyWith(alignment: Alignment.center)));
    });
  });
}
