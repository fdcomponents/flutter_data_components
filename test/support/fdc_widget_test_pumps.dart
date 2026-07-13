import 'package:flutter_test/flutter_test.dart';

/// Pumps scheduled frames until the widget tree becomes idle.
///
/// Unlike [WidgetTester.pumpAndSettle], this helper has an explicit frame
/// budget and reports a focused failure when a repeating animation or
/// unresolved asynchronous operation keeps scheduling work.
Future<void> pumpPendingFrames(
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
    'The widget tree did not become idle within $maxFrames frames. '
    'This usually indicates a repeating animation, an unresolved async '
    'operation, or a test that should wait for a more specific condition.',
  );
}
