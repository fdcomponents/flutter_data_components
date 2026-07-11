import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/src/common/fdc_option.dart';
import 'package:flutter_data_components/src/common/widgets/combo/fdc_combo_field.dart';
import 'package:flutter_data_components/src/common/widgets/combo/fdc_combo_popup.dart';
import 'package:flutter_data_components/src/common/widgets/combo/fdc_combo_search_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('combo field does not overflow when narrowed aggressively', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 12,
            child: FdcComboField<String>(
              options: const <FdcOption<String>>[
                FdcOption<String>(value: 'closed', label: 'Closed'),
              ],
              value: 'closed',
              onChanged: (_) {},
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('combo search options disables inline search by default', () {
    const options = FdcComboSearchOptions();

    expect(options.searchableInline, isFalse);
  });

  test('combo popup search matches label prefix case-insensitively', () {
    final entries =
        fdcFilterComboEntriesForSearch<String>(const <FdcOption<String>>[
          FdcOption<String>(value: 'open', label: 'Open'),
          FdcOption<String>(value: 'closed', label: 'Closed'),
          FdcOption<String>(value: 'reopened', label: 'Reopened'),
          FdcOption<String>(value: 'pending-close', label: 'Pending Close'),
        ], 'cl');

    expect(entries.map((entry) => entry.option.label), const ['Closed']);
  });

  test('combo popup search does not match text in the middle of label', () {
    final entries =
        fdcFilterComboEntriesForSearch<String>(const <FdcOption<String>>[
          FdcOption<String>(value: 'closed', label: 'Closed'),
          FdcOption<String>(value: 'pending-close', label: 'Pending Close'),
        ], 'close');

    expect(entries.map((entry) => entry.option.label), const ['Closed']);
  });

  test('combo popup search can match text inside label in contains mode', () {
    final entries = fdcFilterComboEntriesForSearch<String>(
      const <FdcOption<String>>[
        FdcOption<String>(value: 'closed', label: 'Closed'),
        FdcOption<String>(value: 'pending-close', label: 'Pending Close'),
      ],
      'close',
      mode: FdcComboSearchMode.contains,
    );

    expect(entries.map((entry) => entry.option.label), const [
      'Closed',
      'Pending Close',
    ]);
  });

  test(
    'combo popup search trims input and preserves empty-search behavior',
    () {
      const options = <FdcOption<String>>[
        FdcOption<String>(value: 'open', label: 'Open'),
        FdcOption<String>(value: 'closed', label: 'Closed'),
      ];

      final trimmed = fdcFilterComboEntriesForSearch<String>(options, '  OP  ');
      final empty = fdcFilterComboEntriesForSearch<String>(options, '   ');

      expect(trimmed.map((entry) => entry.option.label), const ['Open']);
      expect(empty.map((entry) => entry.option.label), const [
        'Open',
        'Closed',
      ]);
    },
  );

  test('combo popup arrow navigation stops at last item', () {
    final entries =
        fdcFilterComboEntriesForSearch<String>(const <FdcOption<String>>[
          FdcOption<String>(value: 'open', label: 'Open'),
          FdcOption<String>(value: 'closed', label: 'Closed'),
        ], '');

    expect(fdcNextComboPopupHighlightIndex(entries, 0, 1), 1);
    expect(fdcNextComboPopupHighlightIndex(entries, 1, 1), isNull);
  });

  test('combo popup arrow navigation stops at first item', () {
    final entries =
        fdcFilterComboEntriesForSearch<String>(const <FdcOption<String>>[
          FdcOption<String>(value: 'open', label: 'Open'),
          FdcOption<String>(value: 'closed', label: 'Closed'),
        ], '');

    expect(fdcNextComboPopupHighlightIndex(entries, 1, -1), 0);
    expect(fdcNextComboPopupHighlightIndex(entries, 0, -1), isNull);
  });

  test('combo popup home and end navigation jump to boundaries', () {
    final entries =
        fdcFilterComboEntriesForSearch<String>(const <FdcOption<String>>[
          FdcOption<String>(value: 'open', label: 'Open'),
          FdcOption<String>(value: 'pending', label: 'Pending'),
          FdcOption<String>(value: 'closed', label: 'Closed'),
        ], '');

    expect(fdcComboPopupBoundaryHighlightIndex(entries, last: false), 0);
    expect(fdcComboPopupBoundaryHighlightIndex(entries, last: true), 2);
  });

  test('combo popup page navigation clamps without wrapping', () {
    final entries =
        fdcFilterComboEntriesForSearch<String>(const <FdcOption<String>>[
          FdcOption<String>(value: 'one', label: 'One'),
          FdcOption<String>(value: 'two', label: 'Two'),
          FdcOption<String>(value: 'three', label: 'Three'),
          FdcOption<String>(value: 'four', label: 'Four'),
          FdcOption<String>(value: 'five', label: 'Five'),
        ], '');

    expect(fdcComboPopupPageHighlightIndex(entries, 0, 1, 3), 3);
    expect(fdcComboPopupPageHighlightIndex(entries, 3, 1, 3), 4);
    expect(fdcComboPopupPageHighlightIndex(entries, 4, 1, 3), 4);
    expect(fdcComboPopupPageHighlightIndex(entries, 4, -1, 3), 1);
    expect(fdcComboPopupPageHighlightIndex(entries, 1, -1, 3), 0);
  });

  test('combo popup inline search extracts printable key characters', () {
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyC,
      logicalKey: LogicalKeyboardKey.keyC,
      character: 'c',
      timeStamp: Duration.zero,
    );

    expect(fdcComboPopupInlineSearchCharacter(event), 'c');
  });

  test('combo popup inline search accepts space characters', () {
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.space,
      logicalKey: LogicalKeyboardKey.space,
      character: ' ',
      timeStamp: Duration.zero,
    );

    expect(fdcComboPopupInlineSearchCharacter(event), ' ');
  });

  test('combo popup inline search extracts repeat key characters', () {
    const event = KeyRepeatEvent(
      physicalKey: PhysicalKeyboardKey.keyC,
      logicalKey: LogicalKeyboardKey.keyC,
      character: 'c',
      timeStamp: Duration.zero,
    );

    expect(fdcComboPopupInlineSearchCharacter(event), 'c');
  });

  test('combo popup inline search ignores non-printable keys', () {
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.arrowDown,
      logicalKey: LogicalKeyboardKey.arrowDown,
      timeStamp: Duration.zero,
    );

    expect(fdcComboPopupInlineSearchCharacter(event), isNull);
  });

  test('combo popup absorbs tab traversal while open', () {
    const tab = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.tab,
      logicalKey: LogicalKeyboardKey.tab,
      timeStamp: Duration.zero,
    );

    expect(fdcComboPopupAbsorbsTraversalKey(tab), isTrue);
  });

  test('combo popup keeps search navigation keys local to search field', () {
    const home = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.home,
      logicalKey: LogicalKeyboardKey.home,
      timeStamp: Duration.zero,
    );
    const end = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.end,
      logicalKey: LogicalKeyboardKey.end,
      timeStamp: Duration.zero,
    );
    const pageUp = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.pageUp,
      logicalKey: LogicalKeyboardKey.pageUp,
      timeStamp: Duration.zero,
    );
    const pageDown = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.pageDown,
      logicalKey: LogicalKeyboardKey.pageDown,
      timeStamp: Duration.zero,
    );
    const arrowDown = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.arrowDown,
      logicalKey: LogicalKeyboardKey.arrowDown,
      timeStamp: Duration.zero,
    );

    expect(fdcComboPopupKeepsSearchNavigationLocal(home), isTrue);
    expect(fdcComboPopupKeepsSearchNavigationLocal(end), isTrue);
    expect(fdcComboPopupKeepsSearchNavigationLocal(pageUp), isTrue);
    expect(fdcComboPopupKeepsSearchNavigationLocal(pageDown), isTrue);
    expect(fdcComboPopupKeepsSearchNavigationLocal(arrowDown), isFalse);
  });
}
