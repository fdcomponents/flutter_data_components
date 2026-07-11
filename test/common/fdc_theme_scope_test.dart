import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FdcApp provides app-level grid and editor theme data', (
    tester,
  ) async {
    FdcGridThemeData? gridTheme;
    FdcEditorThemeData? editorTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: FdcApp(
          theme: const FdcThemeData(
            grid: FdcGridThemeData(
              grid: FdcGridStyle(backgroundColor: Colors.red),
            ),
            editor: FdcEditorThemeData(
              input: FdcEditorInputStyle(fillColor: Colors.green),
            ),
          ),
          child: Builder(
            builder: (context) {
              gridTheme = FdcGridTheme.resolveData(context, null);
              editorTheme = FdcEditorTheme.resolveData(context, null);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(gridTheme?.grid.backgroundColor, Colors.red);
    expect(editorTheme?.input.fillColor, Colors.green);
  });

  testWidgets('FdcTheme partially overrides the nearest FdcApp visual theme', (
    tester,
  ) async {
    FdcGridThemeData? gridTheme;
    FdcEditorThemeData? editorTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: FdcApp(
          theme: const FdcThemeData(
            grid: FdcGridThemeData(
              grid: FdcGridStyle(backgroundColor: Colors.red),
            ),
            editor: FdcEditorThemeData(
              input: FdcEditorInputStyle(fillColor: Colors.green),
            ),
          ),
          child: FdcTheme(
            data: const FdcThemeData(
              editor: FdcEditorThemeData(
                input: FdcEditorInputStyle(fillColor: Colors.yellow),
              ),
            ),
            child: Builder(
              builder: (context) {
                gridTheme = FdcGridTheme.resolveData(context, null);
                editorTheme = FdcEditorTheme.resolveData(context, null);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(gridTheme?.grid.backgroundColor, Colors.red);
    expect(editorTheme?.input.fillColor, Colors.yellow);
  });

  testWidgets('local component themes win over FdcTheme scope', (tester) async {
    FdcGridThemeData? gridTheme;
    FdcEditorThemeData? editorTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: FdcTheme(
          data: const FdcThemeData(
            grid: FdcGridThemeData(
              grid: FdcGridStyle(backgroundColor: Colors.red),
            ),
            editor: FdcEditorThemeData(
              input: FdcEditorInputStyle(fillColor: Colors.green),
            ),
          ),
          child: Builder(
            builder: (context) {
              gridTheme = FdcGridTheme.resolveData(
                context,
                const FdcGridThemeData(
                  grid: FdcGridStyle(backgroundColor: Colors.black),
                ),
              );
              editorTheme = FdcEditorTheme.resolveData(
                context,
                const FdcEditorThemeData(
                  input: FdcEditorInputStyle(fillColor: Colors.white),
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(gridTheme?.grid.backgroundColor, Colors.black);
    expect(editorTheme?.input.fillColor, Colors.white);
  });
  testWidgets(
    'grid and editor presets follow Material brightness without explicit FDC theme',
    (tester) async {
      FdcGridThemeData? gridTheme;
      FdcEditorThemeData? editorTheme;

      Widget build(ThemeMode mode) {
        return MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          home: Builder(
            builder: (context) {
              gridTheme = FdcGridTheme.resolveData(context, null);
              editorTheme = FdcEditorTheme.resolveData(context, null);
              return const SizedBox.shrink();
            },
          ),
        );
      }

      await tester.pumpWidget(build(ThemeMode.light));
      expect(gridTheme, FdcGridThemes.light);
      expect(editorTheme, FdcEditorThemes.light);

      await tester.pumpWidget(build(ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(gridTheme, FdcGridThemes.dark);
      expect(editorTheme, FdcEditorThemes.dark);
    },
  );
}
