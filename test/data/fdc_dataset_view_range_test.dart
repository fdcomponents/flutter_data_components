import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset_state.dart';
import 'package:flutter_data_components/src/data/fdc_dataset_view_controller.dart';
import 'package:flutter_data_components/src/data/fdc_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet view index storage', () {
    test('uses compact physical range for full unfiltered unsorted views', () {
      final view = FdcDataSetViewController();
      final records = _records(const <String>['A', 'B', 'C']);

      final nextIndex = view.rebuildView(
        records: records,
        fields: _fields,
        fieldIndexByName: _fieldIndexByName,
        currentIndex: -1,
        preserveRecordId: null,
        mustKeepRecordInView: (_) => false,
      );

      expect(nextIndex, 0);
      expect(view.debugViewIndexesUsePhysicalRange, isTrue);
      expect(view.viewIndexes, const <int>[0, 1, 2]);
    });

    test('materializes when filtering creates a sparse view', () {
      final view = FdcDataSetViewController();
      final records = _records(const <String>['A', 'B', 'C']);
      view.filters.add(
        const FdcDataSetFilter(
          fieldName: 'name',
          operator: FdcFilterOperator.equals,
          value: 'B',
        ),
      );

      view.rebuildView(
        records: records,
        fields: _fields,
        fieldIndexByName: _fieldIndexByName,
        currentIndex: -1,
        preserveRecordId: null,
        mustKeepRecordInView: (_) => false,
      );

      expect(view.debugViewIndexesUsePhysicalRange, isFalse);
      expect(view.viewIndexes, const <int>[1]);
    });

    test('materializes when sorting permutes the physical order', () {
      final view = FdcDataSetViewController();
      final records = _records(const <String>['C', 'A', 'B']);
      view.sorts.add(const FdcDataSetSort(fieldName: 'name'));

      view.rebuildView(
        records: records,
        fields: _fields,
        fieldIndexByName: _fieldIndexByName,
        currentIndex: -1,
        preserveRecordId: null,
        mustKeepRecordInView: (_) => false,
      );

      expect(view.debugViewIndexesUsePhysicalRange, isFalse);
      expect(view.viewIndexes, const <int>[1, 2, 0]);
    });

    test('deleted records keep the view materialized and sparse', () {
      final view = FdcDataSetViewController();
      final records = _records(const <String>['A', 'B', 'C']);
      records[1].state = FdcRecordState.deleted;

      view.rebuildView(
        records: records,
        fields: _fields,
        fieldIndexByName: _fieldIndexByName,
        currentIndex: -1,
        preserveRecordId: null,
        mustKeepRecordInView: (_) => false,
      );

      expect(view.debugViewIndexesUsePhysicalRange, isFalse);
      expect(view.viewIndexes, const <int>[0, 2]);
    });
  });
}

const _fields = <FdcFieldDef>[FdcStringField(name: 'name', size: 50)];
const _fieldIndexByName = <String, int>{'name': 0};

List<FdcRecord> _records(List<String> names) {
  return <FdcRecord>[
    for (var i = 0; i < names.length; i++)
      FdcRecord(id: i + 1, values: <Object?>[names[i]]),
  ];
}
