import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestExportStyle extends FdcExportFormatStyle {
  const _TestExportStyle();
}

void main() {
  testWidgets('FdcApp exposes application export style', (tester) async {
    const configured = FdcExportStyle(pdf: _TestExportStyle());
    FdcExportStyle? resolved;

    await tester.pumpWidget(
      MaterialApp(
        home: FdcApp(
          exportStyle: configured,
          child: Builder(
            builder: (context) {
              resolved = FdcApp.exportStyleOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(resolved, configured);
  });
}
