import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/filtering/fdc_header_filter_input_behavior.dart';
import 'package:flutter_data_components/src/grid/filtering/fdc_header_filter_operator_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('range editor resolves to between', () {
    const column = FdcIntegerColumn(
      fieldName: 'value',
      filterConfig: FdcColumnFilterConfig(editor: FdcFilterEditor.range),
    );

    expect(
      FdcHeaderFilterOperatorPolicy.resolveOperator(
        column: column,
        dataType: FdcDataType.integer,
        gridTextOperator: FdcFilterOperator.equals,
      ),
      FdcFilterOperator.between,
    );
  });

  test('range value has stable equality and signature text', () {
    const left = FdcFilterRangeValue(from: '2', to: '4');
    const right = FdcFilterRangeValue(from: '2', to: '4');

    expect(left, right);
    expect(left.toString(), '2..4');
  });

  test('list editor hides equals operators even when configured', () {
    const column = FdcTextColumn(
      fieldName: 'status',
      filterConfig: FdcColumnFilterConfig(
        editor: FdcFilterEditor.list,
        operators: <FdcFilterOperator>[
          FdcFilterOperator.equals,
          FdcFilterOperator.notEquals,
          FdcFilterOperator.inList,
          FdcFilterOperator.notInList,
          FdcFilterOperator.isNull,
        ],
      ),
    );

    expect(
      FdcHeaderFilterOperatorPolicy.operatorsForColumn(
        column,
        FdcDataType.string,
      ),
      const <FdcFilterOperator>[
        FdcFilterOperator.inList,
        FdcFilterOperator.notInList,
        FdcFilterOperator.isNull,
      ],
    );
  });

  test(
    'list editor falls back when configured operators only contain equals',
    () {
      const column = FdcTextColumn(
        fieldName: 'status',
        filterConfig: FdcColumnFilterConfig(
          editor: FdcFilterEditor.list,
          operators: <FdcFilterOperator>[
            FdcFilterOperator.equals,
            FdcFilterOperator.notEquals,
          ],
        ),
      );

      expect(
        FdcHeaderFilterOperatorPolicy.operatorsForColumn(
          column,
          FdcDataType.string,
        ),
        const <FdcFilterOperator>[
          FdcFilterOperator.inList,
          FdcFilterOperator.notInList,
          FdcFilterOperator.isNull,
          FdcFilterOperator.isNotNull,
        ],
      );
    },
  );

  test('adapter-backed operators hide local-only filter operators', () {
    const textColumn = FdcTextColumn(fieldName: 'name');

    expect(
      FdcHeaderFilterOperatorPolicy.operatorsForColumn(
        textColumn,
        FdcDataType.string,
        adapterBacked: true,
      ),
      isNot(contains(FdcFilterOperator.notContains)),
    );

    const rangeColumn = FdcIntegerColumn(
      fieldName: 'amount',
      filterConfig: FdcColumnFilterConfig(editor: FdcFilterEditor.range),
    );

    expect(
      FdcHeaderFilterOperatorPolicy.operatorsForColumn(
        rangeColumn,
        FdcDataType.integer,
        adapterBacked: true,
      ),
      const <FdcFilterOperator>[
        FdcFilterOperator.between,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ],
    );
    expect(
      FdcHeaderFilterOperatorPolicy.resolveOperator(
        column: rangeColumn,
        dataType: FdcDataType.integer,
        gridTextOperator: FdcFilterOperator.equals,
        adapterBacked: true,
      ),
      FdcFilterOperator.between,
    );
  });

  test('adapter-backed custom local-only operators fall back safely', () {
    const column = FdcTextColumn(
      fieldName: 'name',
      filterConfig: FdcColumnFilterConfig(
        operators: <FdcFilterOperator>[FdcFilterOperator.notContains],
        defaultOperator: FdcFilterOperator.notContains,
      ),
    );

    final operators = FdcHeaderFilterOperatorPolicy.operatorsForColumn(
      column,
      FdcDataType.string,
      adapterBacked: true,
    );

    expect(operators, isNotEmpty);
    expect(operators, isNot(contains(FdcFilterOperator.notContains)));
    expect(operators, contains(FdcFilterOperator.contains));
    expect(
      FdcHeaderFilterOperatorPolicy.resolveOperator(
        column: column,
        dataType: FdcDataType.string,
        gridTextOperator: FdcFilterOperator.contains,
        adapterBacked: true,
      ),
      FdcFilterOperator.contains,
    );
  });

  test('header filter input behavior centralizes focusability rules', () {
    const listColumn = FdcTextColumn(
      fieldName: 'status',
      filterConfig: FdcColumnFilterConfig(editor: FdcFilterEditor.list),
    );
    final listBehavior = FdcHeaderFilterInputBehavior.resolve(
      column: listColumn,
      dataType: FdcDataType.string,
      operator: FdcFilterOperator.inList,
      canOpenFilterMenu: true,
    );

    expect(listBehavior.isMenuOnly, isTrue);
    expect(listBehavior.hasFocusableInput, isFalse);

    const booleanSearchColumn = FdcBooleanColumn(fieldName: 'active');
    final booleanSearchBehavior = FdcHeaderFilterInputBehavior.resolve(
      column: booleanSearchColumn,
      dataType: FdcDataType.boolean,
      operator: FdcFilterOperator.equals,
      canOpenFilterMenu: true,
    );

    expect(booleanSearchBehavior.hasFocusableInput, isFalse);
    expect(booleanSearchBehavior.acceptsTextInput, isFalse);

    const textColumn = FdcTextColumn(fieldName: 'name');
    final nullOperatorBehavior = FdcHeaderFilterInputBehavior.resolve(
      column: textColumn,
      dataType: FdcDataType.string,
      operator: FdcFilterOperator.isNull,
      canOpenFilterMenu: true,
    );

    expect(nullOperatorBehavior.operatorDisplayOnly, isTrue);
    expect(nullOperatorBehavior.hasFocusableInput, isFalse);

    final textBehavior = FdcHeaderFilterInputBehavior.resolve(
      column: textColumn,
      dataType: FdcDataType.string,
      operator: FdcFilterOperator.contains,
      canOpenFilterMenu: true,
    );

    expect(textBehavior.acceptsTextInput, isTrue);
    expect(textBehavior.hasFocusableInput, isTrue);
  });
}
