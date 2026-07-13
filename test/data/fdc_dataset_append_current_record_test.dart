import 'dart:async';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'append preserves both inserted rows across an unawaited view rebuild',
    () async {
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

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 3);
      expect(dataSet.changeSet.inserts, hasLength(1));

      dataSet.append();
      dataSet.setFieldValue('id', 4);
      dataSet.setFieldValue('name', 'Second append');

      unawaited(
        dataSet.sort.set(const <FdcDataSetSort>[
          FdcDataSetSort(fieldName: 'name', sortType: FdcSortType.descending),
        ]),
      );

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 4);
      expect(dataSet.changeSet.inserts, hasLength(2));

      final ids = <Object?>[
        for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++)
          FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'id'),
      ];

      expect(
        ids,
        unorderedEquals(<Object?>[1, 2, 3, 4]),
        reason:
            'Both original rows and both appended rows must remain present.',
      );
    },
  );
}
