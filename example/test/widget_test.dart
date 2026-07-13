import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('customers example opens and renders the CRUD grid', (
    tester,
  ) async {
    await tester.pumpWidget(const CustomersExampleApp());
    await _pumpPendingFrames(tester);

    expect(find.text('FD Components inline CRUD example'), findsOneWidget);
    expect(find.byType(FdcGrid), findsOneWidget);
  });
}

Future<void> _pumpPendingFrames(
  WidgetTester tester, {
  int maxFrames = 120,
}) async {
  for (var frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (!tester.binding.hasScheduledFrame) {
      return;
    }
  }

  throw TestFailure(
    'The example application did not become idle within $maxFrames frames. '
    'This usually indicates a repeating animation, an unresolved async '
    'operation, or a smoke test that should wait for a more specific signal.',
  );
}
