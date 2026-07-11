import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onValidationError fires when post validation fails', () async {
    final eventLog = <List<FdcValidationError>>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name', label: 'Name', required: true),
        FdcStringField(size: 255, name: 'note'),
      ],
      onValidationError: (dataSet, errors) {
        eventLog.add(errors);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages.count, errors.length);
      },

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    await dataSet.open();
    dataSet.append();
    dataSet.setFieldValue('note', 'Only optional field is filled');

    expect(() => dataSet.post(), throwsA(isA<FdcDataSetValidationException>()));

    expect(eventLog, hasLength(1));
    expect(eventLog.single, hasLength(1));
    expect(eventLog.single.single.fieldName, 'name');
    expect(eventLog.single.single.code, FdcValidationCodes.requiredField);
    expect(eventLog.single.single.message, 'Field Name is required.');
    expect(dataSet.state, FdcDataSetState.insert);
  });

  test(
    'onValidationError fires when immediate field validation emits errors',
    () async {
      final eventLog = <List<FdcValidationError>>[];

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(
            name: 'qty',
            label: 'Quantity',
            minValue: 1,
            maxValue: 10,
          ),
        ],
        onValidationError: (dataSet, errors) {
          eventLog.add(errors);
          expect(dataSet.errors.messages.isNotEmpty, isTrue);
        },

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            <String, Object?>{'qty': 5},
          ],
        ),
      );
      await dataSet.open();

      dataSet.edit();

      final errors = FdcDataSetInternal.validateFieldValueAndEmit(
        dataSet,
        'qty',
        0,
      );

      expect(errors, hasLength(1));
      expect(eventLog, hasLength(1));
      expect(eventLog.single.single.fieldName, 'qty');
      expect(eventLog.single.single.code, FdcValidationCodes.minValue);
    },
  );

  test(
    'onValidationError does not fire for silent validation checks or clearing valid field value',
    () async {
      final eventLog = <List<FdcValidationError>>[];

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'qty', label: 'Quantity', minValue: 1),
        ],
        onValidationError: (dataSet, errors) {
          eventLog.add(errors);
        },

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            <String, Object?>{'qty': 5},
          ],
        ),
      );
      await dataSet.open();

      dataSet.edit();

      final silentErrors = dataSet.validateFieldValue('qty', 0);
      expect(silentErrors, hasLength(1));
      expect(eventLog, isEmpty);
      expect(dataSet.errors.messages.isNotEmpty, isFalse);

      final emittedErrors = FdcDataSetInternal.validateFieldValueAndEmit(
        dataSet,
        'qty',
        0,
      );
      expect(emittedErrors, hasLength(1));
      expect(eventLog, hasLength(1));
      expect(dataSet.errors.messages.isNotEmpty, isTrue);

      final validErrors = FdcDataSetInternal.validateFieldValueAndEmit(
        dataSet,
        'qty',
        2,
      );
      expect(validErrors, isEmpty);
      expect(eventLog, hasLength(1));
      expect(dataSet.errors.messages.isNotEmpty, isFalse);
    },
  );

  test('onValidationError includes recordValidator errors', () async {
    final eventLog = <List<FdcValidationError>>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      recordValidator: (record) {
        return <FdcValidationError>[
          const FdcValidationError(
            fieldName: 'name',
            message: 'Name is not accepted.',
            code: 'nameRejected',
          ),
        ];
      },
      onValidationError: (dataSet, errors) {
        eventLog.add(errors);
      },

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );
    await dataSet.open();

    dataSet.edit();
    dataSet.setFieldValue('name', 'Beta');

    expect(() => dataSet.post(), throwsA(isA<FdcDataSetValidationException>()));

    expect(eventLog, hasLength(1));
    expect(eventLog.single.single.fieldName, 'name');
    expect(eventLog.single.single.recordId, isNotNull);
    expect(eventLog.single.single.code, 'nameRejected');
    expect(eventLog.single.single.message, 'Name is not accepted.');
  });
}
