import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('customers example opens and renders the CRUD grid', (
    tester,
  ) async {
    await tester.pumpWidget(const CustomersExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('FD Components inline CRUD example'), findsOneWidget);
    expect(find.byType(FdcGrid), findsOneWidget);
  });
}
