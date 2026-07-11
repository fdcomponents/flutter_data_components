import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/dialogs/fdc_dialog_base.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('record keys require aligned field names and values', () {
    expect(
      () => FdcDataRecordKey(
        fieldNames: const <String>['id'],
        values: const <Object?>[],
      ),
      throwsArgumentError,
    );
  });

  test('dialog base requires at least one button at runtime', () {
    expect(
      () => FdcDialogBase<void>(
        title: 'Title',
        content: const SizedBox.shrink(),
        buttons: const <FdcDialogButton<void>>[],
      ),
      throwsArgumentError,
    );
  });

  testWidgets('grid rejects inline cell error indicators in all modes', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FdcGrid(
          dataSet: dataSet,
          cellIndicator: const FdcGridCellIndicator(
            errorIndicator: FdcErrorIndicatorOptions(
              mode: FdcErrorIndicatorMode.inline,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isArgumentError);
  });
}
