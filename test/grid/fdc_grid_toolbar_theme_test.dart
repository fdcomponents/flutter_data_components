import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_items.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_toolbar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGrid toolbar theme', () {
    testWidgets('standard and custom toolbar items receive themed colors', (
      tester,
    ) async {
      const textColor = Color(0xFF123456);
      const iconColor = Color(0xFF234567);
      const disabledTextColor = Color(0xFF345678);
      const disabledIconColor = Color(0xFF456789);

      Color? customTextColor;
      Color? customIconColor;
      Color? customDisabledTextColor;
      Color? customDisabledIconColor;

      await tester.pumpWidget(
        MaterialApp(
          home: FdcGridToolbarShell(
            style: const FdcGridToolbarStyle(
              itemTextColor: textColor,
              itemIconColor: iconColor,
              disabledItemTextColor: disabledTextColor,
              disabledItemIconColor: disabledIconColor,
            ),
            separatorColor: Colors.transparent,
            dataSet: _createToolbarDataSet(),
            toolbar: FdcGridToolbar(
              items: <FdcGridItem>[
                FdcGridButton(
                  id: 'enabled',
                  icon: Icons.add,
                  label: 'Enabled',
                  onPressed: () {},
                ),
                const FdcGridButton(
                  id: 'disabled',
                  icon: Icons.delete,
                  label: 'Disabled',
                ),
                FdcGridCustomItem(
                  builder: (context) {
                    final itemTheme = FdcGridItemTheme.of(context);
                    final textButtonStyle = TextButtonTheme.of(context).style;
                    final iconButtonStyle = IconButtonTheme.of(context).style;

                    customTextColor = itemTheme.textColor;
                    customIconColor = itemTheme.iconColor;
                    customDisabledTextColor = textButtonStyle?.foregroundColor
                        ?.resolve(const <WidgetState>{WidgetState.disabled});
                    customDisabledIconColor = iconButtonStyle?.foregroundColor
                        ?.resolve(const <WidgetState>{WidgetState.disabled});

                    return const SizedBox(
                      key: ValueKey('custom-toolbar-theme-probe'),
                    );
                  },
                ),
              ],
            ),
            onSearchChanged: (_, {required mode, required caseSensitive}) {},
            onSearchCleared: () {},
            recordCountProvider: () => 0,
            canSearch: true,
            canExport: false,
          ),
        ),
      );

      final enabledLabel = tester.widget<Text>(find.text('Enabled'));
      final disabledLabel = tester.widget<Text>(find.text('Disabled'));
      final enabledIcon = tester.widget<Icon>(find.byIcon(Icons.add));
      final disabledIcon = tester.widget<Icon>(find.byIcon(Icons.delete));

      expect(enabledLabel.style?.color, textColor);
      expect(disabledLabel.style?.color, disabledTextColor);
      expect(enabledIcon.color, iconColor);
      expect(disabledIcon.color, disabledIconColor);
      expect(customTextColor, textColor);
      expect(customIconColor, iconColor);
      expect(customDisabledTextColor, disabledTextColor);
      expect(customDisabledIconColor, disabledIconColor);
    });

    testWidgets('toolbar rejects multiple global search items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FdcGridToolbarShell(
            style: const FdcGridToolbarStyle(),
            separatorColor: Colors.transparent,
            dataSet: _createToolbarDataSet(),
            toolbar: const FdcGridToolbar(
              items: <FdcGridItem>[
                FdcGridSearchBar(),
                FdcGridSearchBar(placement: FdcGridItemPlacement.center),
              ],
            ),
            onSearchChanged: (_, {required mode, required caseSensitive}) {},
            onSearchCleared: () {},
            recordCountProvider: () => 0,
            canSearch: true,
            canExport: false,
          ),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect(exception.toString(), contains('at most one FdcGridSearchBar'));
    });

    test('toolbar style carries item colors through copy, merge and lerp', () {
      const base = FdcGridToolbarStyle(
        itemTextColor: Color(0xFF111111),
        itemIconColor: Color(0xFF222222),
      );
      const override = FdcGridToolbarStyle(
        disabledItemTextColor: Color(0xFF333333),
        disabledItemIconColor: Color(0xFF444444),
      );

      expect(
        base.copyWith(itemTextColor: const Color(0xFF555555)).itemTextColor,
        const Color(0xFF555555),
      );

      final merged = base.merge(override);
      expect(merged.itemTextColor, const Color(0xFF111111));
      expect(merged.itemIconColor, const Color(0xFF222222));
      expect(merged.disabledItemTextColor, const Color(0xFF333333));
      expect(merged.disabledItemIconColor, const Color(0xFF444444));

      final lerped = base.lerp(override, 0.5);
      expect(lerped.itemTextColor, isNotNull);
      expect(lerped.disabledItemIconColor, isNotNull);
    });

    test(
      'built-in dark toolbar themes define visible disabled item colors',
      () {
        expect(FdcGridThemes.dark.toolbar.disabledItemTextColor, isNotNull);
        expect(FdcGridThemes.dark.toolbar.disabledItemIconColor, isNotNull);
        expect(FdcGridThemes.black.toolbar.disabledItemTextColor, isNotNull);
        expect(FdcGridThemes.black.toolbar.disabledItemIconColor, isNotNull);
      },
    );
  });
}

FdcDataSet _createToolbarDataSet() {
  return FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 20)],
  );
}
