import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';

import 'customer_data.dart';

void main() {
  runApp(const CustomersExampleApp());
}

enum _ExampleTheme {
  light('Light'),
  white('White'),
  dark('Dark'),
  black('Black');

  const _ExampleTheme(this.label);

  final String label;

  bool get isDark => this == dark || this == black;

  FdcThemeData get fdcTheme => switch (this) {
    light => const FdcThemeData(
      grid: FdcGridThemes.light,
      editor: FdcEditorThemes.light,
    ),
    white => const FdcThemeData(
      grid: FdcGridThemes.white,
      editor: FdcEditorThemes.white,
    ),
    dark => const FdcThemeData(
      grid: FdcGridThemes.dark,
      editor: FdcEditorThemes.dark,
    ),
    black => const FdcThemeData(
      grid: FdcGridThemes.black,
      editor: FdcEditorThemes.black,
    ),
  };
}

enum _ExampleLanguage {
  english('English'),
  croatian('Croatian'),
  italian('Italian'),
  german('German'),
  french('French'),
  spanish('Spanish');

  const _ExampleLanguage(this.label);

  final String label;

  FdcTranslations get translations => switch (this) {
    english => FdcTranslations.enUs(),
    croatian => FdcTranslations.hrHr(),
    italian => FdcTranslations.itIt(),
    german => FdcTranslations.deDe(),
    french => FdcTranslations.frFr(),
    spanish => FdcTranslations.esEs(),
  };
}

class CustomersExampleApp extends StatefulWidget {
  const CustomersExampleApp({super.key});

  @override
  State<CustomersExampleApp> createState() => _CustomersExampleAppState();
}

class _CustomersExampleAppState extends State<CustomersExampleApp> {
  _ExampleTheme _theme = _ExampleTheme.light;
  _ExampleLanguage _language = _ExampleLanguage.english;

  @override
  Widget build(BuildContext context) {
    final brightness = _theme.isDark ? Brightness.dark : Brightness.light;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FD Components',
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: brightness,
        ),
        useMaterial3: true,
      ),
      home: FdcApp(
        theme: _theme.fdcTheme,
        translations: _language.translations,
        child: _CustomersPage(
          theme: _theme,
          language: _language,
          onThemeChanged: (value) => setState(() => _theme = value),
          onLanguageChanged: (value) => setState(() => _language = value),
        ),
      ),
    );
  }
}

class _CustomersPage extends StatefulWidget {
  const _CustomersPage({
    required this.theme,
    required this.language,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  final _ExampleTheme theme;
  final _ExampleLanguage language;
  final ValueChanged<_ExampleTheme> onThemeChanged;
  final ValueChanged<_ExampleLanguage> onLanguageChanged;

  @override
  State<_CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<_CustomersPage> {
  late final FdcDataSet _customers;
  late final Future<void> _openFuture;

  @override
  void initState() {
    super.initState();
    _customers = createCustomerDataSet();
    _openFuture = _customers.open();
  }

  @override
  void dispose() {
    _customers.dispose();
    super.dispose();
  }

  bool get _editing =>
      _customers.state == FdcDataSetState.edit ||
      _customers.state == FdcDataSetState.insert;

  void _addCustomer() {
    if (_customers.state == FdcDataSetState.browse) {
      _customers.append();
    }
  }

  Future<void> _deleteCustomer() async {
    if (_customers.state != FdcDataSetState.browse || _customers.isEmpty) {
      return;
    }

    final company =
        _customers.fieldValue('company_name') as String? ?? 'customer';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('Delete $company from the dataset?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _customers.delete();
    }
  }

  void _saveEdit() {
    if (!_editing) {
      return;
    }

    try {
      _customers.post();
    } on FdcDataSetValidationException catch (error) {
      final message = error.errors.isEmpty
          ? 'Please complete the required fields.'
          : error.errors.map((item) => item.message).join('\n');

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _cancelEdit() {
    if (_editing) {
      _customers.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FD Components inline CRUD example'),
        actions: <Widget>[
          _AppBarSelector<_ExampleTheme>(
            tooltip: 'FDC theme',
            icon: Icons.palette_outlined,
            value: widget.theme,
            values: _ExampleTheme.values,
            labelOf: (value) => value.label,
            onSelected: widget.onThemeChanged,
          ),
          _AppBarSelector<_ExampleLanguage>(
            tooltip: 'FDC translations',
            icon: Icons.translate,
            value: widget.language,
            values: _ExampleLanguage.values,
            labelOf: (value) => value.label,
            onSelected: widget.onLanguageChanged,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<void>(
        future: _openFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not open the dataset: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return AnimatedBuilder(
            animation: _customers,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: FdcGrid(
                  dataSet: _customers,
                  toolbar: FdcGridToolbar(
                    items: <FdcGridItem>[
                      const FdcGridSearchBar(
                        mode: FdcGridSearchBarMode.advanced,
                        matchMode: FdcSearchMode.anyWord,
                      ),
                      FdcGridButton(
                        id: 'add',
                        icon: Icons.add,
                        label: 'Add',
                        tooltip: 'Append a new customer',
                        onPressed: _customers.state == FdcDataSetState.browse
                            ? _addCustomer
                            : null,
                      ),
                      FdcGridButton(
                        id: 'delete',
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        tooltip: 'Delete the current customer',
                        onPressed:
                            _customers.state == FdcDataSetState.browse &&
                                !_customers.isEmpty
                            ? () => unawaited(_deleteCustomer())
                            : null,
                      ),
                      FdcGridButton(
                        id: 'save',
                        icon: Icons.check,
                        label: 'Save',
                        tooltip: 'Post the current edit',
                        onPressed: _editing ? _saveEdit : null,
                      ),
                      FdcGridButton(
                        id: 'cancel',
                        icon: Icons.close,
                        label: 'Cancel',
                        tooltip: 'Cancel the current edit',
                        onPressed: _editing ? _cancelEdit : null,
                      ),
                    ],
                  ),
                  statusBar: const FdcGridStatusBar(visible: true),
                  columns: const <FdcGridColumn<dynamic>>[
                    FdcIntegerColumn<dynamic>(
                      fieldName: 'customer_id',
                      width: 92,
                      readOnly: true,
                    ),
                    FdcTextColumn<dynamic>(
                      fieldName: 'company_name',
                      width: 190,
                    ),
                    FdcTextColumn<dynamic>(
                      fieldName: 'contact_name',
                      width: 160,
                    ),
                    FdcTextColumn<dynamic>(fieldName: 'email', width: 250),
                    FdcTextColumn<dynamic>(fieldName: 'phone', width: 140),
                    FdcTextColumn<dynamic>(fieldName: 'city', width: 120),
                    FdcComboColumn<String>(
                      fieldName: 'country',
                      width: 150,
                      options: customerCountryOptions,
                      search: FdcComboSearchOptions(
                        searchable: true,
                        searchableInline: true,
                        mode: FdcComboSearchMode.contains,
                      ),
                      searchHintText: 'Search countries',
                    ),
                    FdcTextColumn<dynamic>(fieldName: 'industry', width: 145),
                    FdcComboColumn<String>(
                      fieldName: 'status',
                      width: 110,
                      options: customerStatusOptions,
                    ),
                    FdcDecimalColumn<dynamic>(
                      fieldName: 'credit_limit',
                      width: 145,
                      prefixText: r'$ ',
                      summary: FdcColumnSummary(
                        aggregate: FdcAggregate.sum,
                        label: 'Total',
                      ),
                    ),
                    FdcBooleanColumn<dynamic>(fieldName: 'active', width: 105),
                    FdcDateColumn<dynamic>(
                      fieldName: 'registered_at',
                      width: 130,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AppBarSelector<T> extends StatelessWidget {
  const _AppBarSelector({
    required this.tooltip,
    required this.icon,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onSelected,
  });

  final String tooltip;
  final IconData icon;
  final T value;
  final List<T> values;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: '$tooltip: ${labelOf(value)}',
      icon: Icon(icon),
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => <PopupMenuEntry<T>>[
        for (final item in values)
          CheckedPopupMenuItem<T>(
            value: item,
            checked: item == value,
            child: Text(labelOf(item)),
          ),
      ],
    );
  }
}
