import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGrid column horizontal alignment', () {
    testWidgets('applies center alignment to built-in display text', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 260,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                toolbar: const FdcGridToolbar(visible: false),
                header: const FdcGridHeader(
                  filters: FdcGridHeaderFilters(initiallyVisible: false),
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(
                    fieldName: 'name',
                    label: 'Name',
                    horizontalAlignment: FdcGridHorizontalAlignment.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Alpha'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets(
      'end-aligned header moves the column menu icon to the left in LTR',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(name: 'name', size: 50),
            FdcStringField(name: 'status', size: 50),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'status': 'Open'},
            ],
          ),
        );
        dataSet.open();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 420,
                height: 220,
                child: FdcGrid(
                  dataSet: dataSet,
                  options: const FdcGridOptions(allowColumnSorting: true),
                  toolbar: const FdcGridToolbar(visible: false),
                  header: const FdcGridHeader(
                    filters: FdcGridHeaderFilters(initiallyVisible: false),
                  ),
                  columns: const <FdcGridColumn<dynamic>>[
                    FdcTextColumn<dynamic>(
                      fieldName: 'name',
                      label: 'End header',
                      width: 180,
                      horizontalAlignment: FdcGridHorizontalAlignment.end,
                    ),
                    FdcTextColumn<dynamic>(
                      fieldName: 'status',
                      label: 'Status',
                      width: 160,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final label = tester.widget<Text>(find.text('End header'));
        expect(label.textAlign, TextAlign.end);

        final menuCenter = tester.getCenter(find.byIcon(Icons.more_vert).first);
        final labelCenter = tester.getCenter(find.text('End header'));
        expect(menuCenter.dx, lessThan(labelCenter.dx));
      },
    );

    testWidgets(
      'end-aligned header places sort icon and position before the label in LTR',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(name: 'group', size: 50),
            FdcStringField(name: 'name', size: 50),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'group': 'B', 'name': 'Beta'},
              {'group': 'A', 'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        dataSet.sort.set(const <FdcDataSetSort>[
          FdcDataSetSort(fieldName: 'group'),
          FdcDataSetSort(fieldName: 'name'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 460,
                height: 220,
                child: FdcGrid(
                  dataSet: dataSet,
                  options: const FdcGridOptions(allowColumnSorting: true),
                  toolbar: const FdcGridToolbar(visible: false),
                  header: const FdcGridHeader(
                    filters: FdcGridHeaderFilters(initiallyVisible: false),
                  ),
                  columns: const <FdcGridColumn<dynamic>>[
                    FdcTextColumn<dynamic>(
                      fieldName: 'group',
                      label: 'Group',
                      width: 160,
                    ),
                    FdcTextColumn<dynamic>(
                      fieldName: 'name',
                      label: 'End sorted',
                      width: 220,
                      horizontalAlignment: FdcGridHorizontalAlignment.end,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final labelLeft = tester.getTopLeft(find.text('End sorted')).dx;

        expect(tester.getCenter(find.text('2')).dx, lessThan(labelLeft));

        final sortIcons = find.byIcon(Icons.north);
        expect(sortIcons, findsNWidgets(2));

        final hasSortIconImmediatelyBeforeLabel = List<bool>.generate(
          sortIcons.evaluate().length,
          (index) {
            final dx = tester.getCenter(sortIcons.at(index)).dx;
            return dx < labelLeft && dx > labelLeft - 80;
          },
        ).contains(true);

        expect(hasSortIconImmediatelyBeforeLabel, isTrue);
      },
    );

    testWidgets('in-place text editor keeps legacy left alignment', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 260,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                toolbar: const FdcGridToolbar(visible: false),
                header: const FdcGridHeader(
                  filters: FdcGridHeaderFilters(initiallyVisible: false),
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(
                    fieldName: 'name',
                    label: 'Name',
                    horizontalAlignment: FdcGridHorizontalAlignment.end,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.textAlign, TextAlign.left);
    });

    testWidgets('in-place integer editor uses numeric right alignment', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'quantity')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'quantity': 12},
          ],
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 260,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                toolbar: const FdcGridToolbar(visible: false),
                header: const FdcGridHeader(
                  filters: FdcGridHeaderFilters(initiallyVisible: false),
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcIntegerColumn<dynamic>(
                    fieldName: 'quantity',
                    label: 'Quantity',
                    horizontalAlignment: FdcGridHorizontalAlignment.start,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('12'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.textAlign, TextAlign.right);
    });

    testWidgets('in-place decimal editor uses numeric right alignment', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 10, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 12.34},
          ],
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 260,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                toolbar: const FdcGridToolbar(visible: false),
                header: const FdcGridHeader(
                  filters: FdcGridHeaderFilters(initiallyVisible: false),
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcDecimalColumn<dynamic>(
                    fieldName: 'amount',
                    label: 'Amount',
                    horizontalAlignment: FdcGridHorizontalAlignment.start,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('12.34'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.textAlign, TextAlign.right);
    });
  });
}
