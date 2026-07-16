## 1.0.6

- Changed column reordering to swap columns live while dragging over valid targets, with animated transitions and guarded repeat swaps for stable visual feedback.
- Fixed Copy and Paste actions in the selected-cell context menu when the inplace editor is not active.
- Added regression coverage for menu-driven single-cell clipboard operations.

## 1.0.5

- Added shared menu-overlay dismissal support for embedded Flutter Web applications.

## 1.0.4

- Restored Flutter Web compatibility by routing background dataset sorting, memory-adapter loading, and aggregate work through platform-specific runners: native platforms continue to use isolates while Web uses an inline fallback.

## 1.0.3

- Expanded the `fdc_app.dart` entrypoint to export `FdcThemeData`, `FdcExportStyle`, and `FdcExportFormatStyle` for application-level theme and export configuration.

## 1.0.2

- Fixed context menus so secondary mouse clicks reliably open menus in nested interactive widgets, including Flutter Web grids.

## 1.0.1

- Made sorting, column reordering, header filters, column pinning, and the row indicator opt-in by default.
- Changed the default grid row height to 40.
- Improved grid menu visibility and vertical scrollbar tracking.

## 1.0.0

- First public release.
