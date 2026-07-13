import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_toolbar_search.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

class _SearchSubmit {
  const _SearchSubmit(this.text, this.mode, this.caseSensitive);

  final String text;
  final FdcSearchMode mode;
  final bool caseSensitive;
}

class _SearchHarness extends StatefulWidget {
  const _SearchHarness({
    required this.controller,
    required this.submits,
    super.key,
  });

  final FdcGridToolbarSearchController controller;
  final List<_SearchSubmit> submits;

  @override
  State<_SearchHarness> createState() => _SearchHarnessState();
}

class _SearchHarnessState extends State<_SearchHarness> {
  FdcSearchMode matchMode = FdcSearchMode.anyWord;
  bool caseSensitive = false;

  void updateSearchConfig({FdcSearchMode? matchMode, bool? caseSensitive}) {
    setState(() {
      this.matchMode = matchMode ?? this.matchMode;
      this.caseSensitive = caseSensitive ?? this.caseSensitive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FdcGridToolbarSearch(
          controller: widget.controller,
          style: const FdcGridToolbarStyle(),
          mode: FdcGridSearchBarMode.advanced,
          matchMode: matchMode,
          caseSensitive: caseSensitive,
          debounceDuration: Duration.zero,
          debouncePolicy: FdcDebouncePolicy.fixed,
          recordCountProvider: () => 10,
          enabled: true,
          onSearchChanged: (text, {required mode, required caseSensitive}) {
            widget.submits.add(_SearchSubmit(text, mode, caseSensitive));
          },
          onSearchCleared: () {},
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'toolbar search resubmits active text when parent updates search config',
    (tester) async {
      final submits = <_SearchSubmit>[];
      final controller = FdcGridToolbarSearchController();
      final harnessKey = GlobalKey<_SearchHarnessState>();

      await tester.pumpWidget(
        _SearchHarness(
          key: harnessKey,
          controller: controller,
          submits: submits,
        ),
      );

      controller.openAndFocus();
      await pumpPendingFrames(tester);

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      await tester.enterText(searchField, 'alpha beta');
      await pumpPendingFrames(tester);

      expect(submits, hasLength(1));
      expect(submits.last.text, 'alpha beta');
      expect(submits.last.mode, FdcSearchMode.anyWord);
      expect(submits.last.caseSensitive, isFalse);

      harnessKey.currentState!.updateSearchConfig(
        matchMode: FdcSearchMode.allWords,
      );
      await pumpPendingFrames(tester);

      expect(submits, hasLength(2));
      expect(submits.last.text, 'alpha beta');
      expect(submits.last.mode, FdcSearchMode.allWords);
      expect(submits.last.caseSensitive, isFalse);

      harnessKey.currentState!.updateSearchConfig(caseSensitive: true);
      await pumpPendingFrames(tester);

      expect(submits, hasLength(3));
      expect(submits.last.text, 'alpha beta');
      expect(submits.last.mode, FdcSearchMode.allWords);
      expect(submits.last.caseSensitive, isTrue);
    },
  );
  testWidgets('toolbar search text matches toolbar text size', (tester) async {
    final controller = FdcGridToolbarSearchController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FdcGridToolbarSearch(
            controller: controller,
            style: const FdcGridToolbarStyle(
              textStyle: TextStyle(fontSize: 16),
            ),
            mode: FdcGridSearchBarMode.simple,
            matchMode: FdcSearchMode.anyWord,
            caseSensitive: false,
            debounceDuration: Duration.zero,
            debouncePolicy: FdcDebouncePolicy.fixed,
            recordCountProvider: () => 10,
            enabled: true,
            onSearchChanged: (text, {required mode, required caseSensitive}) {},
            onSearchCleared: () {},
          ),
        ),
      ),
    );

    controller.openAndFocus();
    await pumpPendingFrames(tester);

    final textField = tester.widget<TextField>(
      find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
    );
    expect(textField.style?.fontSize, 16);
    expect(textField.decoration?.hintStyle?.fontSize, 16);
  });
}
