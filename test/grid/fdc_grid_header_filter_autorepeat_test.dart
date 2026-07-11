import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/src/grid/core/fdc_grid_types.dart';
import 'package:flutter_data_components/src/grid/widgets/header_filters/fdc_grid_header_filter_value_editors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('single backspace change is emitted before hardware key-up', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final changes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 40,
            child: FdcGridHeaderTextFilterInput(
              value: 'Alice Miller',
              focusNode: focusNode,
              style: const TextStyle(),
              onChanged: changes.add,
              onSubmitted: (_) {},
              debouncePolicy: FdcDebouncePolicy.adaptive,
              onDeferredChanged: () {},
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
    await tester.enterText(find.byType(TextField), 'Alice');

    expect(changes, isNotEmpty);
    expect(changes.last, 'Alice');

    final changesBeforeKeyUp = List<String>.of(changes);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
    expect(changes, changesBeforeKeyUp);
  });

  testWidgets('pickable header filter places caret on first tap', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 40,
            child: FdcGridHeaderTextFilterInput(
              value: '2026-06-19',
              focusNode: focusNode,
              style: const TextStyle(),
              onChanged: (_) {},
              onSubmitted: (_) {},
              debouncePolicy: FdcDebouncePolicy.adaptive,
              onDeferredChanged: () {},
              onPickValue: (_, _) async => null,
            ),
          ),
        ),
      ),
    );

    expect(focusNode.hasFocus, isFalse);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    final editableState = tester.state<EditableTextState>(
      find.byType(EditableText),
    );
    expect(editableState.textEditingValue.selection.isValid, isTrue);
  });
}
