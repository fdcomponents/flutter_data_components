import 'package:flutter/widgets.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FdcApp wraps its child in the default focus traversal group', (
    tester,
  ) async {
    FdcFocusOptions? resolvedOptions;

    await tester.pumpWidget(
      FdcApp(
        child: Builder(
          builder: (context) {
            resolvedOptions = FdcFocusScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolvedOptions, const FdcFocusOptions());
    final fdcTraversalGroup = find.byWidgetPredicate(
      (widget) =>
          widget is FocusTraversalGroup &&
          widget.policy is WidgetOrderTraversalPolicy,
    );

    expect(fdcTraversalGroup, findsOneWidget);

    final group = tester.widget<FocusTraversalGroup>(fdcTraversalGroup);
    expect(group.policy, isA<WidgetOrderTraversalPolicy>());
  });

  testWidgets('FdcApp can disable the generated focus traversal group', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FdcApp(
        focus: FdcFocusOptions(wrapTraversalGroup: false),
        child: SizedBox.shrink(),
      ),
    );

    final fdcTraversalGroup = find.byWidgetPredicate(
      (widget) =>
          widget is FocusTraversalGroup &&
          widget.policy is WidgetOrderTraversalPolicy,
    );

    expect(fdcTraversalGroup, findsNothing);
  });

  testWidgets('FdcFocusScope can override focus traversal locally', (
    tester,
  ) async {
    FdcFocusOptions? resolvedOptions;

    await tester.pumpWidget(
      FdcFocusScope(
        options: const FdcFocusOptions(
          traversalPolicy: FdcFocusTraversalPolicy.ordered,
        ),
        child: Builder(
          builder: (context) {
            resolvedOptions = FdcFocusScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      resolvedOptions,
      const FdcFocusOptions(traversalPolicy: FdcFocusTraversalPolicy.ordered),
    );
    final fdcTraversalGroup = find.byWidgetPredicate(
      (widget) =>
          widget is FocusTraversalGroup &&
          widget.policy is OrderedTraversalPolicy,
    );

    expect(fdcTraversalGroup, findsOneWidget);

    final group = tester.widget<FocusTraversalGroup>(fdcTraversalGroup);
    expect(group.policy, isA<OrderedTraversalPolicy>());
  });
}
