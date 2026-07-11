import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('text edit resolves editor theme from ThemeData extension', (
    tester,
  ) async {
    final dataSet = _textDataSet();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            FdcEditorTheme(data: FdcEditorThemes.dark),
          ],
        ),
        home: Material(
          child: FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
        ),
      ),
    );

    final decoration = _inputDecoration(tester);
    expect(decoration.fillColor, FdcEditorThemes.dark.input.fillColor);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).style.color,
      FdcEditorThemes.dark.input.textStyle?.color,
    );
  });

  testWidgets('local editor theme wins over ThemeData editor theme', (
    tester,
  ) async {
    final dataSet = _textDataSet();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            FdcEditorTheme(data: FdcEditorThemes.dark),
          ],
        ),
        home: Material(
          child: FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'name',
            theme: FdcEditorThemes.white,
          ),
        ),
      ),
    );

    expect(
      _inputDecoration(tester).fillColor,
      FdcEditorThemes.white.input.fillColor,
    );
  });

  testWidgets('local input style wins over resolved editor theme', (
    tester,
  ) async {
    const fillColor = Color(0xFF123456);
    const focusedBorderColor = Color(0xFFABCDEF);
    final dataSet = _textDataSet();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            FdcEditorTheme(data: FdcEditorThemes.dark),
          ],
        ),
        home: Material(
          child: FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'name',
            style: const FdcEditorInputStyle(
              fillColor: fillColor,
              focusedBorderColor: focusedBorderColor,
            ),
          ),
        ),
      ),
    );

    final decoration = _inputDecoration(tester);
    expect(decoration.fillColor, fillColor);
    expect(
      (decoration.focusedBorder! as OutlineInputBorder).borderSide.color,
      focusedBorderColor,
    );
  });

  testWidgets('text edit counter uses editor theme counter style', (
    tester,
  ) async {
    final dataSet = _textDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 240,
            child: FdcTextEdit(
              dataSet: dataSet,
              fieldName: 'name',
              theme: FdcEditorThemes.black,
              showCounter: true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();

    expect(find.text('5/20'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('5/20')).style?.color,
      FdcEditorThemes.black.counter.textStyle?.color,
    );
  });

  test(
    'editor theme presets expose input controls and combo popup sections',
    () {
      expect(FdcEditorThemes.dark.input.fillColor, isNotNull);
      expect(FdcEditorThemes.dark.controls.iconColor, isNotNull);
      expect(FdcEditorThemes.dark.comboPopup.backgroundColor, isNotNull);
      expect(FdcEditorThemes.dark.counter.textStyle, isNotNull);
    },
  );
}

FdcDataSet _textDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(name: 'name', label: 'Name', size: 20),
    ],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alice'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

InputDecoration _inputDecoration(WidgetTester tester) {
  return tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
}
