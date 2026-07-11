import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/filtering/fdc_header_filter_options_resolver.dart';
import 'package:flutter_data_components/src/grid/filtering/fdc_header_filter_value_codec.dart';
import 'package:flutter_data_components/src/grid/format/fdc_field_value_codec.dart';
import 'package:flutter_data_components/src/grid/models/fdc_column_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('numeric column affixes are display-only for codec formatting', () {
    const codec = FdcFieldValueCodec(settings: FdcFormatSettings());

    const integerColumn = FdcIntegerColumn<dynamic>(
      fieldName: 'quantity',
      prefixText: '~',
      suffixText: ' pcs',
    );
    expect(codec.formatGridValue(integerColumn, 5), '~5 pcs');
    expect(codec.formatGridValue(integerColumn, 5, forEditing: true), '5');
    expect(codec.parseGridTextForCommit(integerColumn, '5').value, 5);

    const decimalColumn = FdcDecimalColumn<dynamic>(
      fieldName: 'amount',
      prefixText: r'$ ',
      suffixText: ' net',
    );
    expect(
      codec.formatGridValue(decimalColumn, 12.3, decimalScale: 2),
      r'$ 12.30 net',
    );
    expect(
      codec.formatGridValue(
        decimalColumn,
        12.3,
        decimalScale: 2,
        forEditing: true,
      ),
      '12.30',
    );
    expect(
      codec
          .parseGridTextForCommit(decimalColumn, '12.30', decimalScale: 2)
          .value,
      '12.30'.decimalScale(2),
    );
    expect(
      codec
          .parseGridTextForCommit(
            decimalColumn,
            r'$ 1,512.30 net',
            decimalScale: 2,
          )
          .value,
      '1512.30'.decimalScale(2),
    );
  });

  test('numeric column affixes stay out of header filter text formatting', () {
    const column = FdcDecimalColumn<dynamic>(
      fieldName: 'amount',
      prefixText: r'$ ',
      suffixText: ' net',
    );
    const runtimeColumnId = FdcColumnIdentity(1);
    final codec = FdcHeaderFilterValueCodec(
      formatSettings: const FdcFormatSettings(),
      dataTypeOf: (_) => FdcDataType.decimal,
      decimalScaleOf: (_) => 2,
      decimalPrecisionOf: (_) => 12,
      runtimeColumnIdOf: (_) => runtimeColumnId,
    );

    expect(
      codec.formatDisplayValue(column, 12.3, runtimeColumnId: runtimeColumnId),
      '12.30',
    );
    expect(
      codec.parseValue(column, '12.30', runtimeColumnId: runtimeColumnId),
      '12.30'.decimalScale(2),
    );
  });

  test('header filter decimal display respects column thousand format', () {
    const column = FdcDecimalColumn<dynamic>(
      fieldName: 'amount',
      formatSettings: FdcFormatSettings(
        decimalSeparator: ',',
        thousandSeparator: '.',
      ),
    );
    const runtimeColumnId = FdcColumnIdentity(1);
    final codec = FdcHeaderFilterValueCodec(
      formatSettings: const FdcFormatSettings(),
      dataTypeOf: (_) => FdcDataType.decimal,
      decimalScaleOf: (_) => 2,
      decimalPrecisionOf: (_) => 12,
      runtimeColumnIdOf: (_) => runtimeColumnId,
    );

    expect(
      codec.formatDisplayValue(
        column,
        1234.56,
        runtimeColumnId: runtimeColumnId,
      ),
      '1.234,56',
    );
    expect(
      codec.parseValue(column, '1.234,56', runtimeColumnId: runtimeColumnId),
      '1234.56'.decimalScale(2),
    );
    expect(
      codec.formatDisplayValue(
        column,
        '1234.56',
        runtimeColumnId: runtimeColumnId,
      ),
      '1.234,56',
    );
  });

  test(
    'numeric column affixes stay out of generated header filter options',
    () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'quantity')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'quantity': 5},
            {'quantity': 8},
          ],
        ),
      );
      unawaited(dataSet.open());

      const column = FdcIntegerColumn<dynamic>(
        fieldName: 'quantity',
        prefixText: '~',
        suffixText: ' pcs',
      );
      const runtimeColumnId = FdcColumnIdentity(1);
      final resolver = FdcHeaderFilterOptionsResolver(
        dataSet: dataSet,
        formatSettings: const FdcFormatSettings(),
        runtimeColumnIdOf: (_) => runtimeColumnId,
        decimalScaleOf: (_) => null,
        decimalPrecisionOf: (_) => null,
      );

      final labels = resolver.resolve(column).map((option) => option.label);

      expect(labels, containsAll(<String>['5', '8']));
      expect(labels, isNot(contains('~5 pcs')));
      expect(labels, isNot(contains('~8 pcs')));
    },
  );

  testWidgets('integer column affixes stay out of the in-place editor', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'quantity')],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'quantity': 5},
        ],
      ),
    );
    dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              columns: const <FdcGridColumn<dynamic>>[
                FdcIntegerColumn<dynamic>(
                  fieldName: 'quantity',
                  prefixText: '~',
                  suffixText: ' pcs',
                ),
              ],
              toolbar: const FdcGridToolbar(visible: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('~5 pcs'), findsOneWidget);

    await tester.tap(find.text('~5 pcs'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();

    final editableText = tester.widget<EditableText>(
      find.byType(EditableText).last,
    );
    expect(editableText.controller.text, '5');
  });
  test('header filter codec parses date-like text to typed values', () {
    const runtimeColumnId = FdcColumnIdentity(1);
    final codec = FdcHeaderFilterValueCodec(
      formatSettings: const FdcFormatSettings(
        dateFormat: 'dd/MM/yyyy',
        dateTimeFormat: 'dd/MM/yyyy HH:mm',
      ),
      dataTypeOf: (column) => column.dataType,
      decimalScaleOf: (_) => null,
      decimalPrecisionOf: (_) => null,
      runtimeColumnIdOf: (_) => runtimeColumnId,
    );

    const dateColumn = FdcDateColumn<dynamic>(fieldName: 'created_at');
    const dateTimeColumn = FdcDateTimeColumn<dynamic>(fieldName: 'updated_at');
    const timeColumn = FdcTimeColumn<dynamic>(fieldName: 'opened_at');

    expect(
      codec.parseValue(
        dateColumn,
        '29/12/2027',
        runtimeColumnId: runtimeColumnId,
      ),
      DateTime(2027, 12, 29),
    );
    expect(
      codec.parseValue(
        dateTimeColumn,
        '31/12/2029 14:30',
        runtimeColumnId: runtimeColumnId,
      ),
      DateTime(2029, 12, 31, 14, 30),
    );
    expect(
      codec.parseValue(
        dateTimeColumn,
        '31/12/2029',
        runtimeColumnId: runtimeColumnId,
      ),
      DateTime(2029, 12, 31),
    );
    expect(codec.isTextReadyToApply(dateTimeColumn, '31/12/2029'), isTrue);
    expect(
      codec.parseValue(timeColumn, '08:45', runtimeColumnId: runtimeColumnId),
      FdcTime(hour: 8, minute: 45),
    );
  });
}
