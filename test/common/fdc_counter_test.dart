import 'package:flutter/material.dart';
import 'package:flutter_data_components/src/common/widgets/counter/fdc_counter.dart';
import 'package:flutter_data_components/src/common/widgets/counter/fdc_counter_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('counter does not wrap or overflow when width is too narrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: SizedBox(
            width: 12,
            child: FdcCounter(text: '123/999', style: FdcCounterStyle()),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final counterText = find.text('123/999');
    if (counterText.evaluate().isNotEmpty) {
      final text = tester.widget<Text>(counterText);
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    }
  });

  testWidgets('counter remains visible when width is sufficient', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: SizedBox(
            width: 120,
            child: FdcCounter(text: '3/20', style: FdcCounterStyle()),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('3/20'));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
  });
}
