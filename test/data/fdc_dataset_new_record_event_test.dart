import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onNewRecord fires after append creates active insert buffer', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(size: 255, name: 'name'),
        FdcStringField(size: 255, name: 'status'),
      ],
      onNewRecord: (dataSet) {
        eventLog.add('new:${dataSet.state.name}');
        expect(dataSet.state, FdcDataSetState.insert);

        dataSet.setFieldValue('id', 100);
        dataSet.setFieldValue('name', 'New customer');
        dataSet.setFieldValue('status', 'draft');
      },

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    await dataSet.open();

    dataSet.append();

    expect(eventLog, <String>['new:insert']);
    expect(dataSet.state, FdcDataSetState.insert);
    expect(dataSet.fieldValue('id'), 100);
    expect(dataSet.fieldValue('name'), 'New customer');
    expect(dataSet.fieldValue('status'), 'draft');

    dataSet.post();

    expect(dataSet.state, FdcDataSetState.browse);
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id'), 100);
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'New customer');
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'status'), 'draft');
  });

  test('onNewRecord fires before afterInsert', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      beforeInsert: (dataSet) {
        eventLog.add('beforeInsert:${dataSet.state.name}');
      },
      onNewRecord: (dataSet) {
        eventLog.add('onNewRecord:${dataSet.state.name}');
        dataSet.setFieldValue('name', 'Default name');
      },
      afterInsert: (dataSet) {
        eventLog.add(
          'afterInsert:${dataSet.state.name}:${dataSet.fieldValue('name')}',
        );
      },

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    await dataSet.open();

    dataSet.append();

    expect(eventLog, <String>[
      'beforeInsert:browse',
      'onNewRecord:insert',
      'afterInsert:insert:Default name',
    ]);
  });

  test('onNewRecord supports insert before current row', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      onNewRecord: (dataSet) {
        eventLog.add('new');
        dataSet.setFieldValue('name', 'Inserted before Alpha');
      },

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
          <String, Object?>{'name': 'Beta'},
        ],
      ),
    );

    await dataSet.open();

    dataSet.first();
    dataSet.insert();

    expect(eventLog, <String>['new']);
    expect(dataSet.state, FdcDataSetState.insert);
    expect(FdcDataSetInternal.activeIndex(dataSet), 0);
    expect(dataSet.fieldValue('name'), 'Inserted before Alpha');
  });

  test(
    'onNewRecord cooperates with onFieldChanged for programmatic defaults',
    () async {
      final newRecordLog = <String>[];
      final fieldLog = <String>[];

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'qty'),
          FdcDecimalField(name: 'price', precision: 12, scale: 2),
          FdcDecimalField(name: 'total', precision: 12, scale: 2),
        ],
        onNewRecord: (dataSet) {
          newRecordLog.add('new');
          dataSet.setFieldValue('qty', 2);
          dataSet.setFieldValue('price', 10);
        },
        onFieldChanged: (dataSet, field, oldValue, newValue) {
          fieldLog.add('${field.name}:$oldValue->$newValue');
          if (field.name == 'qty' || field.name == 'price') {
            final qty = dataSet.fieldByName('qty').asInteger ?? 0;
            final price = dataSet.fieldByName('price').asNum ?? 0;
            dataSet.setFieldValue('total', qty * price);
          }
        },

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      );

      await dataSet.open();

      dataSet.append();

      expect(newRecordLog, <String>['new']);
      expect(fieldLog, <String>[
        'qty:null->2',
        'total:null->0.00',
        'price:null->10.00',
        'total:0.00->20.00',
      ]);
      expect(dataSet.fieldByName('total').asNum, 20);
    },
  );

  test('onNewRecord does not fire when beforeInsert aborts', () async {
    var fired = false;

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      beforeInsert: (dataSet) {
        throw const FdcDataSetAbortException.silent();
      },
      onNewRecord: (dataSet) {
        fired = true;
      },

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    await dataSet.open();

    dataSet.append();

    expect(fired, isFalse);
    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.recordCount, 0);
  });

  test('onNewRecord does not fire for adapter open or edit', () async {
    var count = 0;

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      onNewRecord: (dataSet) {
        count++;
      },

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    dataSet.edit();

    expect(count, 0);
    expect(dataSet.state, FdcDataSetState.edit);
  });
}
