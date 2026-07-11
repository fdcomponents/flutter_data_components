import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keyboard shortcut formats display labels', () {
    expect(FdcKeyboardShortcut.f4.displayLabel, 'F4');
    expect(
      const FdcKeyboardShortcut(
        FdcKeyboardKey.f4,
        control: true,
        shift: true,
      ).displayLabel,
      'Ctrl + Shift + F4',
    );
    expect(
      const FdcKeyboardShortcut(FdcKeyboardKey.keyL, alt: true).displayLabel,
      'Alt + L',
    );
  });
}
