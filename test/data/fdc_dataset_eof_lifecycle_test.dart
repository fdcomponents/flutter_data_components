import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1},
        {'id': 2},
      ],
    ),
  );

  assert(dataSet.eof);
  assert(dataSet.recordNumber == -1);

  await dataSet.open();

  assert(!dataSet.eof);
  assert(dataSet.recordNumber == 1);

  dataSet.next();
  assert(!dataSet.eof);
  assert(dataSet.recordNumber == 2);

  dataSet.next();
  assert(dataSet.eof);
  assert(dataSet.recordNumber == 2);
  assert(dataSet.fieldValue('id') == 2);

  dataSet.first();
  assert(!dataSet.eof);
  assert(dataSet.recordNumber == 1);

  dataSet.last();
  assert(dataSet.eof);
  assert(dataSet.recordNumber == 2);
  assert(dataSet.fieldValue('id') == 2);

  dataSet.moveToRecord(2);
  assert(dataSet.recordNumber == 2);
  assert(dataSet.eof);

  dataSet.moveToRecord(1);
  assert(dataSet.recordNumber == 1);
  assert(!dataSet.eof);

  var rangeErrorThrown = false;
  try {
    dataSet.moveToRecord(50);
    // ignore: avoid_catching_errors
  } on RangeError {
    rangeErrorThrown = true;
  }
  assert(rangeErrorThrown);

  dataSet.first();
  assert(!dataSet.eof);
  assert(dataSet.recordNumber == 1);

  dataSet.close();
  assert(dataSet.eof);
  assert(dataSet.recordNumber == -1);

  var priorClosedErrorThrown = false;
  try {
    dataSet.prior();
    // ignore: avoid_catching_errors
  } on StateError {
    priorClosedErrorThrown = true;
  }
  assert(priorClosedErrorThrown);

  var nextClosedErrorThrown = false;
  try {
    dataSet.next();
    // ignore: avoid_catching_errors
  } on StateError {
    nextClosedErrorThrown = true;
  }
  assert(nextClosedErrorThrown);

  (dataSet.adapter as FdcMemoryDataAdapter).replaceRows(
    const <Map<String, Object?>>[],
  );
  await dataSet.open();
  assert(dataSet.bof);
  assert(dataSet.eof);
  assert(dataSet.recordNumber == -1);
}
