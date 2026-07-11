import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FdcDataSet createDataSet({IFdcDataAdapter? adapter}) {
    return FdcDataSet(
      fields: const [
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],

      adapter:
          adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );
  }

  List<FdcDataSetWorkPhase> collectPhases(FdcDataSet dataSet) {
    final phases = <FdcDataSetWorkPhase>[];
    dataSet.work.addListener(() {
      phases.add(dataSet.work.phase);
    });
    return phases;
  }

  test('adapter open reports load work and returns to idle', () async {
    final dataSet = createDataSet(
      adapter: FdcMemoryDataAdapter(
        rows: const [
          {'id': 1, 'name': 'Alpha'},
          {'id': 2, 'name': 'Beta'},
        ],
      ),
    );
    final phases = collectPhases(dataSet);

    await dataSet.open();

    expect(phases, contains(FdcDataSetWorkPhase.load));
    expect(phases.last, FdcDataSetWorkPhase.idle);
    expect(dataSet.work.isWorking, isFalse);
    expect(dataSet.work.progress, isNull);
  });

  test('filter controller reports filter work and returns to idle', () async {
    final dataSet = createDataSet(
      adapter: FdcMemoryDataAdapter(
        rows: const [
          {'id': 1, 'name': 'Alpha'},
          {'id': 2, 'name': 'Beta'},
        ],
      ),
    );
    await dataSet.open();
    final phases = collectPhases(dataSet);

    await dataSet.filter.where('name').contains('Al').apply();

    expect(phases, contains(FdcDataSetWorkPhase.filter));
    expect(phases.last, FdcDataSetWorkPhase.idle);
    expect(dataSet.work.isWorking, isFalse);
    expect(dataSet.recordCount, 1);
  });

  test('sort controller reports sort work and returns to idle', () async {
    final dataSet = createDataSet(
      adapter: FdcMemoryDataAdapter(
        rows: const [
          {'id': 2, 'name': 'Beta'},
          {'id': 1, 'name': 'Alpha'},
        ],
      ),
    );
    await dataSet.open();
    final phases = collectPhases(dataSet);

    await dataSet.sort.set(const [FdcDataSetSort(fieldName: 'id')]);

    expect(phases, contains(FdcDataSetWorkPhase.sort));
    expect(phases.last, FdcDataSetWorkPhase.idle);
    expect(dataSet.work.isWorking, isFalse);
    expect(dataSet['id'], 1);
  });
}
