import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clipboard = _TestClipboard();

  setUp(() {
    clipboard.text = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, clipboard.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('Community grid copies selected cell without range selection', (
    tester,
  ) async {
    final dataSet = _dataSet();

    await tester.pumpWidget(_host(dataSet));
    await pumpPendingFrames(tester);

    await tester.tap(find.text('Alpha').first);
    await pumpPendingFrames(tester);

    await _sendShortcut(tester, LogicalKeyboardKey.keyC);
    await pumpPendingFrames(tester);

    expect(clipboard.text, 'Alpha');
  });

  testWidgets(
    'Community grid pastes into selected cell without range selection',
    (tester) async {
      final dataSet = _dataSet();
      clipboard.text = 'Gamma';

      await tester.pumpWidget(_host(dataSet));
      await pumpPendingFrames(tester);

      await tester.tap(find.text('Alpha').first);
      await pumpPendingFrames(tester);

      await _sendShortcut(tester, LogicalKeyboardKey.keyV);
      await pumpPendingFrames(tester);

      expect(dataSet['name'], 'Gamma');
      expect(find.text('Gamma'), findsOneWidget);
    },
  );
}

FdcDataSet _dataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(name: 'name', size: 80),
    ],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

Widget _host(FdcDataSet dataSet) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 360,
        height: 180,
        child: FdcGrid(
          dataSet: dataSet,
          header: const FdcGridHeader(visible: false),
          toolbar: const FdcGridToolbar(visible: false),
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        ),
      ),
    ),
  );
}

Future<void> _sendShortcut(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

class _TestClipboard {
  String? text;

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'Clipboard.setData':
        final data = Map<Object?, Object?>.from(call.arguments as Map);
        text = data['text'] as String?;
        return null;
      case 'Clipboard.getData':
        return <String, Object?>{'text': text};
      default:
        return null;
    }
  }
}
