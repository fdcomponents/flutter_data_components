import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_display_cells.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'FdcGridProgress uses the same compact default text baseline as badges',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              labelSmall: TextStyle(fontSize: 11),
              bodyMedium: TextStyle(fontSize: 18),
            ),
          ),
          home: const Center(
            child: FdcGridProgress(
              column: FdcProgressColumn<dynamic>(fieldName: 'completion'),
              value: 50,
              cellTextStyle: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('50%'));

      expect(text.style?.fontSize, 11);
    },
  );

  testWidgets('FdcGridProgress lets progressStyle override compact defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(labelSmall: TextStyle(fontSize: 11)),
        ),
        home: const Center(
          child: FdcGridProgress(
            column: FdcProgressColumn<dynamic>(
              fieldName: 'completion',
              progressStyle: FdcGridProgressStyle(
                textStyle: TextStyle(fontSize: 13),
              ),
            ),
            value: 50,
            cellTextStyle: null,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('50%'));

    expect(text.style?.fontSize, 13);
  });

  testWidgets('FdcGridProgress keeps explicit progress style text color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(labelSmall: TextStyle(fontSize: 11)),
        ),
        home: const Center(
          child: FdcGridProgress(
            column: FdcProgressColumn<dynamic>(
              fieldName: 'completion',
              progressStyle: FdcGridProgressStyle(
                textStyle: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            value: 50,
            cellTextStyle: null,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('50%'));

    expect(text.style?.fontSize, 12);
    expect(text.style?.color, Colors.white70);
  });

  testWidgets('FdcGridProgress resolves progress style from theme extension', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            FdcGridTheme(
              data: FdcGridThemeData(
                progress: FdcGridProgressStyle(
                  color: Colors.purple,
                  backgroundColor: Colors.orange,
                  textStyle: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        home: const Center(
          child: FdcGridProgress(
            column: FdcProgressColumn<dynamic>(fieldName: 'completion'),
            value: 50,
            cellTextStyle: null,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('50%'));
    final fill = tester.widget<ColoredBox>(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == Colors.purple,
      ),
    );

    expect(text.style?.fontSize, 14);
    expect(text.style?.color, Colors.white);
    expect(fill.color, Colors.purple);
  });

  testWidgets('FdcGridProgress uses compact default corner radius', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: FdcGridProgress(
            column: FdcProgressColumn<dynamic>(fieldName: 'completion'),
            value: 50,
            cellTextStyle: null,
          ),
        ),
      ),
    );

    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));

    expect(clip.borderRadius, const BorderRadius.all(Radius.circular(4)));
  });

  testWidgets('FdcGridProgress uses light theme white text and darker track', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: FdcGridProgress(
            column: FdcProgressColumn<dynamic>(fieldName: 'completion'),
            value: 50,
            cellTextStyle: null,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('50%'));
    final track = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = track.decoration as BoxDecoration;

    expect(text.style?.color, const Color(0xFFFFFFFF));
    expect(decoration.color, const Color(0xFF9CA3AF));
  });
}
