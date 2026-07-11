import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/bindings/fdc_bindings.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExtendedStringField extends FdcStringField {
  const _ExtendedStringField({required super.name}) : super(size: 50);
}

void main() {
  group('FdcFieldBindingResolver', () {
    test('resolves a typed field binding', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alice'},
          ],
        ),
      );
      await dataSet.open();

      final binding = FdcFieldBindingResolver.resolve<FdcStringField>(
        dataSet,
        'name',
        ownerName: 'test',
      );

      expect(binding.fieldDef.size, 50);
      expect(binding.value, 'Alice');
      expect(binding.readOnly, isFalse);
    });

    test('stale binding detects current record changes', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alice'},
            {'name': 'Megan'},
          ],
        ),
      );
      await dataSet.open();

      final binding = FdcFieldBindingResolver.resolve<FdcStringField>(
        dataSet,
        'name',
        ownerName: 'test',
      );

      expect(binding.value, 'Alice');
      dataSet.moveToRecord(2);

      expect(binding.ensureCurrentRecordStillBound, throwsA(isA<StateError>()));
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.fieldValue('name'), 'Megan');
    });

    test(
      'resolveAnyOf accepts subclasses of allowed field definitions',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[_ExtendedStringField(name: 'name')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alice'},
            ],
          ),
        );
        await dataSet.open();

        final binding = FdcFieldBindingResolver.resolveAnyOf(
          dataSet,
          'name',
          allowedFieldTypes: const <Type>[FdcStringField],
          ownerName: 'test',
        );

        expect(binding.fieldDef, isA<_ExtendedStringField>());
        expect(binding.value, 'Alice');
        expect(
          dataSet.fieldDef<FdcStringField>('name'),
          isA<_ExtendedStringField>(),
        );
      },
    );

    test('throws on wrong typed binding', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alice'},
          ],
        ),
      );
      await dataSet.open();

      expect(
        () => FdcFieldBindingResolver.resolve<FdcDecimalField>(
          dataSet,
          'name',
          ownerName: 'FdcDecimalEdit',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
