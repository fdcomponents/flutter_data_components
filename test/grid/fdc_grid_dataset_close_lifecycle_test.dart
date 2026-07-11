import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

const _zeroDebounceHeader = FdcGridHeader(
  height: 32,
  filters: FdcGridHeaderFilters(
    visible: true,
    options: FdcGridFilterOptions(debounceDuration: Duration.zero),
  ),
);

void main() {
  testWidgets('dataset close clears grid sort filter and search UI state', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name', label: 'Name'),
        FdcStringField(size: 255, name: 'status', label: 'Status'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alpha', 'status': 'Ready'},
          {'name': 'Beta', 'status': 'Blocked'},
        ],
      ),
    );
    dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 260,
            child: FdcGrid(
              dataSet: dataSet,
              options: const FdcGridOptions(
                allowColumnSorting: true,
                defaultColumnWidth: 150,
                rowHeight: 34,
              ),
              header: _zeroDebounceHeader,
              toolbar: const FdcGridToolbar(
                items: <FdcGridItem>[
                  FdcGridSearchBar(debounceDuration: Duration.zero),
                ],
              ),
              columns: const <FdcGridColumn<dynamic>>[
                FdcTextColumn<dynamic>(fieldName: 'name'),
                FdcTextColumn<dynamic>(fieldName: 'status'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(dataSet.sort.active, isTrue);
    expect(find.byIcon(Icons.north), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(1), 'Ready');
    await tester.pumpAndSettle();
    expect(dataSet.filter.active, isTrue);
    expect(find.text('Beta'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
    );
    await tester.pumpAndSettle();
    final toolbarSearchField = find.byKey(
      const ValueKey('fdc_grid_toolbar_search_field'),
    );
    expect(toolbarSearchField, findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: toolbarSearchField,
        matching: find.byType(EditableText),
      ),
      'Alpha',
    );
    await tester.pumpAndSettle();
    expect(dataSet.search.active, isTrue);

    dataSet.close();
    await tester.pumpAndSettle();

    expect(dataSet.isOpen, isFalse);
    expect(dataSet.sort.active, isFalse);
    expect(dataSet.filter.active, isFalse);
    expect(dataSet.search.active, isFalse);
    expect(find.byIcon(Icons.north), findsNothing);
    expect(
      find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
      findsNothing,
    );

    final headerFilterEditors = tester.widgetList<EditableText>(
      find.byType(EditableText),
    );
    for (final editor in headerFilterEditors) {
      expect(editor.controller.text, isEmpty);
    }
  });
}
