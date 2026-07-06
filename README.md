# Flutter Data Components

[![pub package](https://img.shields.io/pub/v/flutter_data_components.svg)](https://pub.dev/packages/flutter_data_components)
[![pub points](https://img.shields.io/pub/points/flutter_data_components)](https://pub.dev/packages/flutter_data_components/score)
[![likes](https://img.shields.io/pub/likes/flutter_data_components)](https://pub.dev/packages/flutter_data_components/score)
[![license](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

**High-performance RAD data components for Flutter business applications.**

Build data-heavy Flutter applications faster with a cohesive toolkit for datasets, typed fields, validation, CRUD workflows, data-aware editors, and an editable enterprise grid.

FDC is designed for the screens that dominate real business software: POS systems, orders, invoices, inventory, administration, back-office operations, ERP modules, and other structured data workflows.

```dart
import 'package:flutter_data_components/fdc.dart';
```

## Build CRUD screens around data, not widget plumbing

Most business screens repeat the same concerns: schema, validation, edit state, formatting, navigation, filtering, sorting, search, error handling, and persistence.

FDC brings those concerns together in one metadata-driven model.

Define your fields once. Bind a grid or editors to the dataset. Let the same field metadata drive validation, formatting, filtering, editing, and display behavior across the UI.

**What you get:**

- a dataset lifecycle built for CRUD: browse, append, edit, post, cancel, delete;
- typed field metadata with validation, defaults, keys, precision, scale, and storage rules;
- an editable, virtualized data grid with sorting, filtering, search, summaries, selection, toolbars, and status UI;
- data-aware editors that bind directly to dataset fields;
- local and adapter-backed data flows through the same dataset API;
- cached updates and change tracking for controlled persistence workflows;
- shared formatting, localization, theming, and focus behavior;
- JSON, CSV, and XML export support.

## See the model in one minute

Create a dataset with typed schema metadata:

```dart
final customers = FdcDataSet(
  fields: const <FdcFieldDef>[
    FdcIntegerField(
      name: 'id',
      label: 'ID',
      isKey: true,
      storage: FdcFieldStorage(updateable: false),
    ),
    FdcStringField(
      name: 'company',
      label: 'Company',
      size: 120,
      required: true,
    ),
    FdcDecimalField(
      name: 'credit_limit',
      label: 'Credit limit',
      precision: 12,
      scale: 2,
      minValue: 0,
    ),
    FdcBooleanField(
      name: 'active',
      label: 'Active',
      defaultValue: true,
    ),
  ],
  adapter: FdcMemoryDataAdapter(
    rows: <Map<String, Object?>>[
      {
        'id': 1,
        'company': 'Northstar Analytics',
        'credit_limit': 25000,
        'active': true,
      },
    ],
  ),
);

await customers.open();
```

Bind the same dataset directly to a grid:

```dart
FdcGrid(
  dataSet: customers,
  toolbar: const FdcGridToolbar(
    items: <FdcGridItem>[
      FdcGridSearchBar(
        mode: FdcGridSearchBarMode.advanced,
      ),
    ],
  ),
  statusBar: const FdcGridStatusBar(visible: true),
  columns: const <FdcGridColumn<dynamic>>[
    FdcIntegerColumn<dynamic>(
      fieldName: 'id',
      width: 80,
      readOnly: true,
    ),
    FdcTextColumn<dynamic>(
      fieldName: 'company',
      width: 220,
    ),
    FdcDecimalColumn<dynamic>(
      fieldName: 'credit_limit',
      width: 150,
      prefixText: r'$ ',
      summary: FdcColumnSummary(
        aggregate: FdcAggregate.sum,
        label: 'Total',
      ),
    ),
    FdcBooleanColumn<dynamic>(
      fieldName: 'active',
      width: 100,
    ),
  ],
)
```

The grid, editors, filters, validation rules, formatting, and adapter operations all work from the same dataset schema.

## A complete RAD data layer for Flutter

### Dataset lifecycle

`FdcDataSet` is the center of the FDC programming model. It owns field schema, records, current-record navigation, edit buffers, validation, filters, sorts, search state, change tracking, and adapter interaction.

```dart
customers.append();
customers.setFieldValue('company', 'New customer');
customers.post();

customers.edit();
customers.setFieldValue('credit_limit', 50000);
customers.cancel();

customers.delete();
```

This gives business screens an explicit, predictable editing lifecycle instead of scattering temporary form state and persistence rules across widgets.

### Typed schema, shared everywhere

FDC fields are more than column definitions. They describe the data contract used throughout the component stack.

Available dataset field types include strings, integers, decimals, booleans, dates, times, date-times, GUIDs, and object values. Combo behavior is exposed through combo editors and combo grid columns over those typed values. Metadata can describe requirements such as:

- required values and custom validation;
- key participation;
- string size;
- decimal precision, scale, and numeric limits;
- default and calculated values;
- storage and updateability rules;
- display labels and formatting behavior.

The result is one schema source for datasets, grids, editors, exporters, and adapters.

## Enterprise grid without rebuilding the data layer

`FdcGrid` is a dataset-aware editable grid for dense business workflows.

It includes:

- typed text, integer, decimal, boolean, date, date-time, combo, badge, action, and custom columns;
- inline editing with dataset validation and post/cancel lifecycle;
- sorting and typed column filtering;
- advanced dataset search;
- summary rows and aggregates;
- row selection and keyboard navigation;
- column resize, reorder, visibility, and pinning;
- toolbar and status-bar composition;
- paging controls for paged datasets;
- error indicators and work/progress UI;
- wide-grid virtualization and smooth scrolling;
- theme presets and localization support.

The grid does not create a parallel data model. It operates directly on `FdcDataSet`, so navigation, validation, edits, filters, and state remain coordinated.

## Data-aware editors

Build forms with editors bound directly to dataset fields:

```dart
Column(
  children: <Widget>[
    FdcTextEdit(
      dataSet: customers,
      fieldName: 'company',
    ),
    FdcDecimalEdit(
      dataSet: customers,
      fieldName: 'credit_limit',
    ),
    FdcBooleanEdit(
      dataSet: customers,
      fieldName: 'active',
    ),
  ],
)
```

Editors share the dataset lifecycle and field metadata with the grid. A validation rule defined on the field stays the same whether the value is edited in a form or directly in a grid cell.

## Local data or adapters — same UI model

For local application data, load rows directly into an adapter-less dataset:

```dart
final dataSet = FdcDataSet(fields: fields);
await dataSet.loadRows(rows);
```

For externally owned data, use an adapter and open the dataset:

```dart
final dataSet = FdcDataSet(
  fields: fields,
  adapter: FdcMemoryDataAdapter(rows: rows),
);

await dataSet.open();
```

The Community package includes the memory adapter and the public adapter contracts required to integrate other data sources. The dataset remains the stable UI-facing model while adapters handle loading and applying data.

Adapter-backed datasets can also use standard or accumulated paging through `FdcDataPagingOptions`.

## Cached updates and change tracking

FDC can track inserted, updated, and deleted records as a change set. This supports workflows where users edit multiple records before changes are applied to external storage.

The dataset keeps editing semantics separate from persistence transport, making it suitable for transactional business workflows and APIs that accept batched changes.

## Search, filters, sorts, and aggregates

FDC provides first-class dataset operations instead of forcing every screen to invent its own query state.

```dart
await customers.filter.set(
  const <FdcDataSetFilter>[
    FdcDataSetFilter(
      fieldName: 'active',
      operator: FdcFilterOperator.isTrue,
    ),
  ],
);

await customers.sort.set(
  const <FdcDataSetSort>[
    FdcDataSetSort(
      fieldName: 'company',
      sortType: FdcSortType.ascending,
    ),
  ],
);

await customers.search.apply('northstar');
```

The same dataset state drives grid UI and adapter requests, keeping data behavior consistent across local and external data flows.

## Formatting, localization, and themes

Wrap an FDC subtree with `FdcApp` to configure shared presentation behavior:

```dart
FdcApp(
  formatSettings: const FdcFormatSettings(locale: 'en_US'),
  translations: FdcTranslations.enUs(),
  theme: const FdcThemeData(
    grid: FdcGridThemes.light,
    editor: FdcEditorThemes.light,
  ),
  child: MyBusinessScreen(),
)
```

Built-in UI translations include English, Croatian, Italian, German, French, and Spanish. Format presets and translation fallback are separate, so applications can use broader locale formatting even when UI text falls back to English.

## Export structured data

`FdcExporter` can export datasets to JSON, CSV, and XML. Grid export integration can use the visible grid column configuration, so exported data follows the user-facing table layout by default.

## Why FDC?

Flutter is excellent for building interfaces. Business applications, however, also need a disciplined data-editing model.

FDC fills that gap with a component architecture centered on four principles:

**RAD productivity.** Common CRUD mechanics should be reusable infrastructure, not screen-by-screen boilerplate.

**One data contract.** Schema, validation, editing, display, filtering, and persistence metadata should not drift apart.

**Explicit state.** Browse, edit, insert, post, cancel, delete, loading, and error states should be observable and predictable.

**Architecture freedom.** FDC is not a backend, router, dependency-injection framework, or application state-management solution. Use it with the architecture that fits your application.

## Installation

Add the package to your Flutter application:

```bash
flutter pub add flutter_data_components
```

Then import the Community API:

```dart
import 'package:flutter_data_components/fdc.dart';
```

## Example application

The package includes a complete customer-management example demonstrating:

- typed dataset schema;
- adapter-backed data;
- inline CRUD operations;
- validation;
- search and filters;
- summaries;
- combo columns;
- theme switching;
- runtime language switching.

Run it from the package example directory with:

```bash
flutter run
```

## Community and Pro

`flutter_data_components` is the Community foundation of the FD Components ecosystem.

The Pro edition extends the same dataset and grid architecture with advanced adapters and enterprise productivity features. It is not yet publicly available and is being prepared for a separate release.

Community applications use the same core programming model, so the architecture remains consistent across the ecosystem and provides a clear upgrade path when the Pro edition becomes publicly available.

## Documentation

The complete user documentation is currently under development. This README and the included example application provide the current introduction and working reference while the full documentation site is being prepared.

## Links

- Website: https://fdcomponents.com
- Source code: https://github.com/fdcomponents/flutter_data_components
- Issues: https://github.com/fdcomponents/flutter_data_components/issues

## License

Flutter Data Components Community is licensed under the BSD 3-Clause License. See [LICENSE](LICENSE).
