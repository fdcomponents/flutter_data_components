import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'decimal min/max validation compares decimal values without toNum precision loss',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(
            name: 'amount',
            precision: 18,
            scale: 2,
            maxValue: 9007199254740992,
          ),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'amount': '9007199254740992.01'},
          ],
        ),
      );
      await dataSet.open();

      final errors = dataSet.validateFieldValue(
        'amount',
        dataSet.fieldByName('amount').value,
      );

      expect(errors, hasLength(1));
      expect(errors.single.code, FdcValidationCodes.maxValue);
    },
  );

  test(
    'decimal min validation compares normalized decimal values exactly',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(
            name: 'rate',
            precision: 6,
            scale: 4,
            minValue: 0.0002,
          ),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'rate': '0.0001'},
          ],
        ),
      );
      await dataSet.open();

      final errors = dataSet.validateFieldValue(
        'rate',
        dataSet.fieldByName('rate').value,
      );

      expect(errors, hasLength(1));
      expect(errors.single.code, FdcValidationCodes.minValue);
    },
  );
}
