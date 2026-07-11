import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_data_components/src/data/fdc_dataset_view_controller.dart';
import 'package:flutter_data_components/src/data/fdc_record.dart';

Future<void> main() async {
  _viewControllerPrunesRetainedIdsThatNoLongerExist();
  await _deletedRetainedInsertedRecordDoesNotSurviveSortRefresh();
}

void _viewControllerPrunesRetainedIdsThatNoLongerExist() {
  final view = FdcDataSetViewController();
  final first = FdcRecord(id: 1, values: const ['A']);
  final second = FdcRecord(id: 2, values: const ['B']);

  view.retainedVisibleRecordIds
    ..add(first.id)
    ..add(second.id)
    ..add(999);

  final removedFirstPass = view.pruneRetainedVisibleRecords(<FdcRecord>[
    first,
    second,
  ]);

  assert(removedFirstPass == 1);
  assert(view.retainedVisibleRecordIds.contains(first.id));
  assert(view.retainedVisibleRecordIds.contains(second.id));
  assert(!view.retainedVisibleRecordIds.contains(999));

  final removedSecondPass = view.pruneRetainedVisibleRecords(<FdcRecord>[
    first,
  ]);

  assert(removedSecondPass == 1);
  assert(view.retainedVisibleRecordIds.contains(first.id));
  assert(!view.retainedVisibleRecordIds.contains(second.id));
}

Future<void> _deletedRetainedInsertedRecordDoesNotSurviveSortRefresh() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Bravo', 'status': 'active'},
        {'name': 'Charlie', 'status': 'active'},
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

  dataSet.append();
  dataSet.setFieldValue('name', 'Draft');
  dataSet.setFieldValue('status', 'draft');
  dataSet.post();

  assert(dataSet.recordCount == 3);
  assert(dataSet.fieldValue('name') == 'Draft');

  // The inserted cached-update record is retained under the active filter. A
  // delete of an un-applied inserted record physically removes it from storage.
  dataSet.delete();

  assert(dataSet.recordCount == 2);

  // A later sort rebuild must not accidentally keep any stale retained id for
  // the physically removed inserted record.
  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);

  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Bravo');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name') == 'Charlie');
}
