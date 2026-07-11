import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
      FdcDecimalField(name: 'balance', precision: 12, scale: 2),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha', 'balance': 1.0},
        {'id': 2, 'name': 'Beta', 'balance': 2.0},
        {'id': 3, 'name': 'Gamma', 'balance': 3.0},
      ],
    ),
  );

  await dataSet.open();

  assert(dataSet.bof);
  assert(!dataSet.eof);
  assert(FdcDataSetInternal.activeIndex(dataSet) == 0);
  assert(dataSet.recordNumber == 1);

  var updated = 0;
  while (!dataSet.eof) {
    dataSet.edit();
    dataSet.fieldByName('name').value = 'test';
    dataSet.fieldByName('balance').value = 10.09;
    dataSet.post();
    updated++;
    dataSet.next();
  }

  assert(updated == 3);
  assert(dataSet.eof);
  assert(FdcDataSetInternal.activeIndex(dataSet) == dataSet.recordCount - 1);
  assert(dataSet.recordNumber == dataSet.recordCount);
  assert(dataSet.fieldValue('id') == 3);

  for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++) {
    assert(
      FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'name') == 'test',
    );
    assert(
      FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'balance') ==
          '10.09'.decimalScale(2),
    );
  }

  dataSet.prior();
  assert(!dataSet.eof);
  assert(FdcDataSetInternal.activeIndex(dataSet) == 1);
  assert(dataSet.recordNumber == 2);
  assert(dataSet.fieldValue('id') == 2);
}
