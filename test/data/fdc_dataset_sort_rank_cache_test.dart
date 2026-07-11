import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset_view_controller.dart';
import 'package:flutter_data_components/src/data/fdc_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sort rank cache is reused when filtering an already sorted view', () {
    final view = FdcDataSetViewController();
    const fields = <FdcFieldDef>[
      FdcStringField(name: 'name', size: 50),
      FdcStringField(name: 'status', size: 20),
    ];
    const fieldIndexByName = <String, int>{'name': 0, 'status': 1};
    final records = <FdcRecord>[
      FdcRecord(id: 1, values: const <Object?>['Charlie', 'active']),
      FdcRecord(id: 2, values: const <Object?>['Alpha', 'inactive']),
      FdcRecord(id: 3, values: const <Object?>['Bravo', 'active']),
    ];

    view.sorts.add(const FdcDataSetSort(fieldName: 'name'));

    view.rebuildView(
      records: records,
      fields: fields,
      fieldIndexByName: fieldIndexByName,
      currentIndex: -1,
      preserveRecordId: null,
      mustKeepRecordInView: (_) => false,
    );

    expect(view.sortRankCache.length, 1);
    final cachedRanks = view.sortRankCache.values.single;
    expect(view.viewIndexes, const <int>[1, 2, 0]);

    view.filters.add(
      const FdcDataSetFilter(
        fieldName: 'status',
        operator: FdcFilterOperator.equals,
        value: 'active',
      ),
    );

    view.rebuildView(
      records: records,
      fields: fields,
      fieldIndexByName: fieldIndexByName,
      currentIndex: -1,
      preserveRecordId: null,
      mustKeepRecordInView: (_) => false,
    );

    expect(view.sortRankCache.values.single, same(cachedRanks));
    expect(view.viewIndexes, const <int>[2, 0]);
  });

  test('sort rank cache is invalidated for changed fields', () {
    final view = FdcDataSetViewController();
    const fields = <FdcFieldDef>[FdcStringField(name: 'name', size: 50)];
    final records = <FdcRecord>[
      FdcRecord(id: 1, values: const <Object?>['Charlie']),
      FdcRecord(id: 2, values: const <Object?>['Alpha']),
    ];

    view.sorts.add(const FdcDataSetSort(fieldName: 'name'));
    view.rebuildView(
      records: records,
      fields: fields,
      fieldIndexByName: const <String, int>{'name': 0},
      currentIndex: -1,
      preserveRecordId: null,
      mustKeepRecordInView: (_) => false,
    );

    expect(view.sortRankCache, isNotEmpty);

    view.invalidateComparableCacheForField(0);

    expect(view.sortRankCache, isEmpty);
  });
}
