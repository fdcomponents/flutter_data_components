import 'package:flutter_data_components/src/data/fdc_data_errors.dart';
import 'package:flutter_data_components/src/data/fdc_dataset_error_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('error store reuses its unmodifiable list view', () {
    final store = FdcDataSetErrorStore();

    final first = store.unmodifiable;
    final second = store.unmodifiable;

    expect(identical(first, second), isTrue);
    expect(
      () => first.add(fdcDataSetError(message: 'nope')),
      throwsUnsupportedError,
    );

    store.replace(<FdcDataSetError>[
      fdcDataSetError(message: 'Required', fieldName: 'name', recordId: 1),
    ]);

    expect(first, hasLength(1));
    expect(first.single.message, 'Required');
  });

  test('field message index preserves global and record error order', () {
    final store = FdcDataSetErrorStore();
    store.replace(<FdcDataSetError>[
      fdcDataSetError(message: 'Global first', fieldName: 'Name'),
      fdcDataSetError(message: 'Row one', fieldName: 'name', recordId: 1),
      fdcDataSetError(message: 'Global last', fieldName: 'NAME'),
      fdcDataSetError(message: 'Other row', fieldName: 'name', recordId: 2),
      fdcDataSetError(message: 'Other field', fieldName: 'city', recordId: 1),
    ]);

    expect(
      store.messageForField('name', recordId: 1),
      'Global first\nRow one\nGlobal last',
    );
    expect(
      store.messageForField('NAME', recordId: 2),
      'Global first\nGlobal last\nOther row',
    );
    expect(
      store.messageForField('name', recordId: 3),
      'Global first\nGlobal last',
    );
    expect(store.messageForField('missing', recordId: 1), isNull);
  });

  test('field message index stays synchronized after targeted clearing', () {
    final store = FdcDataSetErrorStore();
    store.replace(<FdcDataSetError>[
      fdcDataSetError(message: 'Row one', fieldName: 'name', recordId: 1),
      fdcDataSetError(message: 'Row two', fieldName: 'name', recordId: 2),
    ]);

    expect(store.clearForField('NAME', recordId: 1), isTrue);
    expect(store.messageForField('name', recordId: 1), isNull);
    expect(store.messageForField('name', recordId: 2), 'Row two');

    store.clear();
    expect(store.messageForField('name', recordId: 2), isNull);
  });
  test('field message index handles many record errors on one field', () {
    final store = FdcDataSetErrorStore();
    store.replace(<FdcDataSetError>[
      for (var recordId = 1; recordId <= 5000; recordId += 1)
        fdcDataSetError(
          message: 'Error $recordId',
          fieldName: 'name',
          recordId: recordId,
        ),
    ]);

    expect(store.messageForField('name', recordId: 1), 'Error 1');
    expect(store.messageForField('NAME', recordId: 2500), 'Error 2500');
    expect(store.messageForField('name', recordId: 5000), 'Error 5000');
    expect(store.messageForField('name', recordId: 5001), isNull);
  });
}
