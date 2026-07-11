import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inList filters values without requiring OR expression trees', () async {
    final dataSet = _createDataSet();
    await dataSet.open();

    await dataSet.filter.where('status').inList(const [
      'active',
      'pending',
    ]).apply();

    expect(dataSet.recordCount, 3);
    expect(dataSet.toMaps().map((row) => row['Name']).toList(), const [
      'Alpha',
      'Beta',
      'Delta',
    ]);
  });

  test('inList string comparison is case-insensitive by default', () async {
    final dataSet = _createDataSet();
    await dataSet.open();

    await dataSet.filter.where('STATUS').inList(const ['ACTIVE']).apply();

    expect(dataSet.recordCount, 2);
    expect(dataSet.toMaps().map((row) => row['Name']).toList(), const [
      'Alpha',
      'Delta',
    ]);
  });

  test('notInList excludes matching values', () async {
    final dataSet = _createDataSet();
    await dataSet.open();

    await dataSet.filter.where('status').notInList(const ['inactive']).apply();

    expect(dataSet.recordCount, 3);
    expect(dataSet.toMaps().map((row) => row['Name']).toList(), const [
      'Alpha',
      'Beta',
      'Delta',
    ]);
  });

  test(
    'empty inList matches no rows and empty notInList matches all rows',
    () async {
      final dataSet = _createDataSet();
      await dataSet.open();

      await dataSet.filter.where('status').inList(const []).apply();
      expect(dataSet.recordCount, 0);

      await dataSet.filter.where('status').notInList(const []).apply();
      expect(dataSet.recordCount, 4);
    },
  );

  test('between filters inclusive value ranges', () async {
    final dataSet = _createDataSet();
    await dataSet.open();

    await dataSet.filter.where('amount').between(10, 20).apply();

    expect(dataSet.recordCount, 3);
    expect(dataSet.toMaps().map((row) => row['Name']).toList(), const [
      'Alpha',
      'Beta',
      'Gamma',
    ]);
  });
}

FdcDataSet _createDataSet() {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(name: 'Name', size: 50),
      FdcStringField(name: 'Status', size: 20),
      FdcIntegerField(name: 'Amount'),
    ],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'Name': 'Alpha', 'Status': 'active', 'Amount': 10},
        {'Name': 'Beta', 'Status': 'pending', 'Amount': 20},
        {'Name': 'Gamma', 'Status': 'inactive', 'Amount': 15},
        {'Name': 'Delta', 'Status': 'active', 'Amount': 30},
      ],
    ),
  );
}
