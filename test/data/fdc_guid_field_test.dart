import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGuidField', () {
    test('normalizes standard GUID string input', () async {
      final dataSet = _createGuidDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 'A0EBD67F-6F77-4A8E-9F41-B04D08764F01'},
          ],
        ),
      );

      await dataSet.open();

      final value = dataSet.fieldValue('id');
      expect(value, isA<FdcGuid>());
      expect(value.toString(), 'a0ebd67f-6f77-4a8e-9f41-b04d08764f01');
    });

    test('accepts compact and braced GUID input', () async {
      final dataSet = _createGuidDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 'a0ebd67f6f774a8e9f41b04d08764f01'},
            {'id': '{B0EBD67F-6F77-4A8E-9F41-B04D08764F02}'},
          ],
        ),
      );

      await dataSet.open();

      expect(
        FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id').toString(),
        'a0ebd67f-6f77-4a8e-9f41-b04d08764f01',
      );
      expect(
        FdcDataSetInternal.fieldValueAt(dataSet, 1, 'id').toString(),
        'b0ebd67f-6f77-4a8e-9f41-b04d08764f02',
      );
    });

    test('rejects invalid GUID input', () {
      final dataSet = _createGuidDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 'not-a-guid'},
          ],
        ),
      );

      expect(() => dataSet.open(), throwsA(isA<FdcDataSetException>()));
    });

    test('sorts and filters as canonical text', () async {
      final dataSet = _createGuidDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 'c0ebd67f-6f77-4a8e-9f41-b04d08764f03'},
            {'id': 'a0ebd67f-6f77-4a8e-9f41-b04d08764f01'},
            {'id': 'b0ebd67f-6f77-4a8e-9f41-b04d08764f02'},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.sort.set(const <FdcDataSetSort>[
        FdcDataSetSort(fieldName: 'id'),
      ]);

      expect(
        FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id').toString(),
        startsWith('a0'),
      );
      expect(
        FdcDataSetInternal.fieldValueAt(dataSet, 2, 'id').toString(),
        startsWith('c0'),
      );

      await dataSet.filter.where('id').startsWith('b0eb').apply();

      expect(dataSet.recordCount, 1);
      expect(
        dataSet.fieldValue('id').toString(),
        'b0ebd67f-6f77-4a8e-9f41-b04d08764f02',
      );
    });

    test('runtime accessor returns typed value', () async {
      final dataSet = _createGuidDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 'a0ebd67f-6f77-4a8e-9f41-b04d08764f01'},
          ],
        ),
      );

      await dataSet.open();

      final field = dataSet.fieldByName('id');
      expect(
        field.asGuid,
        FdcGuid.parse('a0ebd67f-6f77-4a8e-9f41-b04d08764f01'),
      );
    });

    test('uses binary value semantics', () {
      final guid = FdcGuid.parse('a0ebd67f-6f77-4a8e-9f41-b04d08764f01');
      final same = FdcGuid.fromBytes(guid.bytes);
      final greater = FdcGuid.parse('a0ebd67f-6f77-4a8e-9f41-b04d08764f02');

      expect(guid, same);
      expect(guid.hashCode, same.hashCode);
      expect(guid.compareTo(greater), lessThan(0));
      expect(guid.bytes.length, 16);
      expect(guid.value, 'a0ebd67f-6f77-4a8e-9f41-b04d08764f01');
    });

    test('generates RFC 4122 version 4 GUID values', () {
      final guid = FdcGuid.newGuid();
      final bytes = guid.bytes;

      expect(bytes.length, 16);
      expect(bytes[6] >> 4, 4);
      expect(bytes[8] & 0xc0, 0x80);
      expect(FdcGuid.tryParse(guid.toString()), guid);
    });

    test(
      'defaultValue: FdcGuid.newGuid does not backfill loaded rows',
      () async {
        final dataSet = FdcDataSet(
          fields: <FdcFieldDef>[
            const FdcGuidField(name: 'id', defaultValue: FdcGuid.newGuid),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{},
              <String, Object?>{},
            ],
          ),
        );

        await dataSet.open();

        expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id'), isNull);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'id'), isNull);
      },
    );

    test(
      'defaultValue: FdcGuid.newGuid initializes appended records',
      () async {
        final dataSet = FdcDataSet(
          fields: <FdcFieldDef>[
            const FdcGuidField(name: 'id', defaultValue: FdcGuid.newGuid),
          ],

          adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
        );

        await dataSet.open();
        dataSet.append();
        final first = dataSet.fieldValue('id');
        dataSet.post();

        dataSet.append();
        final second = dataSet.fieldValue('id');

        expect(first, isA<FdcGuid>());
        expect(second, isA<FdcGuid>());
        expect(second, isNot(first));
      },
    );

    test(
      'rejects static GUID default values to avoid duplicate defaults',
      () async {
        final dataSet = FdcDataSet(
          fields: <FdcFieldDef>[
            FdcGuidField(name: 'id', defaultValue: FdcGuid.newGuid()),
          ],

          adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
        );

        await dataSet.open();

        expect(dataSet.append, throwsA(isA<FdcDataSetException>()));
      },
    );
  });
}

FdcDataSet _createGuidDataSet({IFdcDataAdapter? adapter}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[FdcGuidField(name: 'id')],
    adapter:
        adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
}
