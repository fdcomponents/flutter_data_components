import 'fdc_grid_ux_test_support.dart';

void _registerHeaderInteractionTests() {
  group('Header interaction', () {
    testWidgets(
      'unsorted sortable header shows disabled sort affordance on hover',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Beta'},
              {'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          ],
        );

        expect(find.byIcon(Icons.north), findsNothing);

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: const Offset(590, 310));
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.text('Name')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));

        expect(find.byIcon(Icons.north), findsOneWidget);

        await gesture.moveTo(const Offset(590, 310));
        await uxPumpPendingFrames(tester);

        expect(find.byIcon(Icons.north), findsNothing);
        await gesture.removePointer();
      },
    );

    testWidgets('Space opens combo dropdown when autoEdit is false', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 20, name: 'status')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'status': 'open'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        options: const FdcGridOptions(autoEdit: false),
        columns: const <FdcGridColumn<dynamic>>[
          FdcComboColumn<String>(
            fieldName: 'status',
            options: <FdcOption<String>>[
              FdcOption<String>(value: 'open', label: 'Open'),
              FdcOption<String>(value: 'closed', label: 'Closed'),
            ],
          ),
        ],
      );

      await tester.tap(find.text('Open'));
      await uxPumpPendingFrames(tester);

      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Closed'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await uxPumpPendingFrames(tester);

      expect(find.text('Closed'), findsOneWidget);
      expect(dataSet.fieldValue('status'), 'open');
    });
  });
}

void main() {
  group('FdcGrid widget UX / Header Interaction', () {
    _registerHeaderInteractionTests();
  });
}
