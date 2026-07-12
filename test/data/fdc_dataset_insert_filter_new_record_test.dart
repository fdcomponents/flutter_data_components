import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fdc dataset insert filter new record', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name'),
        FdcStringField(size: 255, name: 'status'),
      ],
      onNewRecord: (dataSet) {
        dataSet.setFieldValue('name', 'New row');
        dataSet.setFieldValue('status', 'draft');
      },

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alpha', 'status': 'active'},
        ],
      ),
    );

    await dataSet.open();

    await dataSet.filter.set(const <FdcDataSetFilter>[
      FdcDataSetFilter(
        fieldName: 'status',
        operator: FdcFilterOperator.equals,
        value: 'active',
      ),
    ]);

    expect(dataSet.recordCount, 1);
    dataSet.append();

    expect(dataSet.state, FdcDataSetState.insert);
    expect(dataSet.recordCount, 2);
    expect(FdcDataSetInternal.activeIndex(dataSet), 1);
    expect(dataSet.fieldValue('name'), 'New row');
    expect(dataSet.fieldValue('status'), 'draft');

    dataSet.post();

    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.recordCount, 2);
    expect(FdcDataSetInternal.activeIndex(dataSet), 1);
    expect(dataSet.fieldValue('name'), 'New row');
    expect(dataSet.fieldValue('status'), 'draft');

    await dataSet.filter.set(const <FdcDataSetFilter>[
      FdcDataSetFilter(
        fieldName: 'status',
        operator: FdcFilterOperator.equals,
        value: 'active',
      ),
    ]);

    expect(dataSet.recordCount, 1);
    expect(dataSet.fieldValue('name'), 'Alpha');
  });
}
