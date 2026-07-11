import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/models/fdc_grid_cell_models.dart';
import 'package:flutter_data_components/src/grid/models/fdc_grid_layout_models.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_control_theme.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_header_label.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_row.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_row_indicator_cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGrid controls theme', () {
    test('built-in light theme uses neutral checkbox colors', () {
      expect(
        FdcGridThemes.light.controls.checkboxFillColor,
        const Color(0x00000000),
      );
      expect(
        FdcGridThemes.light.controls.checkboxCheckColor,
        const Color(0xFF000000),
      );
      expect(
        FdcGridThemes.light.controls.checkboxBorderColor,
        const Color(0xFF9CA3AF),
      );
      expect(
        FdcGridThemes.light.controls.checkboxDisabledBorderColor,
        const Color(0xFF9CA3AF),
      );
      expect(
        FdcGridThemes.light.controls.activeIconColor,
        const Color(0xFF000000),
      );
    });

    test('built-in white theme preserves historical pure-white surfaces', () {
      expect(FdcGridThemes.white.grid.backgroundColor, Colors.white);
      expect(FdcGridThemes.white.header.backgroundColor, Colors.white);
      expect(FdcGridThemes.white.summary.backgroundColor, isNull);
      expect(FdcGridThemes.white.statusBar.backgroundColor, isNull);
    });

    test('built-in light theme uses soft grey chrome surfaces', () {
      expect(FdcGridThemes.light.grid.backgroundColor, const Color(0xFFF9FAFB));
      expect(
        FdcGridThemes.light.header.backgroundColor,
        const Color(0xFFF3F4F6),
      );
      expect(
        FdcGridThemes.light.toolbar.backgroundColor,
        const Color(0xFFF3F4F6),
      );
      expect(
        FdcGridThemes.light.statusBar.backgroundColor,
        const Color(0xFFF3F4F6),
      );
      expect(
        FdcGridThemes.light.header.backgroundColor,
        isNot(FdcGridThemes.white.header.backgroundColor),
      );
    });

    testWidgets('checkbox border resolves consistently across value states', (
      tester,
    ) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final side = FdcGridControlTheme.checkboxSide(
        capturedContext,
        FdcGridThemes.light.controls,
        enabled: true,
      );

      final normalSide = side.resolve(const <WidgetState>{});
      final selectedSide = side.resolve(const <WidgetState>{
        WidgetState.selected,
      });
      final selectedHoveredSide = side.resolve(const <WidgetState>{
        WidgetState.selected,
        WidgetState.hovered,
      });

      expect(normalSide, isNotNull);
      expect(selectedSide, isNotNull);
      expect(selectedHoveredSide, isNotNull);
      expect(normalSide!.color, const Color(0xFF9CA3AF));
      expect(selectedSide!.color, const Color(0xFF9CA3AF));
      expect(selectedHoveredSide!.color, const Color(0xFF9CA3AF));
    });

    test('built-in dark themes define visible control colors', () {
      expect(FdcGridThemes.dark.controls.iconColor, isNotNull);
      expect(FdcGridThemes.dark.controls.checkboxBorderColor, isNotNull);
      expect(FdcGridThemes.dark.controls.checkboxFillColor, isNotNull);
      expect(FdcGridThemes.dark.controls.switchThumbColor, isNotNull);
      expect(FdcGridThemes.dark.counter.textStyle?.color, isNotNull);

      expect(FdcGridThemes.black.controls.iconColor, isNotNull);
      expect(FdcGridThemes.black.controls.checkboxBorderColor, isNotNull);
      expect(FdcGridThemes.black.controls.checkboxFillColor, isNotNull);
      expect(FdcGridThemes.black.controls.switchThumbColor, isNotNull);
      expect(FdcGridThemes.black.counter.textStyle?.color, isNotNull);
    });

    test('built-in dark header-adjacent surfaces align with header color', () {
      expect(
        FdcGridThemes.dark.header.groupBackgroundColor,
        FdcGridThemes.dark.header.backgroundColor,
      );
      expect(
        FdcGridThemes.dark.grid.rowIndicatorBackgroundColor,
        FdcGridThemes.dark.header.backgroundColor,
      );
      expect(
        FdcGridThemes.black.header.groupBackgroundColor,
        FdcGridThemes.black.header.backgroundColor,
      );
    });

    test('built-in themes keep disabled cell backgrounds transparent', () {
      expect(
        FdcGridStyle.defaults.disabledCellBackgroundColor,
        Colors.transparent,
      );
      expect(
        FdcGridThemes.light.grid.disabledCellBackgroundColor,
        Colors.transparent,
      );
      expect(
        FdcGridThemes.dark.grid.disabledCellBackgroundColor,
        Colors.transparent,
      );
      expect(
        FdcGridThemes.black.grid.disabledCellBackgroundColor,
        Colors.transparent,
      );
    });

    testWidgets('row indicator number uses active control color', (
      tester,
    ) async {
      const activeColor = Color(0xFF123456);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 64,
            height: 36,
            child: FdcGridRowIndicatorCell(
              model: const FdcGridRowIndicatorCellModel(
                rowIndex: 4,
                rowNumber: 5,
                options: FdcGridRowIndicatorOptions(
                  showRecordStatus: false,
                  showRowNumbers: true,
                ),
                selected: false,
                selectionEnabled: true,
                recordId: 10,
                status: null,
                textStyle: TextStyle(color: Colors.red, fontSize: 14),
                controlsStyle: FdcGridControlsStyle(
                  activeIconColor: activeColor,
                ),
              ),
              onTap: () {},
              onSelectedChanged: (_) {},
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('5'));
      expect(text.style?.color, activeColor);
      expect(text.style?.fontSize, 12);
    });

    testWidgets('row indicator clears stale current-row status', (
      tester,
    ) async {
      final interaction = ValueNotifier<FdcGridInteractionState>(
        const FdcGridInteractionState(
          selectedRowIndex: 4,
          focusState: FdcGridFocusState.cell,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 64,
            height: 36,
            child: FdcGridRowIndicatorRow(
              width: 64,
              rowHeight: 36,
              model: const FdcGridRowIndicatorCellModel(
                rowIndex: 4,
                rowNumber: 5,
                options: FdcGridRowIndicatorOptions(),
                selected: false,
                selectionEnabled: true,
                recordId: 10,
                status: FdcGridRowIndicatorStatus.browse,
                textStyle: null,
                controlsStyle: FdcGridControlsStyle(),
              ),
              interactionState: interaction,
              selectedRowBackgroundColor: Colors.transparent,
              onTap: () {},
              onSelectedChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_right), findsOneWidget);

      interaction.value = const FdcGridInteractionState(
        selectedRowIndex: 5,
        focusState: FdcGridFocusState.cell,
      );
      await tester.pump();

      expect(find.byIcon(Icons.arrow_right), findsNothing);
    });

    test('theme data carries controls through copy, merge and lerp', () {
      const base = FdcGridThemeData(
        controls: FdcGridControlsStyle(
          iconColor: Color(0xFF111111),
          checkboxFillColor: Color(0xFF222222),
        ),
      );
      const override = FdcGridThemeData(
        controls: FdcGridControlsStyle(
          activeIconColor: Color(0xFF333333),
          checkboxCheckColor: Color(0xFF444444),
        ),
      );

      expect(
        base
            .copyWith(
              controls: const FdcGridControlsStyle(
                iconColor: Color(0xFF555555),
              ),
            )
            .controls
            .iconColor,
        const Color(0xFF555555),
      );

      final merged = base.merge(override);
      expect(merged.controls.iconColor, const Color(0xFF111111));
      expect(merged.controls.activeIconColor, const Color(0xFF333333));
      expect(merged.controls.checkboxFillColor, const Color(0xFF222222));
      expect(merged.controls.checkboxCheckColor, const Color(0xFF444444));

      final lerped = base.lerp(override, 0.5);
      expect(lerped.controls.iconColor, isNotNull);
      expect(lerped.controls.activeIconColor, isNotNull);
    });

    test('theme data carries counter through copy merge and lerp', () {
      const base = FdcGridThemeData(
        counter: FdcCounterStyle(
          textStyle: TextStyle(color: Color(0xFF111111)),
        ),
      );
      const override = FdcGridThemeData(
        counter: FdcCounterStyle(
          textStyle: TextStyle(color: Color(0xFF333333)),
          height: 14,
        ),
      );

      expect(
        base
            .copyWith(
              counter: const FdcCounterStyle(
                textStyle: TextStyle(color: Color(0xFF555555)),
              ),
            )
            .counter
            .textStyle
            ?.color,
        const Color(0xFF555555),
      );

      final merged = base.merge(override);
      expect(merged.counter.textStyle?.color, const Color(0xFF333333));
      expect(merged.counter.height, 14);

      final lerped = base.lerp(override, 0.5);
      expect(lerped.counter.textStyle?.color, isNotNull);
      expect(lerped.counter.height, 13.0);
    });

    testWidgets('sort icon with position uses the resolved label color', (
      tester,
    ) async {
      const labelColor = Color(0xFFABCDEF);

      await tester.pumpWidget(
        const MaterialApp(
          home: FdcGridHeaderSortIconWithPosition(
            icon: Icons.north,
            color: labelColor,
            position: 2,
            showPosition: true,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.north));
      final position = tester.widget<Text>(find.text('2'));

      expect(icon.color, labelColor);
      expect(position.style?.color, labelColor);
    });
  });
}
