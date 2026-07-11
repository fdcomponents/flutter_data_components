import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'bound text edit renders empty disabled editor without current record',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'name', label: 'Name', size: 20),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
        isFalse,
      );
    },
  );

  testWidgets('bound checkbox renders disabled without current record', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(name: 'active', label: 'Active'),
      ],

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcBooleanEdit(dataSet: dataSet, fieldName: 'active'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
  });

  testWidgets('bound combo renders disabled without current record', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'status', label: 'Status', size: 20),
      ],

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcComboEdit<String>(
            dataSet: dataSet,
            fieldName: 'status',
            options: const <FdcOption<String>>[
              FdcOption<String>(value: 'open', label: 'Open'),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
