import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'dataset index operator reads current record raw field values',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcIntegerField(name: 'quantity'),
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          FdcBooleanField(name: 'active'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{
              'name': 'Alpha',
              'quantity': 3,
              'amount': 12.5,
              'active': true,
            },
          ],
        ),
      );

      await dataSet.open();

      expect(dataSet['name'], 'Alpha');
      expect(dataSet['quantity'], 3);
      expect(dataSet.fieldByName('amount').asNum, 12.5);
      expect(dataSet['active'], isTrue);
    },
  );

  test(
    'dataset index operator writes active edit buffer field values',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcIntegerField(name: 'quantity'),
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          FdcBooleanField(name: 'active'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{
              'name': 'Alpha',
              'quantity': 3,
              'amount': 12.5,
              'active': false,
            },
          ],
        ),
      );

      await dataSet.open();

      dataSet.edit();
      dataSet['name'] = 'Beta';
      dataSet['quantity'] = 7;
      dataSet['amount'] = 99.95;
      dataSet['active'] = true;

      expect(dataSet.fieldByName('name').asString, 'Beta');
      expect(dataSet.fieldByName('quantity').asInteger, 7);
      expect(dataSet.fieldByName('amount').asDecimal?.toString(), '99.95');
      expect(dataSet.fieldByName('active').asBoolean, isTrue);
    },
  );

  test('dataset index operator write follows dataset state rules', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    expect(() => dataSet['name'] = 'Beta', throwsA(isA<StateError>()));
  });
}
