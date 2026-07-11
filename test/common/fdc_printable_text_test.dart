import 'package:flutter_data_components/src/common/text/fdc_printable_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clipboard sanitizer removes control and format characters', () {
    expect(
      fdcPrintableClipboardText(
        'A\u0000\u0008\u007f\u0085\u200b\u202e\u2060\ufeffB',
      ),
      'AB',
    );
  });

  test('clipboard sanitizer removes tab and line breaks for one cell', () {
    expect(fdcPrintableClipboardText('A\tB\r\nC'), 'ABC');
  });

  test('clipboard sanitizer can preserve tabular delimiters', () {
    expect(
      fdcPrintableClipboardText(
        'A\tB\r\nC\u200b',
        preserveTabAndLineBreaks: true,
      ),
      'A\tB\r\nC',
    );
  });

  test('clipboard sanitizer preserves printable Unicode text', () {
    expect(
      fdcPrintableClipboardText('€ 1.500,21 – Seattle 😀'),
      '€ 1.500,21 – Seattle 😀',
    );
  });
}
