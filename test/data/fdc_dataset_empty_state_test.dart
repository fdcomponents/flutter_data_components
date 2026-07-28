import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isEmpty and isNotEmpty reflect the current dataset view', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1},
        ],
      ),
    );

    expect(dataSet.isEmpty, isTrue);
    expect(dataSet.isNotEmpty, isFalse);

    await dataSet.open();

    expect(dataSet.isEmpty, isFalse);
    expect(dataSet.isNotEmpty, isTrue);

    dataSet.close();

    expect(dataSet.isEmpty, isTrue);
    expect(dataSet.isNotEmpty, isFalse);
  });
}
