import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadRows opens an adapter-less local dataset', () async {
    final dataSet = _createLocalDataSet();

    await dataSet.loadRows(<Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'Alpha'},
      <String, Object?>{'id': 2, 'name': 'Beta'},
    ]);

    expect(dataSet.isLocal, isTrue);
    expect(dataSet.isOpen, isTrue);
    expect(dataSet.recordCount, 2);
    expect(dataSet['name'], 'Alpha');
  });

  test('loadRows awaits future rows before opening a local dataset', () async {
    final dataSet = _createLocalDataSet();

    await dataSet.loadRows(
      Future<List<Map<String, Object?>>>.value(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ]),
    );

    expect(dataSet.isLocal, isTrue);
    expect(dataSet.isOpen, isTrue);
    expect(dataSet.recordCount, 1);
    expect(dataSet['name'], 'Alpha');
  });

  test(
    'local dataset posts changes immediately even with cached update mode',
    () async {
      final dataSet = _createLocalDataSet(
        updateMode: FdcUpdateMode.cachedUpdates,
      );
      await dataSet.loadRows(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ]);

      dataSet.edit();
      dataSet['name'] = 'Beta';
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet['name'], 'Beta');
      expect(dataSet.hasUpdates, isFalse);
    },
  );

  test(
    'local dataset deletes immediately even with cached update mode',
    () async {
      final dataSet = _createLocalDataSet(
        updateMode: FdcUpdateMode.cachedUpdates,
      );
      await dataSet.loadRows(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
        <String, Object?>{'id': 2, 'name': 'Beta'},
      ]);

      dataSet.delete();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(dataSet['name'], 'Beta');
      expect(dataSet.hasUpdates, isFalse);
    },
  );

  test('adapter-backed dataset rejects loadRows APIs', () async {
    final dataSet = FdcDataSet(
      fields: _fields,
      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    expect(
      () => dataSet.loadRows(const <Map<String, Object?>>[]),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      dataSet.loadRows(
        Future<List<Map<String, Object?>>>.value(
          const <Map<String, Object?>>[],
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('local dataset rejects adapter open APIs', () async {
    final dataSet = _createLocalDataSet();

    await expectLater(dataSet.open(), throwsA(isA<StateError>()));
  });
}

const _fields = <FdcFieldDef>[
  FdcIntegerField(name: 'id', isKey: true),
  FdcStringField(name: 'name', size: 50),
];

FdcDataSet _createLocalDataSet({
  FdcUpdateMode updateMode = FdcUpdateMode.immediate,
}) {
  return FdcDataSet(fields: _fields, updateMode: updateMode);
}
