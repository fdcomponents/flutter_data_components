import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_display_cells.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FdcGridBadge renders empty content for null values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: FdcGridBadge(
            column: FdcBadgeColumn<dynamic>(
              fieldName: 'status',
              badgeText: 'Fallback',
              badgeColor: Colors.blue,
            ),
            value: null,
            cellTextStyle: null,
            alignment: Alignment.center,
          ),
        ),
      ),
    );

    expect(find.text('Fallback'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(FdcGridBadge),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('FdcGridBadge uses compact badge styling', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: FdcGridBadge(
            column: FdcBadgeColumn<dynamic>(
              fieldName: 'status',
              badgeText: 'Paid',
              badgeColor: Colors.blue,
            ),
            value: 'paid',
            cellTextStyle: null,
            alignment: Alignment.center,
          ),
        ),
      ),
    );

    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(FdcGridBadge),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>();

    final badgeDecoration = decorations.singleWhere(
      (decoration) => decoration.color == Colors.blue,
    );

    expect(badgeDecoration.borderRadius, BorderRadius.circular(4));
    expect(badgeDecoration.border, isA<Border>());

    final text = tester.widget<Text>(find.text('Paid'));
    expect(text.style?.fontSize, isNotNull);
    expect(text.style!.fontSize!, lessThan(14));
  });

  testWidgets('FdcGridBadge derives icon color and size from text style', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: FdcGridBadge(
            column: FdcBadgeColumn<dynamic>(fieldName: 'status'),
            value: FdcBadgeValue(
              text: 'Active',
              color: Color(0xFFDCFCE7),
              icon: Icons.check,
              textStyle: TextStyle(color: Colors.green, fontSize: 12),
            ),
            cellTextStyle: null,
            alignment: Alignment.center,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(icon.color, Colors.green);
    expect(icon.size, 12);

    final text = tester.widget<Text>(find.text('Active'));
    expect(text.style?.color, Colors.green);
    expect(text.style?.fontSize, 12);
  });

  testWidgets('FdcGridBadge keeps default icon color aligned with text color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: FdcGridBadge(
            column: FdcBadgeColumn<dynamic>(fieldName: 'status'),
            value: FdcBadgeValue(
              text: 'Active',
              color: Color(0xFFDCFCE7),
              icon: Icons.check,
            ),
            cellTextStyle: null,
            alignment: Alignment.center,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.check));
    final text = tester.widget<Text>(find.text('Active'));

    expect(icon.color, text.style?.color);
    expect(icon.size, text.style?.fontSize);
  });
}
