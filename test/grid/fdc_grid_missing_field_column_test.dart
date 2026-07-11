import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/managers/fdc_grid_column_manager.dart';
import 'package:flutter_data_components/src/grid/runtime/data/fdc_grid_row_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGridColumnManager missing field binding', () {
    test('throws when explicit fieldName is not found in dataset', () {
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

      expect(
        () => manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcDecimalColumn<dynamic>(
              fieldName: 'total_balance',
              label: 'Total balance',
            ),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('references unknown dataset field "total_balance"'),
          ),
        ),
      );
    });

    test(
      'allows explicit columns while adapter-backed dataset fields are pending',
      () {
        final dataSet = FdcDataSet(
          adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
        );

        final manager = FdcGridColumnManager();
        final resolved = manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        );

        expect(resolved, hasLength(2));
        expect(resolved[0].fieldName, 'id');
        expect(resolved[1].fieldName, 'name');
      },
    );

    test(
      'throws for explicit columns after an opened dataset has no fields',
      () {
        final dataSet = FdcDataSet(
          adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
        );
        unawaited(dataSet.open());

        final manager = FdcGridColumnManager();

        expect(
          () => manager.resolveColumns(
            const <FdcGridColumn<dynamic>>[
              FdcIntegerColumn<dynamic>(fieldName: 'id'),
            ],
            FdcDataSetGridRowSource(dataSet),
            dataSet,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('references unknown dataset field "id"'),
            ),
          ),
        );
      },
    );

    test('generates default columns when no columns are provided', () {
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
        const <FdcGridColumn<dynamic>>[],
        FdcDataSetGridRowSource(dataSet),
        dataSet,
      );

      expect(resolved[0], isA<FdcIntegerColumn<dynamic>>());
      expect(resolved[0].fieldName, 'id');
      expect(resolved[1], isA<FdcTextColumn<dynamic>>());
      expect(resolved[1].fieldName, 'review');
    });

    test('skips object fields when generating default columns', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcObjectField(name: 'payload'),
          FdcStringField(size: 255, name: 'review'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {
              'id': 1,
              'payload': {'kind': 'internal'},
              'review': 'OK',
            },
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

      expect(resolved, hasLength(2));
      expect(resolved[0], isA<FdcIntegerColumn<dynamic>>());
      expect(resolved[0].fieldName, 'id');
      expect(resolved[1], isA<FdcTextColumn<dynamic>>());
      expect(resolved[1].fieldName, 'review');
      expect(resolved.any((column) => column.fieldName == 'payload'), isFalse);
    });

    test('throws for explicit empty fieldName', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'review')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'review': 'OK'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();

      expect(
        () => manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[FdcTextColumn<dynamic>(fieldName: '')],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates explicit column width configuration', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'review')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'review': 'OK'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();

      expect(
        () => manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'review', minWidth: -1),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains(
              'minWidth must be a finite value greater than or equal to zero',
            ),
          ),
        ),
      );

      expect(
        () => manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'review',
              minWidth: 120,
              maxWidth: 80,
            ),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('maxWidth must be greater than or equal to minWidth'),
          ),
        ),
      );

      expect(
        () => manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'review',
              width: 50,
              minWidth: 80,
            ),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('width must be greater than or equal to minWidth'),
          ),
        ),
      );
    });

    test('validates explicit column filter popup configuration', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'review')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'review': 'OK'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();

      expect(
        () => manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'review',
              filterConfig: FdcColumnFilterConfig(comboMaxPopupItems: 0),
            ),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains(
              'filterConfig.comboMaxPopupItems must be greater than zero',
            ),
          ),
        ),
      );
    });

    test('uses dataset field metadata for generated default columns', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          FdcDateField(name: 'documentDate'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'amount': null, 'documentDate': null},
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

      expect(resolved[0], isA<FdcIntegerColumn<dynamic>>());
      expect(resolved[1], isA<FdcDecimalColumn<dynamic>>());
      expect(resolved[2], isA<FdcDateColumn<dynamic>>());
    });

    test('explicit field binding preserves core visual behavior', () {
      FdcColumnValueChangeResult<dynamic>? interceptor(
        FdcColumnValueChangingContext<dynamic> context,
      ) {
        return context.replaceValue(context.newValue);
      }

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();
      const summaryStyle = FdcGridSummaryCellStyle();
      final resolved = manager.resolveColumns(
        <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            pin: FdcGridColumnPin.startFixed,
            showIndicator: false,
            onValueChanging: interceptor,
            summary: const FdcColumnSummary(
              aggregate: FdcAggregate.sum,
              label: 'Total',
              labelVisible: false,
              labelAlignment: FdcSummaryLabelAlignment.startAligned,
              allowAggregateChange: true,
              style: summaryStyle,
            ),
          ),
        ],
        FdcDataSetGridRowSource(dataSet),
        dataSet,
      );

      final column = resolved.single;

      expect(column, isA<FdcDecimalColumn<dynamic>>());
      expect(column.fieldName, 'amount');
      expect(column.pin, FdcGridColumnPin.startFixed);
      expect(column.showIndicator, isFalse);
      expect(column.onValueChanging, same(interceptor));
      expect(column.summary.aggregate, FdcAggregate.sum);
      expect(column.summary.label, 'Total');
      expect(column.summary.labelVisible, isFalse);
      expect(
        column.summary.labelAlignment,
        FdcSummaryLabelAlignment.startAligned,
      );
      expect(column.summary.allowAggregateChange, isTrue);
      expect(column.summary.style, same(summaryStyle));
    });

    test(
      'explicit same-type binding preserves indicator and value interceptor',
      () {
        FdcColumnValueChangeResult<dynamic>? interceptor(
          FdcColumnValueChangingContext<dynamic> context,
        ) {
          return context.replaceValue(context.newValue);
        }

        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alice'},
            ],
          ),
        );
        unawaited(dataSet.open());

        final manager = FdcGridColumnManager();
        final resolved = manager.resolveColumns(
          <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'name',
              showIndicator: false,
              onValueChanging: interceptor,
              pin: FdcGridColumnPin.end,
              summary: const FdcColumnSummary(allowAggregateChange: true),
            ),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        );

        final column = resolved.single;

        expect(column, isA<FdcTextColumn<dynamic>>());
        expect(column.fieldName, 'name');
        expect(column.showIndicator, isFalse);
        expect(column.onValueChanging, same(interceptor));
        expect(column.pin, FdcGridColumnPin.end);
        expect(column.summary.allowAggregateChange, isTrue);
      },
    );

    test('throws for incompatible explicit typed columns', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alice'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();

      expect(
        () => manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'name'),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('preserves explicit UI-specialized columns over typed fields', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'completion'),
          FdcStringField(name: 'status', size: 20),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'completion': 50, 'status': 'Active'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();
      final resolved = manager.resolveColumns(
        const <FdcGridColumn<dynamic>>[
          FdcProgressColumn<dynamic>(fieldName: 'completion'),
          FdcComboColumn<dynamic>(
            fieldName: 'status',
            options: <FdcOption>[
              FdcOption(value: 'Active', label: 'Active'),
              FdcOption(value: 'Blocked', label: 'Blocked'),
            ],
          ),
        ],
        FdcDataSetGridRowSource(dataSet),
        dataSet,
      );

      expect(resolved[0], isA<FdcProgressColumn<dynamic>>());
      expect(resolved[1], isA<FdcComboColumn<dynamic>>());
    });

    test('throws for incompatible explicit UI-specialized columns', () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alice'},
          ],
        ),
      );
      unawaited(dataSet.open());

      final manager = FdcGridColumnManager();

      expect(
        () => manager.resolveColumns(
          const <FdcGridColumn<dynamic>>[
            FdcProgressColumn<dynamic>(fieldName: 'name'),
          ],
          FdcDataSetGridRowSource(dataSet),
          dataSet,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FdcDataSetGridRowSource missing field behavior', () {
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
