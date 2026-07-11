import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onError fires for visible abort and not for silent abort', () async {
    final visibleLog = <List<FdcDataSetError>>[];
    final visibleCauses = <Object?>[];

    final visibleDataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      beforeEdit: (dataSet) {
        throw FdcDataSetAbortException('Edit is not allowed.');
      },
      onError: (dataSet, errors, cause) {
        visibleLog.add(errors);
        visibleCauses.add(cause);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages.count, errors.length);
      },

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );

    await visibleDataSet.open();
    visibleDataSet.edit();

    expect(visibleDataSet.state, FdcDataSetState.browse);
    expect(visibleDataSet.errors.messages[0], 'Edit is not allowed.');
    expect(visibleLog, hasLength(1));
    expect(visibleLog.single.single.message, 'Edit is not allowed.');
    expect(visibleCauses.single, isA<FdcDataSetAbortException>());

    final silentLog = <List<FdcDataSetError>>[];
    final silentDataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      beforeEdit: (dataSet) {
        throw const FdcDataSetAbortException.silent();
      },
      onError: (dataSet, errors, cause) {
        silentLog.add(errors);
      },

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );

    await silentDataSet.open();
    silentDataSet.edit();

    expect(silentDataSet.state, FdcDataSetState.browse);
    expect(silentDataSet.errors.messages.isNotEmpty, isFalse);
    expect(silentLog, isEmpty);
  });

  test('onError fires for post validation errors', () async {
    final errorLog = <List<FdcDataSetError>>[];
    final validationLog = <List<FdcValidationError>>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name', label: 'Name', required: true),
      ],
      onValidationError: (dataSet, errors) {
        validationLog.add(errors);
      },
      onError: (dataSet, errors, cause) {
        errorLog.add(errors);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages.count, errors.length);
      },

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    await dataSet.open();
    dataSet.append();

    expect(() => dataSet.post(), throwsA(isA<FdcDataSetValidationException>()));

    expect(validationLog, hasLength(1));
    expect(errorLog, hasLength(1));
    expect(errorLog.single.single.fieldName, 'name');
    expect(errorLog.single.single.code, FdcValidationCodes.requiredField);
    expect(errorLog.single.single.message, 'Field Name is required.');
  });

  test('onError fires for immediate field validation errors', () async {
    final errorLog = <List<FdcDataSetError>>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'qty', label: 'Quantity', minValue: 1),
      ],
      onError: (dataSet, errors, cause) {
        errorLog.add(errors);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
      },

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
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
    expect(errorLog, hasLength(1));
    expect(errorLog.single.single.fieldName, 'qty');
    expect(errorLog.single.single.code, FdcValidationCodes.minValue);
  });

  test(
    'onError fires for unexpected exceptions converted to dataset errors',
    () async {
      final errorLog = <List<FdcDataSetError>>[];
      final causes = <Object?>[];
      final sourceError = Exception('Open failed.');

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
        beforeOpen: (dataSet) {
          throw sourceError;
        },
        onError: (dataSet, errors, cause) {
          errorLog.add(errors);
          causes.add(cause);
          expect(dataSet.errors.messages.isNotEmpty, isTrue);
        },

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      );

      expect(() => dataSet.open(), throwsA(isA<FdcDataSetException>()));

      expect(errorLog, hasLength(1));
      expect(errorLog.single.single.message, 'Open failed.');
      expect(errorLog.single.single.cause, same(sourceError));
      expect(causes.single, same(sourceError));
    },
  );

  test('onError fires for failed apply update result errors', () async {
    final errorLog = <List<FdcDataSetError>>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
      adapter: _FailingApplyAdapter(),
      onError: (dataSet, errors, cause) {
        errorLog.add(errors);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
      },
    );

    await dataSet.open();
    dataSet.edit();
    dataSet.setFieldValue('name', 'Beta');

    final result = await dataSet.applyUpdates();

    expect(result.success, isFalse);
    expect(errorLog, hasLength(1));
    expect(errorLog.single.single.message, 'Server rejected the record.');
    expect(errorLog.single.single.fieldName, 'name');
    expect(errorLog.single.single.code, 'serverRejected');
  });
}

class _FailingApplyAdapter implements IFdcDataAdapter {
  @override
  bool get readOnly => false;

  @override
  FdcDataAdapterCapabilities get capabilities =>
      const FdcDataAdapterCapabilities.none();

  @override
  Future<FdcDataAggregateResult> aggregate(
    FdcDataAggregateRequest request,
  ) async {
    throw FdcDataAdapterException(
      operation: 'aggregate',
      code: 'unsupported_adapter_operation',
      message: '$runtimeType does not support aggregate queries.',
    );
  }

  @override
  String? validateStorageValue(FdcFieldDef field, Object? value) => null;

  @override
  FdcDataApplyError mapApplyException(
    FdcChangeSetEntry entry,
    Object error, {
    required FdcDataApplyOperation operation,
  }) {
    return FdcDataApplyError(
      recordId: entry.recordId,
      message: error.toString(),
      code: 'adapter_error',
    );
  }

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    return const FdcDataLoadResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'name': 'Alpha'},
      ],
    );
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    return const FdcDataApplyResult.failure(
      errors: <FdcDataApplyError>[
        FdcDataApplyError(
          recordId: 1,
          fieldName: 'name',
          code: 'serverRejected',
          message: 'Server rejected the record.',
        ),
      ],
    );
  }
}
