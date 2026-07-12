import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fdc dataset sort retains filtered insert', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name'),
        FdcStringField(size: 255, name: 'status'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Bravo', 'status': 'active'},
          {'name': 'Charlie', 'status': 'active'},
          {'name': 'Zulu', 'status': 'inactive'},
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

    expect(dataSet.recordCount, 2);

    dataSet.append();
    dataSet.setFieldValue('name', 'Aardvark');
    dataSet.setFieldValue('status', 'draft');
    dataSet.post();

    expect(dataSet.recordCount, 3);
    expect(dataSet.fieldValue('name'), 'Aardvark');

    await dataSet.sort.set(const <FdcDataSetSort>[
      FdcDataSetSort(fieldName: 'name'),
    ]);

    expect(dataSet.recordCount, 3);
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Aardvark');

    await dataSet.sort.clear();

    expect(dataSet.recordCount, 3);

    // A real filter apply is still the explicit action that rebuilds membership.
    await dataSet.filter.set(const <FdcDataSetFilter>[
      FdcDataSetFilter(
        fieldName: 'status',
        operator: FdcFilterOperator.equals,
        value: 'active',
      ),
    ]);

    expect(dataSet.recordCount, 2);
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Bravo');
  });
}
