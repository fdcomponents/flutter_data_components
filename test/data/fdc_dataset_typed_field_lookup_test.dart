import 'package:flutter_data_components/fdc.dart';

void main() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(name: 'name', size: 50),
      FdcDecimalField(name: 'amount', precision: 12, scale: 2),
      FdcIntegerField(name: 'quantity', minValue: 1, maxValue: 10),
      FdcBooleanField(name: 'active'),
      FdcDateField(name: 'date'),
      FdcDateTimeField(name: 'createdAt'),
      FdcTimeField(name: 'time'),
    ],

    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );

  assert(dataSet.fieldByName('name').definition is FdcStringField);
  assert(dataSet.fieldDef<FdcStringField>('name').size == 50);
  assert(dataSet.fieldDef<FdcDecimalField>('amount').precision == 12);
  assert(dataSet.fieldDef<FdcDecimalField>('amount').scale == 2);
  assert(dataSet.fieldDef<FdcIntegerField>('quantity').minValue == 1);
  assert(dataSet.fieldDef<FdcIntegerField>('quantity').maxValue == 10);
  assert(dataSet.fieldDef<FdcBooleanField>('active').name == 'active');
  assert(dataSet.fieldDef<FdcDateField>('date').name == 'date');
  assert(dataSet.fieldDef<FdcDateTimeField>('createdAt').name == 'createdAt');
  assert(dataSet.fieldDef<FdcTimeField>('time').name == 'time');
  assert(dataSet.fieldDef<FdcDecimalField>('amount').scale == 2);

  var invalidTypeThrown = false;
  try {
    dataSet.fieldDef<FdcDecimalField>('name');
    // ignore: avoid_catching_errors
  } on StateError catch (error) {
    invalidTypeThrown = true;
    assert(
      error.message ==
          'Invalid field definition type: field "name" is FdcStringField, expected FdcDecimalField.',
    );
  }

  assert(invalidTypeThrown);
}
