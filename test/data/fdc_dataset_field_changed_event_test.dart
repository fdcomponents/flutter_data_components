import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onFieldChanged fires when edit buffer field changes', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(size: 255, name: 'name'),
      ],
      onFieldChanged: (dataSet, field, oldValue, newValue) {
        eventLog.add(
          '${dataSet.fieldValue('id')}:${field.name}:$oldValue->$newValue',
        );
        expect(dataSet.state, FdcDataSetState.edit);
        expect(dataSet.fieldValue(field.name), newValue);
      },

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    dataSet.edit();
    dataSet.setFieldValue('name', 'Beta');

    expect(eventLog, <String>['1:name:Alpha->Beta']);
    expect(dataSet.fieldValue('name'), 'Beta');
    // Public dataset reads reflect the active edit buffer while editing.
    expect(dataSet.fieldValue('name'), 'Beta');
  });

  test('onFieldChanged does not fire when value is unchanged', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      onFieldChanged: (dataSet, field, oldValue, newValue) {
        eventLog.add(field.name);
      },

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    dataSet.edit();
    dataSet.setFieldValue('name', 'Alpha');

    expect(eventLog, isEmpty);
  });

  test(
    'onFieldChanged fires for calculated fields changed by edit buffer write',
    () async {
      final eventLog = <String>[];

      final dataSet = FdcDataSet(
        fields: <FdcFieldDef>[
          const FdcIntegerField(name: 'qty'),
          const FdcDecimalField(name: 'price', precision: 12, scale: 2),
          FdcDecimalField(
            name: 'total',
            precision: 12,
            scale: 2,
            calculatedValue: (context) {
              final qty = context.numValue('qty') ?? 0;
              final price = context.numValue('price') ?? 0;
              return qty * price;
            },
          ),
        ],
        onFieldChanged: (dataSet, field, oldValue, newValue) {
          eventLog.add('${field.name}:$oldValue->$newValue');
        },

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            <String, Object?>{'qty': 2, 'price': 10},
          ],
        ),
      );

      await dataSet.open();

      dataSet.edit();
      dataSet.setFieldValue('qty', 3);

      expect(eventLog, <String>['qty:2->3', 'total:20.00->30.00']);
      expect(dataSet.fieldByName('total').asNum, 30);
    },
  );

  test('onFieldChanged supports reentrant dependent field updates', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'qty'),
        FdcDecimalField(name: 'price', precision: 12, scale: 2),
        FdcDecimalField(name: 'total', precision: 12, scale: 2),
      ],
      onFieldChanged: (dataSet, field, oldValue, newValue) {
        eventLog.add('${field.name}:$oldValue->$newValue');
        if (field.name == 'qty' || field.name == 'price') {
          final qty = dataSet.fieldByName('qty').asInteger ?? 0;
          final price = dataSet.fieldByName('price').asNum ?? 0;
          dataSet.setFieldValue('total', qty * price);
        }
      },

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'qty': 2, 'price': 10, 'total': 20},
        ],
      ),
    );

    await dataSet.open();

    dataSet.edit();
    dataSet.setFieldValue('qty', 3);

    expect(eventLog, <String>['qty:2->3', 'total:20.00->30.00']);
    expect(dataSet.fieldByName('total').asNum, 30);
  });

  test('onFieldChanged fires for current-row edit lifecycle updates', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      onFieldChanged: (dataSet, field, oldValue, newValue) {
        eventLog.add(
          '${dataSet.state.name}:${field.name}:$oldValue->$newValue',
        );
      },

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    dataSet.edit();
    dataSet.setFieldValue('name', 'Beta');
    dataSet.post();

    expect(eventLog, <String>['edit:name:Alpha->Beta']);
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Beta');
  });
}
