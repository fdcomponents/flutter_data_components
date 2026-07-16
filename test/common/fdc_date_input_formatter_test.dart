// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/services.dart';
import 'package:flutter_data_components/src/common/format/fdc_date_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDateInputFormatter time seconds', () {
    test('formats six time digits as HH:mm:ss', () {
      final formatter = FdcDateInputFormatter('HH:mm:ss');

      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '123456',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );

      expect(result.text, '12:34:56');
      expect(result.selection.extentOffset, 8);
    });

    test('keeps seconds editable after formatted minute input', () {
      final formatter = FdcDateInputFormatter('HH:mm:ss');

      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '12:34:',
          selection: TextSelection.collapsed(offset: 6),
        ),
        const TextEditingValue(
          text: '12:34:5',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );

      expect(result.text, '12:34:5');
      expect(result.selection.extentOffset, 7);
    });
  });
}
