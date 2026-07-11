import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

FdcDataSet _booleanDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcBooleanField(name: 'active'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'active': false},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet _lookupDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'status'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'status': 'Active', 'name': 'Alpha'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

void main() {
  testWidgets('column onValueChanged fires before grid onCellChanged', (
    tester,
  ) async {
    final dataSet = _booleanDataSet();
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                const FdcIntegerColumn<dynamic>(
                  fieldName: 'id',
                  readOnly: true,
                ),
                FdcBooleanColumn<bool>(
                  fieldName: 'active',
                  onValueChanged: (context) {
                    events.add(
                      'column:${context.rowIndex}:${context.columnIndex}:'
                      '${context.fieldName}:${context.oldValue}->'
                      '${context.value}:${(context.column as FdcGridColumn<dynamic>).fieldName}',
                    );
                  },
                ),
              ],
              onCellChanged: (context) {
                events.add(
                  'grid:${context.rowIndex}:${context.columnIndex}:'
                  '${context.fieldName}:${context.oldValue}->${context.value}',
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(events, <String>[
      'column:0:1:active:false->true:active',
      'grid:0:1:active:false->true',
    ]);
  });

  testWidgets('column onValueChanged stays scoped to the edited column', (
    tester,
  ) async {
    final dataSet = _lookupDataSet();
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 220,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
                  fieldName: 'status',
                  width: 140,
                  onValueChanging: (context) {
                    if (context.newValue == 'scan') {
                      context.setValueOf<String>('name', 'Lookup article');
                      return context.replaceValue('ART-001');
                    }
                    return context.accept();
                  },
                  onValueChanged: (context) {
                    events.add(
                      'statusChanged:${context.oldValue}->${context.value}',
                    );
                  },
                ),
                FdcTextColumn<String>(
                  fieldName: 'name',
                  width: 160,
                  onValueChanged: (context) {
                    events.add(
                      'nameChanged:${context.oldValue}->${context.value}',
                    );
                  },
                ),
                FdcCustomColumn<int>(
                  fieldName: 'id',
                  label: 'Action',
                  width: 120,
                  cellBuilder: (field, cell) {
                    return TextButton(
                      key: const ValueKey<String>('scan-status'),
                      onPressed: () =>
                          field.setValueOf<String>('status', 'scan'),
                      child: Text('${field.value ?? ''}'),
                    );
                  },
                ),
              ],
              onCellChanged: (context) {
                events.add(
                  'grid:${context.fieldName}:${context.oldValue}->${context.value}',
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('scan-status')));
    await tester.pumpAndSettle();

    expect(dataSet.fieldValue('status'), 'ART-001');
    expect(dataSet.fieldValue('name'), 'Lookup article');
    expect(events, contains('statusChanged:Active->ART-001'));
    expect(events, contains('grid:status:Active->ART-001'));
    expect(events, contains('grid:name:Alpha->Lookup article'));
    expect(events.where((event) => event.startsWith('nameChanged')), isEmpty);
  });

  testWidgets(
    'additional value result rejects unknown fields before writing anything',
    (tester) async {
      final dataSet = _lookupDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(visible: false),
                toolbar: const FdcGridToolbar(visible: false),
                columns: <FdcGridColumn<dynamic>>[
                  FdcTextColumn<String>(
                    fieldName: 'status',
                    onValueChanging: (context) {
                      return context
                          .replaceValue('Changed')
                          .withAdditionalValues(const <String, Object?>{
                            'missing_field': 'invalid',
                          });
                    },
                  ),
                  FdcCustomColumn<int>(
                    fieldName: 'id',
                    cellBuilder: (field, cell) {
                      return TextButton(
                        key: const ValueKey<String>('invalid-additional-write'),
                        onPressed: () =>
                            field.setValueOf<String>('status', 'trigger'),
                        child: const Text('Trigger'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('invalid-additional-write')),
      );
      await tester.pump();

      expect(tester.takeException(), isA<ArgumentError>());
      expect(dataSet.fieldValue('status'), 'Active');
      expect(dataSet.fieldValue('name'), 'Alpha');
    },
  );
}
