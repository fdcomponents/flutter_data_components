# FD Components Example

A minimal cross-platform inline CRUD example built with one in-memory `FdcDataSet` and one `FdcGrid`.

The example is intentionally small enough to read and copy, while still showing a complete data-entry workflow: browse records, search, sort, filter, edit values directly in the grid, insert new records, validate required fields, save or cancel changes, delete records, and display aggregate and status information.

## What the example demonstrates

- a typed dataset schema with 36 in-memory business records;
- a 12-column editable customer grid;
- advanced built-in search with match-mode and case-sensitivity controls;
- column sorting and header filtering;
- inline text, decimal, boolean, and date editing;
- insert, edit, post, cancel, and delete lifecycle operations;
- required-field validation with user-visible feedback;
- a `sum` summary for the Credit Limit column;
- the built-in grid status bar;
- live switching between the built-in Light, White, Dark, and Black FDC themes;
- live switching between the built-in English, Croatian, Italian, German, French, and Spanish FDC translations;
- the same Dart code running across Android, iOS, web, Windows, macOS, and Linux.

The dataset is memory-backed, so no database, server, API key, asset import, or platform-specific setup is required.

## Run the example

From the `example` directory:

```bash
flutter pub get
flutter run
```

Choose any Flutter target available on your machine. For example:

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d macos
```

## Themes and translations

The app bar includes two compact selectors for exploring FDC's built-in presentation options:

- the **palette** button switches between the Light, White, Dark, and Black grid/editor theme presets;
- the **translate** button switches FDC component text between English, Croatian, Italian, German, French, and Spanish.

The selectors update the running example immediately. Theme changes apply the matching built-in `FdcGridThemes` and `FdcEditorThemes` presets through `FdcApp`, while language changes replace the active `FdcTranslations` bundle. Open a column menu, filter menu, search controls, or another built-in FDC surface to see translated component text.

The business data itself intentionally remains in English so theme and translation changes can be compared without changing the dataset.

## Inline CRUD workflow

The toolbar exposes the basic record lifecycle directly:

- **Add** appends a new customer and enters insert mode.
- Edit any editable cell directly in the grid.
- **Save** posts the current insert or edit after validation succeeds.
- **Cancel** discards the active insert or edit.
- **Delete** asks for confirmation and removes the current customer.

`Company` and `Contact` are required fields. Attempting to save an incomplete new record keeps the record in edit state and shows the validation message in a `SnackBar`.

The `ID` column is read-only. The remaining columns demonstrate common business data types, including text, decimal, boolean, and date values.

## Keyboard navigation

The grid supports keyboard-first data entry when it has focus. On devices without a hardware keyboard, the same actions remain available through pointer/touch interaction and the toolbar.

| Key | Action |
| --- | --- |
| Arrow keys | Move between rows and columns. |
| `Tab` | Move to the next editable cell. |
| `Shift+Tab` | Move to the previous editable cell. |
| `Enter` | Commit the active cell edit and move to the next editable cell. |
| `F2` | Start editing the selected cell, or move the caret to the end while already editing. |
| Type text | Start editing an editable text-like cell from the keyboard. |
| `Space` | Toggle an editable boolean cell; also activates supported drop-down editors. |
| `Home` / `End` | Move to the first or last column in the current row. |
| `Page Up` / `Page Down` | Move by one visible page of rows. |
| `Ctrl+Page Up` / `Ctrl+Page Down` | Move to the first or last row. |
| `Insert` | Insert a new record and focus an editable field. |
| `Ctrl+Delete` | Delete the current record using the grid delete-confirmation flow. |
| `Delete` / `Backspace` | Clear the selected editable cell value when not using `Ctrl`. |
| `Escape` | Cancel the active cell edit; when no cell editor is active, cancel the current dataset edit or insert. |
| `Ctrl+F` / `Cmd+F` | Focus the grid search bar when available. |

A useful keyboard-only CRUD path is:

1. Press `Insert` to append a new record.
2. Enter values and use `Tab` or `Enter` to advance through editable cells.
3. Continue navigating to commit valid edits as you leave the row, or use **Save** in the toolbar to post explicitly.
4. Press `Escape` to cancel the active edit/insert flow when needed.
5. Select an existing row and press `Ctrl+Delete` to start the delete-confirmation flow.

## Search, sorting, and filtering

Use the search field in the toolbar to search the dataset. The example enables the advanced search UI, so the toolbar also exposes match-mode and case-sensitivity controls. This makes it easy to compare different global-search strategies directly in the running example.

Column headers and column menus expose sorting and filtering capabilities provided by `FdcGrid`.

While a record is actively being edited or inserted, query-changing filter actions can be unavailable until the edit lifecycle is resolved. Save or cancel the current edit before changing the dataset view.

## Project structure

The example keeps application code intentionally small:

```text
lib/
  main.dart
  customer_data.dart
```

- `main.dart` contains the application shell, grid configuration, toolbar actions, validation feedback, and CRUD interaction flow.
- `customer_data.dart` defines the dataset schema, default values for inserted records, and the in-memory sample rows.

This structure is deliberate: the example demonstrates FD Components directly without adding repositories, services, state-management frameworks, or other application architecture that would obscure the core dataset-and-grid workflow.
