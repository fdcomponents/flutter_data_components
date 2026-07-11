part of '../fdc_grid_widget_ux_test.dart';

void _registerEditingValidationTests() {
  group('Editing and validation', () {
    testWidgets('ArrowDown on pristine append row keeps insert buffer active', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
            {'id': 2, 'name': 'Beta'},
            {'id': 3, 'name': 'Gamma'},
            {'id': 4, 'name': 'Delta'},
            {'id': 5, 'name': 'Epsilon'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Epsilon'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 6);
      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 5);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 6);
      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 5);
    });

    testWidgets(
      'Auto appended insert row keeps insert indicator while editing',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id', label: 'ID'),
            FdcStringField(size: 255, name: 'name', label: 'Name'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(dataSet.state, FdcDataSetState.insert);
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      },
    );

    testWidgets(
      'Grid auto append does not validate a pristine required insert row',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(
              size: 255,
              name: 'name',
              label: 'Name',
              required: true,
            ),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 2);
        expect(dataSet.state, FdcDataSetState.insert);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.text('Validation error'), findsNothing);
      },
    );

    testWidgets(
      'Grid auto append displays onNewRecord defaults before deferred editor starts',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(
              size: 255,
              name: 'name',
              label: 'Name',
              required: true,
            ),
          ],
          onNewRecord: (dataSet) {
            dataSet.setFieldValue('name', 'New customer');
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 2);
        expect(dataSet.state, FdcDataSetState.insert);
        expect(dataSet.fieldValue('name'), 'New customer');
        expect(find.text('New customer'), findsWidgets);
        expect(find.byType(TextFormField), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        final editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'x');
      },
    );

    testWidgets('Invalid active insert blocks activating another row', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(
            size: 255,
            name: 'name',
            label: 'Name',
            required: true,
          ),
        ],
        onNewRecord: (dataSet) {
          dataSet.setFieldValue('name', 'Temp');
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
            {'name': 'Beta'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 2);
      expect(find.byType(TextFormField), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 2);
      expect(dataSet.recordCount, 3);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(find.text('Validation error'), findsOneWidget);
      expect(find.text('Field Name is required.'), findsOneWidget);
    });

    testWidgets('Invalid active insert can blur when tapping outside grid', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(
            size: 255,
            name: 'name',
            label: 'Name',
            required: true,
          ),
        ],
        onNewRecord: (dataSet) {
          dataSet.setFieldValue('name', 'Temp');
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
            {'name': 'Beta'},
          ],
        ),
      );
      dataSet.open();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 2);
      expect(dataSet.recordCount, 3);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Validation error'), findsNothing);
      expect(find.text('Field Name is required.'), findsNothing);
    });

    testWidgets(
      'Pristine required insert row is cancelled when leaving before changes',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(
              size: 255,
              name: 'name',
              label: 'Name',
              required: true,
            ),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
              {'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(dataSet.state, FdcDataSetState.insert);
        expect(FdcDataSetInternal.activeIndex(dataSet), 2);
        expect(dataSet.recordCount, 3);

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();

        // A completely untouched insert row is not validated. It is cancelled
        // automatically when the user leaves it.
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 2);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.text('Field Name is required.'), findsNothing);
      },
    );

    testWidgets('Calculated field refreshes and stays non-editable', (
      tester,
    ) async {
      final dataSet = _calculatedDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'quantity'),
          FdcDecimalColumn<dynamic>(fieldName: 'total'),
        ],
      );

      expect(find.text('50.00'), findsOneWidget);

      await tester.tap(find.text('50.00'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '6');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(dataSet.fieldByName('total').asNum, 60);
      expect(find.text('60.00'), findsOneWidget);
    });

    testWidgets('Decimal column formats and edits scale-limited decimal text', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 5, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1.2},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
      );

      expect(find.text('1.20'), findsOneWidget);

      await tester.tap(find.text('1.20'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), '123.67');
      await tester.pump();

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      expect(editableText.controller.text, '123.67');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        (FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount') as FdcDecimal)
            .toNum(),
        123.67,
      );
      expect(find.text('123.67'), findsOneWidget);
    });

    testWidgets('Decimal column accepts exact scale boundary on commit', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 6, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1.2},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
      );

      await tester.tap(find.text('1.20'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), '1.01');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        (FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount') as FdcDecimal)
            .toNum(),
        1.01,
      );
      expect(find.text('1.01'), findsOneWidget);
    });

    testWidgets('Decimal column rejects precision overflow on commit', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 5, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1.2},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
      );

      await tester.tap(find.text('1.20'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      editableText.controller.text = '12345.67';
      editableText.controller.selection = const TextSelection.collapsed(
        offset: 8,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      // The rejected commit intentionally keeps the in-place editor focused,
      // so waiting for a fully settled frame can hang on the active text
      // input/caret pipeline. Pump only the validation response frame.
      await tester.pump();

      expect(
        (FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount') as FdcDecimal)
            .toNum(),
        1.2,
      );
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('Decimal header filter uses decimal column format', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1234.56},
            {'amount': 2000.00},
            {'amount': 12.30},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            label: 'Amount',
            formatSettings: FdcFormatSettings(
              decimalSeparator: ',',
              thousandSeparator: '.',
            ),
          ),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).last, '1.234,56');
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(
        (FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount') as FdcDecimal)
            .toNum(),
        1234.56,
      );
      expect(find.text('1.234,56'), findsWidgets);
      expect(find.text('2.000,00'), findsNothing);
    });

    testWidgets('Decimal header filter displays grouped column decimal text', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1500.21},
            {'amount': 2000.00},
          ],
        ),
      );
      dataSet.open();

      const formats = FdcFormatSettings();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            label: 'Amount',
            formatSettings: formats,
          ),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).last, '1500.21');
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(find.text('1500.21'), findsWidgets);

      await tester.tap(find.text('1,500.21'));
      await tester.pumpAndSettle();

      expect(find.text('1,500.21'), findsWidgets);
    });

    testWidgets('between decimal range fields use column decimal format', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1000.00},
            {'amount': 1500.25},
            {'amount': 2500.00},
          ],
        ),
      );
      dataSet.open();

      const formats = FdcFormatSettings(
        decimalSeparator: ',',
        thousandSeparator: '.',
      );

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            label: 'Amount',
            formatSettings: formats,
          ),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Between'));
      await tester.pumpAndSettle();

      final fields = _headerRangeFilterTextFields();
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '1000,00');
      await tester.enterText(fields.at(1), '2000,00');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.text('1.000,00'), findsWidgets);
      expect(find.text('2000,00'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 2);
      expect(find.text('1.000,00'), findsWidgets);
      expect(find.text('1.500,25'), findsOneWidget);
      expect(find.text('2.500,00'), findsNothing);
    });

    testWidgets('between operator opens range form and applies only on Apply', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10.00},
            {'amount': 20.00},
            {'amount': 30.00},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Between'));
      await tester.pumpAndSettle();

      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      final fields = _headerRangeFilterTextFields();
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '15.00');
      await tester.enterText(fields.at(1), '25.00');
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 3);
      expect(find.text('10.00'), findsOneWidget);
      expect(find.text('30.00'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsOneWidget);
      expect(find.text('10.00'), findsNothing);
      expect(find.text('30.00'), findsNothing);
    });

    testWidgets('between apply requires both fields with valid values', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10.00},
            {'amount': 20.00},
            {'amount': 30.00},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Between'));
      await tester.pumpAndSettle();

      FilledButton applyButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Apply'),
      );

      expect(applyButton().onPressed, isNull);

      final fields = _headerRangeFilterTextFields();
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '15.00');
      await tester.pumpAndSettle();
      expect(applyButton().onPressed, isNull);

      await tester.enterText(fields.at(1), 'abc');
      await tester.pumpAndSettle();
      expect(applyButton().onPressed, isNull);

      await tester.enterText(fields.at(1), '25.00');
      await tester.pumpAndSettle();
      expect(applyButton().onPressed, isNotNull);

      applyButton().onPressed!();
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsOneWidget);
    });

    testWidgets(
      'between apply consumes auto-open token before layout rebuilds',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'amount': 10.00},
              {'amount': 20.00},
              {'amount': 30.00},
            ],
          ),
        );
        dataSet.open();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
          ],
          header: _zeroDebounceHeader,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Between'));
        await tester.pumpAndSettle();

        final fields = _headerRangeFilterTextFields();
        await tester.enterText(fields.at(0), '15.00');
        await tester.enterText(fields.at(1), '25.00');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        expect(find.text('From'), findsNothing);
        expect(find.text('To'), findsNothing);
        expect(dataSet.recordCount, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
          ],
          header: _zeroDebounceHeader,
        );
        await tester.pumpAndSettle();

        expect(find.text('From'), findsNothing);
        expect(find.text('To'), findsNothing);
        expect(dataSet.recordCount, 1);
      },
    );

    testWidgets(
      'switching from between to scalar operator clears range value',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'amount': 10.00},
              {'amount': 20.00},
              {'amount': 30.00},
            ],
          ),
        );
        dataSet.open();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
          ],
          header: _zeroDebounceHeader,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Between'));
        await tester.pumpAndSettle();

        final fields = _headerRangeFilterTextFields();
        await tester.enterText(fields.at(0), '15.00');
        await tester.enterText(fields.at(1), '25.00');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 1);
        expect(find.text('20.00'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Equals').last);
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 3);
        expect(find.text('10.00'), findsOneWidget);
        expect(find.text('20.00'), findsOneWidget);
        expect(find.text('30.00'), findsOneWidget);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).last)
              .controller
              .text,
          '',
        );
      },
    );

    testWidgets('selecting an empty scalar filter operator focuses its input', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await _pumpFilterGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      final nameFilter = tester.widget<EditableText>(
        find.byType(EditableText).at(1),
      );
      expect(nameFilter.controller.text, isEmpty);
      expect(nameFilter.focusNode.hasFocus, isFalse);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Equals').last);
      await tester.pumpAndSettle();

      expect(nameFilter.focusNode.hasFocus, isTrue);
    });

    testWidgets('text header filter uses grid-safe edit context menu', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await _pumpFilterGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      final textField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(textField.contextMenuBuilder, isNotNull);
      expect(textField.groupId, same(fdcGridTapRegionGroup));
    });

    testWidgets(
      'clearing text header filter value preserves selected scalar operator and focus',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        final filterFinder = find.byType(EditableText).at(1);
        await tester.tap(find.byIcon(Icons.more_vert).at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Equals').last);
        await tester.pumpAndSettle();

        await tester.enterText(filterFinder, 'Alpha');
        await tester.pumpAndSettle();
        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.equals,
        );
        expect(dataSet.recordCount, 1);

        await tester.enterText(filterFinder, '');
        await tester.pumpAndSettle();

        final clearedFilter = tester.widget<EditableText>(filterFinder);
        expect(clearedFilter.controller.text, isEmpty);
        expect(clearedFilter.focusNode.hasFocus, isTrue);
        expect(dataSet.recordCount, 2);

        await tester.enterText(filterFinder, 'Al');
        await tester.pumpAndSettle();

        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.equals,
        );
        expect(dataSet.recordCount, 0);
      },
    );

    testWidgets('between cancel restores previous header filter state', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10.00},
            {'amount': 20.00},
            {'amount': 30.00},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).last, '20.00');
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsWidgets);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Between'));
      await tester.pumpAndSettle();

      expect(find.text('From'), findsOneWidget);
      expect(find.text('20.00'), findsWidgets);
      expect(find.text('No range filter'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsWidgets);
      expect(find.text('From'), findsNothing);
    });

    testWidgets(
      'between DateTime fields normalize date-only input on field exit',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcDateTimeField(name: 'createdAt')],
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'createdAt': DateTime(2029, 12, 31)},
              {'createdAt': DateTime(2029, 12, 31, 14, 30)},
              {'createdAt': DateTime(2030)},
            ],
          ),
        );
        dataSet.open();

        const formats = FdcFormatSettings(
          dateFormat: 'MM/dd/yyyy',
          dateTimeFormat: 'MM/dd/yyyy HH:mm',
        );

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDateTimeColumn<dynamic>(
              fieldName: 'createdAt',
              label: 'Created',
              formatSettings: formats,
            ),
          ],
          header: _zeroDebounceHeader,
          formatSettings: formats,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Between'));
        await tester.pumpAndSettle();

        final fields = _headerRangeFilterTextFields();
        expect(fields, findsNWidgets(2));
        await tester.enterText(fields.at(0), '12/31/2029');
        await tester.tap(fields.at(1));
        await tester.pumpAndSettle();

        final fromTextField = tester.widget<TextField>(
          _headerRangeFilterTextFields().at(0),
        );
        expect(fromTextField.controller?.text, '12/31/2029 00:00');
        expect(dataSet.recordCount, 3);

        await tester.enterText(
          _headerRangeFilterTextFields().at(1),
          '12/31/2029',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 1);
        expect(
          find.text('12/31/2029 00:00 – 12/31/2029 00:00'),
          findsOneWidget,
        );
      },
    );

    testWidgets('between range form captures keyboard inside popup', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10.00},
            {'amount': 20.00},
            {'amount': 30.00},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Between'));
      await tester.pumpAndSettle();

      final fields = _headerRangeFilterTextFields();
      expect(fields, findsNWidgets(2));

      await tester.tap(fields.at(0));
      await tester.enterText(fields.at(0), '15.00');
      await tester.pumpAndSettle();

      TextField fromField = tester.widget<TextField>(fields.at(0));
      TextField toField = tester.widget<TextField>(fields.at(1));
      expect(fromField.focusNode?.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      fromField = tester.widget<TextField>(fields.at(0));
      expect(fromField.focusNode?.hasFocus, isTrue);
      expect(fromField.controller?.selection.baseOffset, 4);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      fromField = tester.widget<TextField>(fields.at(0));
      expect(fromField.focusNode?.hasFocus, isTrue);
      expect(fromField.controller?.selection.baseOffset, 0);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      toField = tester.widget<TextField>(fields.at(1));
      expect(toField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      fromField = tester.widget<TextField>(fields.at(0));
      expect(fromField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      fromField = tester.widget<TextField>(fields.at(0));
      expect(fromField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      toField = tester.widget<TextField>(fields.at(1));
      expect(toField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);
      expect(dataSet.recordCount, 3);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      toField = tester.widget<TextField>(fields.at(1));
      expect(toField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);
      expect(dataSet.recordCount, 3);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Apply'), findsOneWidget);
      expect(dataSet.recordCount, 3);
      expect(find.text('Required'), findsOneWidget);

      await tester.enterText(fields.at(1), '25.00');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Apply'), findsNothing);
      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsOneWidget);
      expect(find.text('10.00'), findsNothing);
      expect(find.text('30.00'), findsNothing);
    });

    testWidgets(
      'beforeInsert abort from grid auto append shows dataset error dialog',
      (tester) async {
        var beforeInsertCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          beforeInsert: (dataSet) {
            beforeInsertCalls++;
            throw FdcDataSetAbortException('Insert is not allowed.');
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(beforeInsertCalls, 1);
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 1);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages[0], 'Insert is not allowed.');
        expect(find.text('Insert is not allowed.'), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets('beforeEdit abort from grid shows dataset error dialog', (
      tester,
    ) async {
      var beforeEditCalls = 0;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
        beforeEdit: (dataSet) {
          beforeEditCalls++;
          throw FdcDataSetAbortException('Edit is not allowed.');
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.pumpAndSettle();

      expect(beforeEditCalls, 1);
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(dataSet.errors.messages[0], 'Edit is not allowed.');
      expect(find.text('Edit is not allowed.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets(
      'silent beforeEdit abort from grid does not show error dialog',
      (tester) async {
        var beforeEditCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          beforeEdit: (dataSet) {
            beforeEditCalls++;
            throw const FdcDataSetAbortException.silent();
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.pumpAndSettle();

        expect(beforeEditCalls, 1);
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets(
      'silent beforeInsert abort from grid auto append does not show error dialog',
      (tester) async {
        var beforeInsertCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          beforeInsert: (dataSet) {
            beforeInsertCalls++;
            throw const FdcDataSetAbortException.silent();
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(beforeInsertCalls, 1);
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 1);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets(
      'grid keeps externally posted row visible until filter is explicitly reapplied',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'status'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'status': 'active'},
              {'name': 'Beta', 'status': 'blocked'},
            ],
          ),
        );
        dataSet.open();

        dataSet.filter.where('status').equals('active').apply();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'status'),
          ],
        );

        expect(dataSet.recordCount, 1);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);

        dataSet.edit();
        dataSet.setFieldValue('status', 'inactive');
        dataSet.post();
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Alpha');
        expect(dataSet.fieldValue('status'), 'inactive');
        expect(find.text('Alpha'), findsOneWidget);
      },
    );

    testWidgets(
      'leaving unchanged header filter does not reapply active filter',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'status'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'status': 'active'},
              {'name': 'Beta', 'status': 'blocked'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'status'),
          ],
          header: _zeroDebounceHeader,
        );

        await tester.enterText(find.byType(EditableText).at(1), 'active');
        await tester.pumpAndSettle();

        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);

        dataSet.append();
        dataSet.setFieldValue('name', 'Gamma');
        dataSet.setFieldValue('status', 'inactive');
        dataSet.post();
        await tester.pumpAndSettle();

        expect(find.text('Gamma'), findsOneWidget);

        await tester.tap(find.byType(EditableText).at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alpha').first);
        await tester.pumpAndSettle();

        expect(find.text('Gamma'), findsOneWidget);
      },
    );
  });
}
