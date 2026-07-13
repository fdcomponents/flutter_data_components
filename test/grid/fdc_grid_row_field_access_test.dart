import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/managers/fdc_grid_column_manager.dart';
import 'package:flutter_data_components/src/grid/runtime/data/fdc_grid_row_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGrid row field access contract', () {
    test(
      'unknown explicit field fails fast and is not reported as present',
      () {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 255, name: 'review'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'review': 'Review value'},
            ],
          ),
        );
        unawaited(dataSet.open());

        final source = FdcDataSetGridRowSource(dataSet);
        final row = source[0];

        expect(
          () => source.valueAt(0, 'total_balance'),
          throwsA(isA<ArgumentError>()),
        );
        expect(row.containsField('total_balance'), isFalse);
        expect(() => row['total_balance'], throwsA(isA<ArgumentError>()));
        expect(row['review'], 'Review value');
      },
    );

    test('dataset row containsField uses case-insensitive field names', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'Name': 'Alice'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final row = FdcDataSetGridRowSource(dataSet)[0];

      expect(row.containsField('Name'), isTrue);
      expect(row.containsField('name'), isTrue);
      expect(row.containsField('NAME'), isTrue);
      expect(row.valueOf('name'), 'Alice');
      expect(row['NAME'], 'Alice');
      expect(() => row.valueOf('missing'), throwsA(isA<ArgumentError>()));
    });

    test('transient row containsField uses case-insensitive field names', () {
      final row = FdcGridTransientRow(
        rowIndex: 0,
        fieldNames: const <String>['id', 'Name'],
        valueResolver: (fieldName) {
          switch (fieldName) {
            case 'id':
              return 1;
            case 'Name':
              return 'Alice';
          }
          return null;
        },
      );

      expect(row.containsField('Name'), isTrue);
      expect(row.containsField('name'), isTrue);
      expect(row.containsField('NAME'), isTrue);
      expect(row.valueOf('name'), 'Alice');
      expect(row['NAME'], 'Alice');
    });

    test('field context typed accessors offer strict and safe variants', () {
      final context = FdcFieldContext<String>(
        column: FdcCustomColumn<String>(
          fieldName: 'status',
          cellBuilder: (field, cell) => const SizedBox.shrink(),
        ),
        rowIndex: 0,
        columnIndex: 1,
        value: 'Active',
        fieldExists: (fieldName) =>
            const <String>{'name', 'age'}.contains(fieldName),
        fieldValueResolver: (fieldName) {
          switch (fieldName) {
            case 'name':
              return 'Alice';
            case 'age':
              return 42;
          }
          return null;
        },
        fieldValueWriter: (fieldName, value) => true,
        fieldValueFormatter: (fieldName, value) => value?.toString() ?? '',
      );

      expect(context.valueOf<String>('name'), 'Alice');
      expect(context.tryValueOf<String>('name'), 'Alice');
      expect(context.tryValueOf<int>('name'), isNull);
      expect(() => context.valueOf<int>('name'), throwsA(isA<TypeError>()));
      expect(context.tryValueOf<String>('missing'), isNull);
      expect(
        () => context.valueOf<String>('missing'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => context.setValueOf<String>('missing', 'x'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'value changing context typed accessors offer strict and safe variants',
      () {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(name: 'name', size: 50),
            FdcIntegerField(name: 'age'),
            FdcStringField(name: 'status', size: 50),
          ],

          adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
        );
        final row = FdcGridTransientRow(
          rowIndex: 0,
          fieldNames: const <String>['name', 'age'],
          valueResolver: (fieldName) {
            switch (fieldName) {
              case 'name':
                return 'Alice';
              case 'age':
                return 42;
            }
            return null;
          },
        );
        final context = FdcColumnValueChangingContext<String>(
          dataSet: dataSet,
          column: const FdcTextColumn<String>(fieldName: 'status'),
          row: row,
          rowIndex: 0,
          columnIndex: 1,
          fieldName: 'status',
          oldValue: 'Active',
          newValue: 'Blocked',
        );

        expect(context.valueOf<String>('name'), 'Alice');
        expect(context.tryValueOf<String>('name'), 'Alice');
        expect(context.tryValueOf<int>('name'), isNull);
        expect(() => context.valueOf<int>('name'), throwsA(isA<TypeError>()));
        expect(context.tryValueOf<String>('missing'), isNull);
        expect(
          () => context.valueOf<String>('missing'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => context.setValueOf<String>('missing', 'x'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('binds GUID fields through text columns', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcGuidField(name: 'guid')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'guid': 'a0ebd67f-6f77-4a8e-9f41-b04d08764f01'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();
      final resolved = manager.resolveColumns(
        const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'guid'),
        ],
        FdcDataSetGridRowSource(dataSet),
        dataSet,
      );

      expect(resolved.single, isA<FdcTextColumn<dynamic>>());
      expect(resolved.single.fieldName, 'guid');
      expect(() => resolved.single.validateBinding(dataSet), returnsNormally);
    });

    test('action columns do not require a dataset field binding', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'review'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'review': 'OK'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();
      final resolved = manager.resolveColumns(
        const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcActionColumn(actions: [FdcRowAction.delete()]),
        ],
        FdcDataSetGridRowSource(dataSet),
        dataSet,
      );

      expect(resolved[1], isA<FdcActionColumn>());
      expect(resolved[1].isDataBound, isFalse);
      expect(resolved[1].allowSort, isFalse);
      expect(resolved[1].filterEnabled, isFalse);
    });

    test('delete row action uses a destructive default color', () {
      const action = FdcRowAction.delete();

      expect(action.color, const Color(0xFFD32F2F));
    });

    test('auto-generates GUID fields as text columns', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcGuidField(name: 'guid')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'guid': 'a0ebd67f-6f77-4a8e-9f41-b04d08764f01'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();
      final resolved = manager.resolveColumns(
        const <FdcGridColumn<dynamic>>[],
        FdcDataSetGridRowSource(dataSet),
        dataSet,
      );

      expect(resolved.single, isA<FdcTextColumn<dynamic>>());
      expect(resolved.single.fieldName, 'guid');
    });
  });
}
