import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FdcDataSet dataSet;

  setUp(() async {
    dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'name', size: 255),
        FdcIntegerField(name: 'age'),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alice', 'age': 42},
        ],
      ),
    );
    await dataSet.open();
  });

  test('focus event field access is strict except tryValueOf', () {
    final context = FdcFieldFocusContext<String>(
      dataSet: dataSet,
      host: FdcFieldEventHost.grid,
      fieldName: 'name',
      valueOf: (fieldName) => dataSet.fieldValue(fieldName),
    );

    expect(context.valueOf<String>('name'), 'Alice');
    expect(context.tryValueOf<String>('missing'), isNull);
    expect(
      () => context.valueOf<String>('missing'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('value changing event getters and setter reject unknown fields', () {
    final context = FdcFieldValueChangingContext<String>(
      dataSet: dataSet,
      host: FdcFieldEventHost.grid,
      fieldName: 'name',
      rowIndex: 0,
      oldValue: 'Alice',
      newValue: 'Megan',
      valueOf: (fieldName) => dataSet.fieldValue(fieldName),
    );

    expect(context.valueOf<int>('age'), 42);
    expect(context.tryValueOf<String>('missing'), isNull);
    expect(
      () => context.valueOf<String>('missing'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => context.setValueOf<String>('missing', 'x'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('value changed event field access is strict except tryValueOf', () {
    final context = FdcFieldValueChangedContext<String>(
      dataSet: dataSet,
      host: FdcFieldEventHost.grid,
      fieldName: 'name',
      rowIndex: 0,
      oldValue: 'Alice',
      value: 'Megan',
      valueOf: (fieldName) => dataSet.fieldValue(fieldName),
    );

    expect(context.valueOf<int>('age'), 42);
    expect(context.tryValueOf<String>('missing'), isNull);
    expect(
      () => context.valueOf<String>('missing'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
