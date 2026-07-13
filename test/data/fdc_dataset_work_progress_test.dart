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

    expect(
      phases,
      const <FdcDataSetWorkPhase>[
        FdcDataSetWorkPhase.load,
        FdcDataSetWorkPhase.idle,
      ],
      reason:
          'Opening the adapter must publish one load transition followed by idle.',
    );
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

    expect(
      phases,
      const <FdcDataSetWorkPhase>[
        FdcDataSetWorkPhase.filter,
        FdcDataSetWorkPhase.idle,
      ],
      reason:
          'Applying one filter must publish one filter transition followed by idle.',
    );
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

    expect(
      phases,
      const <FdcDataSetWorkPhase>[
        FdcDataSetWorkPhase.sort,
        FdcDataSetWorkPhase.idle,
      ],
      reason:
          'Applying one sort must publish one sort transition followed by idle.',
    );
    expect(dataSet.work.isWorking, isFalse);
    expect(dataSet['id'], 1);
  });
}
