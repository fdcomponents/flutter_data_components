import 'dart:async';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 2, 'name': 'Beta'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('id', 3);
  dataSet.setFieldValue('name', 'First insert');
  dataSet.post();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 3);
  assert(dataSet.changeSet.inserts.length == 1);

  dataSet.append();
  dataSet.setFieldValue('id', 4);
  dataSet.setFieldValue('name', 'Second append');

  // Force a view rebuild while still in append/insert mode. The dataset current
  // record must remain the active edit-buffer record, not whatever row happens
  // to be at the current visible index after sort/filter rebuilds.
  unawaited(
    dataSet.sort.set(const <FdcDataSetSort>[
      FdcDataSetSort(fieldName: 'name', sortType: FdcSortType.descending),
    ]),
  );

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 4);
  assert(dataSet.changeSet.inserts.length == 2);

  final ids = <Object?>[
    for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++)
      FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'id'),
  ];

  assert(ids.contains(1));
  assert(ids.contains(2));
  assert(ids.contains(3));
  assert(ids.contains(4));
}
