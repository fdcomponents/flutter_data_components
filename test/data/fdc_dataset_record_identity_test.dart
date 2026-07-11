import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'internal record ids stay attached across sort and filter view rebuilds',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 32, name: 'name'),
          FdcStringField(size: 32, name: 'status'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha', 'status': 'low'},
            {'id': 2, 'name': 'Beta', 'status': 'high'},
            {'id': 3, 'name': 'Gamma', 'status': 'low'},
          ],
        ),
      );

      await dataSet.open();

      final alphaRecordId = _recordIdForName(dataSet, 'Alpha');
      final betaRecordId = _recordIdForName(dataSet, 'Beta');
      final gammaRecordId = _recordIdForName(dataSet, 'Gamma');

      expect(
        {alphaRecordId, betaRecordId, gammaRecordId}.length,
        3,
        reason: 'Each loaded record must receive a distinct runtime id.',
      );
      expect(FdcDataSetInternal.allRecordIds(dataSet), hasLength(3));

      await dataSet.sort.set(const <FdcDataSetSort>[
        FdcDataSetSort(fieldName: 'name', sortType: FdcSortType.descending),
      ]);

      expect(_recordIdForName(dataSet, 'Alpha'), alphaRecordId);
      expect(_recordIdForName(dataSet, 'Beta'), betaRecordId);
      expect(_recordIdForName(dataSet, 'Gamma'), gammaRecordId);

      await dataSet.filter.set(const <FdcDataSetFilter>[
        FdcDataSetFilter(
          fieldName: 'status',
          operator: FdcFilterOperator.equals,
          value: 'low',
        ),
      ]);

      expect(dataSet.recordCount, 2);
      expect(_recordIdForName(dataSet, 'Alpha'), alphaRecordId);
      expect(_recordIdForName(dataSet, 'Gamma'), gammaRecordId);
      expect(
        FdcDataSetInternal.containsRecordId(dataSet, betaRecordId),
        isTrue,
      );
      expect(FdcDataSetInternal.allRecordIds(dataSet), contains(betaRecordId));

      await dataSet.filter.clear();

      expect(dataSet.recordCount, 3);
      expect(_recordIdForName(dataSet, 'Alpha'), alphaRecordId);
      expect(_recordIdForName(dataSet, 'Beta'), betaRecordId);
      expect(_recordIdForName(dataSet, 'Gamma'), gammaRecordId);
    },
  );

  test(
    'internal record selection is stored on records across sort and filter',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 32, name: 'name'),
          FdcStringField(size: 32, name: 'status'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha', 'status': 'low'},
            {'id': 2, 'name': 'Beta', 'status': 'high'},
            {'id': 3, 'name': 'Gamma', 'status': 'low'},
          ],
        ),
      );

      await dataSet.open();

      final betaRecordId = _recordIdForName(dataSet, 'Beta');
      FdcDataSetInternal.setRecordSelectedAt(dataSet, 1, true);

      expect(FdcDataSetInternal.isRecordSelectedAt(dataSet, 1), isTrue);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);

      await dataSet.sort.set(const <FdcDataSetSort>[
        FdcDataSetSort(fieldName: 'name', sortType: FdcSortType.descending),
      ]);

      final sortedBetaIndex = _rowIndexForName(dataSet, 'Beta');
      expect(
        FdcDataSetInternal.recordIdAt(dataSet, sortedBetaIndex),
        betaRecordId,
      );
      expect(
        FdcDataSetInternal.isRecordSelectedAt(dataSet, sortedBetaIndex),
        isTrue,
      );
      expect(
        FdcDataSetInternal.isRecordSelectedAt(
          dataSet,
          _rowIndexForName(dataSet, 'Gamma'),
        ),
        isFalse,
      );
      expect(
        FdcDataSetInternal.isRecordSelectedAt(
          dataSet,
          _rowIndexForName(dataSet, 'Alpha'),
        ),
        isFalse,
      );

      await dataSet.filter.set(const <FdcDataSetFilter>[
        FdcDataSetFilter(
          fieldName: 'status',
          operator: FdcFilterOperator.equals,
          value: 'low',
        ),
      ]);

      expect(dataSet.recordCount, 2);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 0);
      expect(
        FdcDataSetInternal.containsRecordId(dataSet, betaRecordId),
        isTrue,
      );

      await dataSet.filter.clear();

      expect(_recordIdForName(dataSet, 'Beta'), betaRecordId);
      final betaIndex = _rowIndexForName(dataSet, 'Beta');
      expect(FdcDataSetInternal.isRecordSelectedAt(dataSet, betaIndex), isTrue);
    },
  );

  test(
    'internal selected state is removed with deleted or cancelled records',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 32, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
            {'id': 2, 'name': 'Beta'},
          ],
        ),
      );

      await dataSet.open();

      final betaRecordId = _recordIdForName(dataSet, 'Beta');
      FdcDataSetInternal.setRecordSelectedAt(dataSet, 1, true);

      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      dataSet.moveToRecord(2);
      dataSet.delete();

      // Persistent records are marked deleted but remain in the internal store
      // until updates are applied/cancelled. Selection metadata must still be
      // cleared immediately so deleted rows do not stay selected.
      expect(
        FdcDataSetInternal.containsRecordId(dataSet, betaRecordId),
        isTrue,
      );
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 0);

      dataSet.append();
      final appendRecordId = FdcDataSetInternal.currentRecordId(dataSet);
      expect(appendRecordId, isNotNull);

      FdcDataSetInternal.setRecordSelectedAt(
        dataSet,
        FdcDataSetInternal.activeIndex(dataSet),
        true,
      );
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);

      dataSet.cancel();

      expect(
        FdcDataSetInternal.containsRecordId(dataSet, appendRecordId!),
        isFalse,
      );
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 0);
    },
  );

  test(
    'internal append record id is removed on pristine insert cancel',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 32, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );

      await dataSet.open();

      final originalIds = FdcDataSetInternal.allRecordIds(dataSet);
      expect(originalIds, hasLength(1));

      dataSet.append();

      final firstAppendRecordId = FdcDataSetInternal.currentRecordId(dataSet);
      expect(firstAppendRecordId, isNotNull);
      expect(FdcDataSetInternal.recordIdAt(dataSet, 1), firstAppendRecordId);
      expect(
        FdcDataSetInternal.containsRecordId(dataSet, firstAppendRecordId!),
        isTrue,
      );

      dataSet.cancel();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(
        FdcDataSetInternal.containsRecordId(dataSet, firstAppendRecordId),
        isFalse,
      );
      expect(FdcDataSetInternal.allRecordIds(dataSet), originalIds);

      dataSet.append();

      final secondAppendRecordId = FdcDataSetInternal.currentRecordId(dataSet);
      expect(secondAppendRecordId, isNotNull);
      expect(secondAppendRecordId, isNot(firstAppendRecordId));
    },
  );
}

int _recordIdForName(FdcDataSet dataSet, String name) {
  for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++) {
    if (FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'name') == name) {
      return FdcDataSetInternal.recordIdAt(dataSet, rowIndex);
    }
  }
  throw StateError('Record not visible: $name');
}

int _rowIndexForName(FdcDataSet dataSet, String name) {
  for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++) {
    if (FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'name') == name) {
      return rowIndex;
    }
  }
  throw StateError('Record not visible: $name');
}
