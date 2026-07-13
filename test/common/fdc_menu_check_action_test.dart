import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_data_components/src/common/menu/fdc_menu_entry.dart';
import 'package:flutter_data_components/src/common/menu/fdc_menu_overlay.dart';
import 'package:flutter_data_components/src/common/menu/fdc_menu_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
  testWidgets('checked menu action shows a leading checkmark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FdcMenuAnchor(
              openOnTap: true,
              entries: <FdcMenuEntry>[
                FdcMenuCheckAction(
                  text: 'Rating 4',
                  checked: true,
                  child: Text('★★★★☆'),
                ),
              ],
              child: SizedBox(
                key: ValueKey<String>('menu-anchor'),
                width: 120,
                height: 32,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey<String>('menu-anchor'))),
    );
    await pumpPendingFrames(tester);

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('★★★★☆'), findsOneWidget);
  });

  testWidgets('menu title is emphasized and non-interactive', (tester) async {
    var actionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FdcMenuAnchor(
              openOnTap: true,
              entries: <FdcMenuEntry>[
                const FdcMenuTitle(text: 'Filters'),
                FdcMenuAction(
                  text: 'Clear filter',
                  onPressed: () => actionCount += 1,
                ),
              ],
              child: const SizedBox(
                key: ValueKey<String>('title-menu-anchor'),
                width: 120,
                height: 32,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey<String>('title-menu-anchor'))),
    );
    await pumpPendingFrames(tester);

    final title = tester.widget<Text>(find.text('Filters'));
    expect(title.style?.fontWeight, FontWeight.w600);
    expect(
      find.ancestor(
        of: find.text('Filters'),
        matching: find.byType(MenuItemButton),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Filters'));
    await tester.pump();

    expect(actionCount, 0);
    expect(find.text('Clear filter'), findsOneWidget);
  });
  testWidgets(
    'secondary pointer opens dynamic menu above nested gesture child',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FdcMenuAnchor(
                entriesBuilder: () => const <FdcMenuEntry>[
                  FdcMenuAction(text: 'Dynamic action'),
                ],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {},
                  child: const SizedBox(
                    key: ValueKey<String>('secondary-menu-anchor'),
                    width: 160,
                    height: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey<String>('secondary-menu-anchor')),
        ),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump();

      expect(find.text('Dynamic action'), findsOneWidget);
    },
  );

  testWidgets('dismissAll closes an open FDC menu', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FdcMenuAnchor(
              openOnTap: true,
              entries: <FdcMenuEntry>[
                FdcMenuAction(text: 'Dismissible action'),
              ],
              child: SizedBox(
                key: ValueKey<String>('dismiss-menu-anchor'),
                width: 120,
                height: 32,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey<String>('dismiss-menu-anchor')),
      ),
    );
    await pumpPendingFrames(tester);
    expect(find.text('Dismissible action'), findsOneWidget);

    FdcMenuOverlay.dismissAll();
    await pumpPendingFrames(tester);

    expect(find.text('Dismissible action'), findsNothing);
  });
}
