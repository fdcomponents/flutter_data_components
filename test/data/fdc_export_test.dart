import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('built-in export formats provide distinct menu icons', () {
    expect(FdcExportFormat.csv.icon, Icons.table_rows_outlined);
    expect(FdcExportFormat.json.icon, Icons.data_object);
    expect(FdcExportFormat.xml.icon, Icons.code_outlined);
    expect(<IconData?>{
      FdcExportFormat.csv.icon,
      FdcExportFormat.json.icon,
      FdcExportFormat.xml.icon,
    }, hasLength(3));
  });

  group('FdcExportOptions validation', () {
    test('rejects invalid CSV delimiters and line terminators', () {
      expect(() => FdcExportOptions(csvDelimiter: ''), throwsArgumentError);
      expect(() => FdcExportOptions(csvDelimiter: '\n'), throwsArgumentError);
      expect(() => FdcExportOptions(csvDelimiter: '"'), throwsArgumentError);
      expect(() => FdcExportOptions(lineTerminator: ''), throwsArgumentError);
      expect(
        () => FdcExportOptions(lineTerminator: 'custom'),
        throwsArgumentError,
      );
    });

    test('rejects invalid XML element names', () {
      expect(
        () => FdcExportOptions(rootElementName: '1rows'),
        throwsArgumentError,
      );
      expect(
        () => FdcExportOptions(rowElementName: 'xmlRow'),
        throwsArgumentError,
      );
    });
  });

  group('FdcExportRegistry', () {
    test('contains all Community built-in writers', () async {
      expect(FdcExportRegistry.formats, FdcExportFormat.builtInFormats);
      expect(
        FdcExportRegistry.writerFor(FdcExportFormat.csv),
        isA<FdcExportWriter>(),
      );
      expect(
        FdcExportRegistry.writerFor(FdcExportFormat.json),
        isA<FdcExportWriter>(),
      );
      expect(
        FdcExportRegistry.writerFor(FdcExportFormat.xml),
        isA<FdcExportWriter>(),
      );
    });
  });

  group('FdcExporter', () {
    test('exports current view to CSV with headers', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'qty': 1},
            {'name': 'Bravo, Inc', 'qty': 2},
          ],
        ),
      );
      dataSet.open();
      dataSet.filter.where('qty').equals(2).apply();

      final result = await FdcExporter.exportDataSet(
        dataSet,
        format: FdcExportFormat.csv,
      );

      expect(result.format, FdcExportFormat.csv);
      expect(result.fileExtension, 'csv');
      expect(result.text, 'Name,Quantity\n"Bravo, Inc",2\n');
      expect(result.bytes, isNotEmpty);
    });

    test('exports selected rows to JSON', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'qty': 1},
            {'name': 'Bravo', 'qty': 2},
          ],
        ),
      );
      dataSet.open();
      dataSet.selection.setSelectedAt(1, true);

      final result = await FdcExporter.exportDataSet(
        dataSet,
        format: FdcExportFormat.json,
        options: FdcExportOptions(scope: FdcExportScope.selectedRows),
      );

      expect(result.mimeType, 'application/json');
      expect(result.text, contains('"Name": "Bravo"'));
      expect(result.text, contains('"Quantity": 2'));
      expect(result.text, isNot(contains('Alpha')));
    });

    test('exports all rows independently of the current view', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'qty': 1},
            {'name': 'Bravo', 'qty': 2},
          ],
        ),
      );
      dataSet.open();
      dataSet.filter.where('name').equals('Alpha').apply();

      final result = await FdcExporter.exportDataSet(
        dataSet,
        format: FdcExportFormat.xml,
        options: FdcExportOptions(scope: FdcExportScope.allRows),
      );

      expect(result.text, contains('<name>Alpha</name>'));
      expect(result.text, contains('<name>Bravo</name>'));
    });

    test('uses output keys separately from CSV headers', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'qty': 1},
          ],
        ),
      );
      dataSet.open();
      final options = FdcExportOptions(
        columns: <FdcExportColumn>[
          const FdcExportColumn(
            fieldName: 'name',
            key: 'export_name',
            label: 'Display Name',
          ),
        ],
      );

      final json = await FdcExporter.exportDataSet(
        dataSet,
        format: FdcExportFormat.json,
        options: options,
      );
      final csv = await FdcExporter.exportDataSet(
        dataSet,
        format: FdcExportFormat.csv,
        options: options,
      );
      final xml = await FdcExporter.exportDataSet(
        dataSet,
        format: FdcExportFormat.xml,
        options: options,
      );

      expect(json.text, contains('"export_name": "Alpha"'));
      expect(csv.text, 'Display Name\nAlpha\n');
      expect(xml.text, contains('<export_name>Alpha</export_name>'));
    });

    test('sanitizes spreadsheet formulas in CSV text values', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': '=HYPERLINK("https://example.invalid")', 'qty': -12},
            {'name': '\t@SUM(A1:A2)', 'qty': 3},
          ],
        ),
      );
      dataSet.open();

      final result = await FdcExporter.exportDataSet(
        dataSet,
        format: FdcExportFormat.csv,
      );

      expect(result.text, contains("'=HYPERLINK"));
      expect(result.text, contains("'\t@SUM(A1:A2)"));
      expect(result.text, contains(',-12'));
    });

    test('allows spreadsheet formula sanitization to be disabled', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': '=1+1', 'qty': 1},
          ],
        ),
      );
      dataSet.open();

      final result = await FdcExporter.exportDataSet(
        dataSet,
        format: FdcExportFormat.csv,
        options: FdcExportOptions(sanitizeSpreadsheetFormulas: false),
      );

      expect(result.text, contains('=1+1'));
      expect(result.text, isNot(contains("'=1+1")));
    });

    test('supports extension formats through custom writers', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'qty': 1},
          ],
        ),
      );
      dataSet.open();
      const format = FdcExportFormat(
        'pipe',
        label: 'Pipe',
        fileExtension: 'txt',
        mimeType: 'text/plain',
      );

      final result = await FdcExporter.exportDataSet(
        dataSet,
        format: format,
        writer: const _PipeExportWriter(),
      );

      expect(result.format, format);
      expect(result.fileExtension, 'txt');
      expect(result.text, 'Name|Quantity\nAlpha|1');
    });

    test('throws for unknown formats without a writer', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'qty': 1},
          ],
        ),
      );
      dataSet.open();
      const format = FdcExportFormat(
        'unknown',
        label: 'Unknown',
        fileExtension: 'unknown',
        mimeType: 'application/octet-stream',
      );

      await expectLater(
        FdcExporter.exportDataSet(dataSet, format: format),
        throwsUnsupportedError,
      );
    });
  });
}

class _PipeExportWriter implements FdcExportWriter {
  const _PipeExportWriter();

  @override
  FdcExportPayload write(FdcExportWriterContext context) {
    final lines = <String>[
      context.columns.map(context.headerFor).join('|'),
      for (final row in context.rows)
        context.columns
            .map((column) => context.valueFor(row, column).toString())
            .join('|'),
    ];
    return FdcTextExportPayload(lines.join('\n'));
  }
}

FdcDataSet _createDataSet({IFdcDataAdapter? adapter}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(name: 'name', label: 'Name', size: 50),
      FdcIntegerField(name: 'qty', label: 'Quantity'),
    ],

    adapter:
        adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
}
