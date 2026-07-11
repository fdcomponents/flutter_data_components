import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<FdcDataSet> createDataSet() async {
    final dataSet = FdcDataSet(
      fields: const [
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: [
          for (var i = 0; i < 20000; i++)
            {'id': i, 'name': i.isEven ? 'Even $i' : 'Odd $i'},
        ],
      ),
    );
    await dataSet.open();
    return dataSet;
  }

  test('filter set reports filter work and returns to idle', () async {
    final source = await createDataSet();
    final phases = <FdcDataSetWorkPhase>[];
    final started = <FdcDataSetWorkInfo>[];
    final completed = <FdcDataSetWorkInfo>[];
    final dataSet = FdcDataSet(
      fields: source.fields,
      onWorkStarted: (_, work) => started.add(work),
      onWorkCompleted: (_, work) => completed.add(work),

      adapter: FdcMemoryDataAdapter(rows: source.toMaps()),
    )..open();

    dataSet.work.addListener(() {
      phases.add(dataSet.work.phase);
    });

    final applied = await dataSet.filter.set(const [
      FdcDataSetFilter(
        fieldName: 'name',
        operator: FdcFilterOperator.contains,
        value: 'Even',
      ),
    ]);

    expect(applied, isTrue);
    expect(phases, contains(FdcDataSetWorkPhase.filter));
    expect(phases.last, FdcDataSetWorkPhase.idle);
    expect(
      started.map((work) => work.phase),
      contains(FdcDataSetWorkPhase.filter),
    );
    expect(
      completed.map((work) => work.phase),
      contains(FdcDataSetWorkPhase.filter),
    );
    expect(dataSet.work.isWorking, isFalse);
    expect(dataSet.recordCount, 10000);
  });

  test('sort set reports sort work and sorts rows', () async {
    final dataSet = await createDataSet();
    final phases = <FdcDataSetWorkPhase>[];

    dataSet.work.addListener(() {
      phases.add(dataSet.work.phase);
    });

    final applied = await dataSet.sort.set(const [
      FdcDataSetSort(fieldName: 'id', sortType: FdcSortType.descending),
    ]);

    expect(applied, isTrue);
    expect(phases, contains(FdcDataSetWorkPhase.sort));
    expect(phases.last, FdcDataSetWorkPhase.idle);
    expect(dataSet['id'], 19999);
  });

  test(
    'sort set keeps published recordCount stable while rebuilding',
    () async {
      final dataSet = await createDataSet();
      final observedCounts = <int>[];

      dataSet.work.addListener(() {
        if (dataSet.work.isWorking) {
          observedCounts.add(dataSet.recordCount);
        }
      });

      final applied = await dataSet.sort.set(const [
        FdcDataSetSort(fieldName: 'id', sortType: FdcSortType.descending),
      ]);

      expect(applied, isTrue);
      expect(observedCounts, isNotEmpty);
      expect(observedCounts.toSet(), {20000});
      expect(dataSet.recordCount, 20000);
      expect(dataSet['id'], 19999);
    },
  );

  test('sort set starts as indeterminate work before sorting rows', () async {
    final dataSet = await createDataSet();
    final sortProgressValues = <double?>[];

    dataSet.work.addListener(() {
      if (dataSet.work.isWorking &&
          dataSet.work.phase == FdcDataSetWorkPhase.sort) {
        sortProgressValues.add(dataSet.work.progress);
      }
    });

    final applied = await dataSet.sort.set(const [
      FdcDataSetSort(fieldName: 'id', sortType: FdcSortType.descending),
    ]);

    expect(applied, isTrue);
    expect(sortProgressValues, isNotEmpty);
    expect(sortProgressValues.first, isNull);
    expect(dataSet['id'], 19999);
  });

  test(
    'filter clear starts as indeterminate work before rebuilding rows',
    () async {
      final dataSet = await createDataSet();
      dataSet.filter.set(const [
        FdcDataSetFilter(
          fieldName: 'name',
          operator: FdcFilterOperator.contains,
          value: 'Even',
        ),
      ]);
      expect(dataSet.recordCount, 10000);

      final filterProgressValues = <double?>[];
      dataSet.work.addListener(() {
        if (dataSet.work.isWorking &&
            dataSet.work.phase == FdcDataSetWorkPhase.filter) {
          filterProgressValues.add(dataSet.work.progress);
        }
      });

      final applied = await dataSet.filter.clear();

      expect(applied, isTrue);
      expect(filterProgressValues, isNotEmpty);
      expect(filterProgressValues.first, isNull);
      expect(dataSet.recordCount, 20000);
    },
  );

  test('search reports search work with initial progress', () async {
    final dataSet = await createDataSet();
    final started = <FdcDataSetWorkInfo>[];

    final observed = FdcDataSet(
      fields: dataSet.fields,
      onWorkStarted: (_, work) => started.add(work),

      adapter: FdcMemoryDataAdapter(rows: dataSet.toMaps()),
    )..open();

    await observed.search.apply('20');

    expect(
      started.map((work) => work.phase),
      contains(FdcDataSetWorkPhase.search),
    );
    expect(started.last.mode, FdcDataSetWorkMode.determinate);
    expect(observed.work.isWorking, isFalse);
  });
}
