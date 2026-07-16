// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../common/menu/fdc_menu_entry.dart';
import '../../data/fdc_data.dart';
import '../columns/fdc_column_base.dart';
import 'fdc_grid_cell_ref.dart';

// Range-selection contracts used by the grid runtime.

/// Normalized rectangular selection bounds in grid row and source-column space.
///
/// Range-selection session implementations produce this record and the Community
/// grid host consumes it for clipboard operations, hit testing, and overlay
/// projection. `firstRow` and `lastRow` are zero-based data-row indexes and are
/// inclusive. `firstColumn` and `lastColumn` are inclusive source column indexes.
/// `columnIndexes` contains the selected source column indexes in current visual
/// order, which may differ from a contiguous numeric range after reordering or
/// pinning.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam and may be
/// used by compatible third-party extension packages.
typedef FdcGridRangeSelectionBounds = ({
  int firstRow,
  int lastRow,
  int firstColumn,
  int lastColumn,
  List<int> columnIndexes,
});

/// Reads display text for one grid cell during range-copy serialization.
///
/// The grid host supplies this callback and the range-selection session calls it.
/// Both indexes are zero-based and use data-row and source-column coordinates, not
/// viewport-relative positions. Implementations must return text for every valid
/// coordinate requested by the session; failures are propagated to the caller.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcGridRangeSelectionCellTextReader =
    String Function(int rowIndex, int columnIndex);

/// Reports whether one grid cell may receive a range-paste update.
///
/// The grid host supplies this predicate and the range-selection session calls it
/// while validating a paste plan. Indexes are zero-based data-row and source-column
/// coordinates. Returning `false` excludes the cell from writable paste targets;
/// the session decides whether that makes the complete paste plan inapplicable.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcGridRangeSelectionCellEditablePredicate =
    bool Function(int rowIndex, int columnIndex);

/// Parses clipboard text into a value suitable for one destination grid cell.
///
/// The grid host supplies this parser and the range-selection session calls it
/// during paste-plan validation. Indexes are zero-based data-row and source-column
/// coordinates. Return a parsed `value` with `errorText == null` on success. Return
/// a non-null `errorText` when the text cannot be applied to that cell; `value` may
/// be `null` because `null` is also a valid parsed field value. The session must not
/// include failed parses in an applicable update plan. Exceptions are not converted
/// to validation errors and therefore propagate to the caller.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcGridRangeSelectionCellTextParser =
    ({Object? value, String? errorText}) Function(
      int rowIndex,
      int columnIndex,
      String text,
    );

/// One validated cell assignment produced by a range-paste operation.
///
/// `rowIndex` and `columnIndex` are zero-based data-row and source-column indexes.
/// `value` is the parsed value to write and may legitimately be `null`. Extension
/// sessions produce these records; the grid runtime consumes them when applying the
/// paste plan.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcGridRangeSelectionPasteUpdate = ({
  int rowIndex,
  int columnIndex,
  Object? value,
});

/// Result of validating clipboard content against the current selected range.
///
/// Range-selection session implementations return this record to the grid host.
/// On success, `updates` contains the ordered cell assignments to apply and
/// `errorText` is `null`. On validation failure, `errorText` describes the failure
/// and `updates` must not contain assignments that the host should apply. A session
/// may instead return `null` from `readClipboardPastePlan` when clipboard content is
/// absent or cannot produce any applicable operation.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcGridRangeSelectionPastePlan = ({
  List<FdcGridRangeSelectionPasteUpdate> updates,
  String? errorText,
});

/// Builds menu entries for the current range-selection context.
///
/// Extension packages implement this callback and the grid invokes it when opening
/// a range-selection context menu. [context] belongs to the active grid widget tree;
/// [menuContext] exposes current command availability and host-provided copy/paste
/// actions. Return entries in display order. Returning an empty list contributes no
/// range-selection menu items. Exceptions propagate to the menu-building caller.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcGridRangeSelectionContextMenuBuilder =
    List<FdcMenuEntry> Function(
      BuildContext context,
      FdcGridRangeSelectionContextMenuContext menuContext,
    );

/// Context passed when building range-selection context-menu entries.
class FdcGridRangeSelectionContextMenuContext {
  /// Creates a [FdcGridRangeSelectionContextMenuContext].
  const FdcGridRangeSelectionContextMenuContext({
    required this.copyEnabled,
    required this.pasteEnabled,
    required this.onCopy,
    required this.onPaste,
  });

  /// Whether the host currently allows copying the selected range.
  ///
  /// Builders should disable or omit copy commands when this is `false`.
  final bool copyEnabled;

  /// Whether the host currently allows pasting clipboard data into the range.
  ///
  /// Builders should disable or omit paste commands when this is `false`.
  final bool pasteEnabled;

  /// Invokes the host-owned copy command for the current normalized range.
  ///
  /// Builders should wire enabled copy menu items to this callback rather than
  /// duplicating clipboard serialization logic.
  final VoidCallback onCopy;

  /// Invokes the host-owned paste command for the current normalized range.
  ///
  /// Builders should wire enabled paste menu items to this callback rather than
  /// applying clipboard values directly.
  final VoidCallback onPaste;
}

/// Resolves the top edge of a data row in vertical grid content coordinates.
///
/// The grid host provides this resolver and overlay builders call it for zero-based
/// data-row indexes. The returned value is measured before applying the viewport's
/// vertical scroll offset. This contract allows hosts with non-uniform row geometry
/// to project range overlays correctly. Invalid row indexes are outside the contract.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcGridRangeSelectionRowTopResolver = double Function(int rowIndex);

/// Builds the visual overlay for an attached range-selection session.
///
/// Extension packages implement this callback and the grid host calls it during
/// overlay composition. [overlayContext] is an immutable geometry snapshot using
/// grid viewport and source-column coordinates. Implementations should render only
/// the overlay and must not mutate selection state. Return `SizedBox.shrink()` when
/// no visual output is required. Exceptions propagate through the widget build.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcGridRangeSelectionOverlayBuilder =
    Widget Function(
      BuildContext context,
      FdcGridRangeSelectionOverlayContext overlayContext,
    );

/// Column geometry snapshot used by the range-selection overlay.
class FdcGridRangeSelectionOverlayColumnGeometry {
  /// Creates a [FdcGridRangeSelectionOverlayColumnGeometry].
  const FdcGridRangeSelectionOverlayColumnGeometry({
    required this.sourceColumnIndex,
    required this.offset,
    required this.width,
  });

  /// The source column index.
  final int sourceColumnIndex;

  /// Horizontal offset of the column inside its viewport band.
  final double offset;

  /// Rendered width of the source column.
  final double width;
}

/// Horizontal viewport band used by the range-selection overlay.
class FdcGridRangeSelectionOverlayBand {
  /// Creates a [FdcGridRangeSelectionOverlayBand].
  const FdcGridRangeSelectionOverlayBand({
    required this.name,
    required this.geometries,
    required this.origin,
    required this.clipWidth,
    required this.scrollOffset,
  });

  /// Stable band name used to distinguish pinned and scrollable regions.
  final String name;

  /// Column geometries that belong to this viewport band.
  final List<FdcGridRangeSelectionOverlayColumnGeometry> geometries;

  /// Horizontal origin of the band in grid viewport coordinates.
  final double origin;

  /// Width of the visible clipped region for this band, in logical pixels.
  final double clipWidth;

  /// Horizontal scroll displacement applied to this band, in logical pixels.
  ///
  /// Pinned bands normally report zero; scrollable bands report their current
  /// viewport offset.
  final double scrollOffset;
}

/// Viewport layout snapshot used to render the selected range.
class FdcGridRangeSelectionOverlayContext {
  /// Creates a [FdcGridRangeSelectionOverlayContext].
  const FdcGridRangeSelectionOverlayContext({
    required this.bounds,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.rowHeight,
    required this.verticalScrollOffset,
    required this.rowTopAt,
    required this.bands,
    required this.borderColor,
    required this.backgroundColor,
    required this.borderThickness,
    required this.showSelectionHandle,
    required this.selectionHandleSize,
  });

  /// Normalized selected row and column bounds.
  final FdcGridRangeSelectionBounds bounds;

  /// Width of the grid body viewport, in logical pixels.
  final double viewportWidth;

  /// Height of the grid body viewport, in logical pixels.
  final double viewportHeight;

  /// Default rendered row height used by uniform-row overlay implementations.
  final double rowHeight;

  /// Current vertical body scroll offset, in logical pixels.
  final double verticalScrollOffset;

  /// Resolves row top positions in unscrolled vertical content coordinates.
  final FdcGridRangeSelectionRowTopResolver rowTopAt;

  /// Viewport bands used to project the selection overlay.
  final List<FdcGridRangeSelectionOverlayBand> bands;

  /// Color requested by the feature for the selected-range outline.
  final Color borderColor;

  /// Optional fill color requested by the feature for the selected range.
  ///
  /// A `null` value means that the overlay should not paint a selection fill.
  final Color? backgroundColor;

  /// Positive outline thickness requested by the feature, in logical pixels.
  final double borderThickness;

  /// Whether the resize handle is painted at the normalized bottom-right corner.
  final bool showSelectionHandle;

  /// Visible selection-handle size in logical pixels.
  final double selectionHandleSize;
}

/// Mutable runtime state contract for range selection attached to one grid
/// instance.
///
/// The Community grid host creates, calls, and owns the lifetime of one session per
/// attached [FdcGridRangeSelectionFeature]. Extension packages implement this class
/// to hold anchor/extent state, keyboard and pointer gesture state, clipboard
/// planning, context-menu contribution, and overlay construction. All row indexes are
/// zero-based data-row indexes; column indexes are source indexes unless a parameter
/// explicitly says visual order.
///
/// The Community package owns only the neutral grid/runtime seam. First-party and
/// compatible third-party extension packages may implement this stable
/// `fdc_ext.dart` contract. Implementations should treat host references and runtime
/// callbacks as attachment-scoped and release transient input state when detached or
/// reset by the host.
abstract class FdcGridRangeSelectionSession {
  /// Creates a [FdcGridRangeSelectionSession].
  const FdcGridRangeSelectionSession();

  /// Creates a disabled no-op session used when no range-selection extension
  /// is attached to the Community grid host.
  factory FdcGridRangeSelectionSession.noop() {
    return _FdcGridNoopRangeSelectionSession();
  }

  /// Anchor owned by this session for the retained range, or `null` when no
  /// range gesture has established one.
  ///
  /// The cell reference is attachment-scoped. Its row index is a zero-based
  /// data-row index and its source-column identity is stable across visual
  /// reorder operations.
  FdcGridCellRef? get anchorCell;

  /// Replaces the session-owned range anchor.
  ///
  /// Extension implementations update this during pointer or keyboard range
  /// gestures and clear it when the host resets the session.
  set anchorCell(FdcGridCellRef? value);

  /// Extent owned by this session for the retained range, or `null` when no
  /// range gesture has established one.
  ///
  /// The cell reference uses the same zero-based data-row and source-column
  /// coordinate space as [anchorCell].
  FdcGridCellRef? get extentCell;

  /// Replaces the session-owned range extent.
  ///
  /// Extensions normally move the extent while preserving [anchorCell]; clear
  /// both values when the retained range is discarded.
  set extentCell(FdcGridCellRef? value);

  /// True while the session is tracking the range-selection modifier gesture.
  ///
  /// This is transient input state owned by the extension session, not a
  /// retained range flag, and is valid only for the current grid attachment.
  bool get modifierDown;

  /// Updates the session-owned modifier gesture state.
  ///
  /// Hosts may query the value during neutral keyboard navigation; extensions
  /// must clear it when the modifier is released, input is cancelled, or the
  /// session is reset.
  set modifierDown(bool value);

  /// True while this session owns an active pointer-drag range gesture.
  ///
  /// The value is transient input state and must be cleared when the drag ends,
  /// is cancelled, or the host resets the session.
  bool get pointerDragActive;

  /// Updates whether this session owns an active pointer-drag gesture.
  set pointerDragActive(bool value);

  /// Last pointer-hovered cell tracked by this session, or `null` when no hover
  /// target is retained.
  ///
  /// The reference uses zero-based data-row and source-column coordinates and
  /// is attachment-scoped; clear it when pointer tracking ends or the host resets
  /// transient input state.
  FdcGridCellRef? get pointerHoverCell;

  /// Replaces the session-owned pointer-hover cell.
  set pointerHoverCell(FdcGridCellRef? value);

  /// True while this session has locked range projection to a captured scroll
  /// offset during an input gesture.
  ///
  /// Extensions own this transient flag and must clear it when the gesture or
  /// attachment lifecycle that established the lock ends.
  bool get scrollOffsetLockActive;

  /// Updates the session-owned scroll-offset lock state.
  set scrollOffsetLockActive(bool value);

  /// Whether anchor and extent currently describe an explicit multi-cell gesture range.
  ///
  /// Hosts use this to distinguish a deliberate range from the ordinary selected
  /// cell when deciding whether range-only commands or visuals should be active.
  bool get hasExplicitCellRange;

  /// Whether any selected-range state is currently retained by the session.
  ///
  /// Hosts may use this to decide whether Escape, reset, or lifecycle cleanup has
  /// work to perform. This may be true for a single-cell range as well as a larger
  /// rectangle.
  bool get hasRangeState;

  /// Whether transient keyboard or pointer gesture state is currently active.
  ///
  /// Hosts use this during focus and lifecycle transitions to release modifier, drag,
  /// hover, or scroll-lock state without necessarily discarding the selected range.
  bool get hasInputState;

  /// Whether the effective range-extension modifier is currently active.
  ///
  /// Implementations may derive this from keyboard state and other session input
  /// state. Hosts use it to decide whether navigation or pointer input should extend
  /// the current range instead of performing ordinary selection.
  bool get modifierActive;

  /// Whether [event] targets the modifier key used to extend a range.
  bool isModifierKeyEvent(KeyEvent event);

  /// Whether [event] represents the range modifier entering a pressed state.
  bool isModifierPressedEvent(KeyEvent event);

  /// Whether a global modifier transition should update range-selection input state.
  ///
  /// Implementations use the supplied editor, focus, hover, and enablement state
  /// to avoid intercepting modifier input owned by active text editors.
  bool shouldProcessGlobalModifierEvent({
    required bool enabled,
    required bool modifierKey,
    required bool pressed,
    required FdcGridCellRef? hoverCell,
    required bool hasActiveCellEditor,
    required bool hasGridTextInputFocus,
  });

  /// Updates modifier-driven range state from keyboard input.
  ///
  /// Returns whether selection state changed and the grid should react.
  bool updateModifierFromKeyboard({
    required bool enabled,
    required bool pressed,
    required FdcGridCellRef? currentCell,
  });

  /// Whether the current grid focus and editor state allow range-copy handling.
  bool shouldHandleCopyShortcut({
    required bool enabled,
    required bool copyEnabled,
    required bool hasActiveCellEditor,
    required bool gridCellHasPrimaryFocus,
  });

  /// Whether the current grid focus and editor state allow range-paste handling.
  bool shouldHandlePasteShortcut({
    required bool enabled,
    required bool pasteEnabled,
    required bool hasActiveCellEditor,
    required bool gridCellHasPrimaryFocus,
  });

  /// Whether Escape should dismiss current range-selection state.
  bool shouldHandleEscape({required bool enabled});

  /// Whether [cell] lies inside [bounds].
  bool containsCell(FdcGridRangeSelectionBounds? bounds, FdcGridCellRef? cell);

  /// Updates the cell currently under the pointer and returns whether state changed.
  bool updatePointerHoverCell(FdcGridCellRef? next);

  /// Starts a modifier-key range from [current], returning whether state changed.
  bool beginModifierRange(FdcGridCellRef? current);

  /// Ends the current modifier-key range gesture.
  bool endModifierRange();

  /// Resets the current state.
  void reset();

  /// Releases transient keyboard and pointer input state without discarding the range.
  void releaseInput();

  /// Clears the selected range while preserving unrelated host state.
  void clearRange();

  /// Starts or extends a range after grid cell navigation changed the selected cell.
  bool beginOrExtendFromSelectedCell({
    required FdcGridCellRef previousCell,
    required FdcGridCellRef currentCell,
  });

  /// Starts pointer-driven range extension at [target].
  ///
  /// Returns `false` when range selection is unavailable or the gesture should
  /// remain owned by normal cell selection.
  bool startPointerDrag({
    required bool enabled,
    required bool modifierActive,
    required FdcGridCellRef target,
    required FdcGridCellRef? selectedCell,
  });

  /// Starts resizing the retained range from its bottom-right selection handle.
  ///
  /// The normalized [anchor] remains fixed while pointer updates move the
  /// current extent. Returns `false` when range selection is unavailable.
  bool startSelectionHandleDrag({
    required bool enabled,
    required FdcGridCellRef anchor,
    required FdcGridCellRef extent,
  });

  /// Extends an active pointer drag to [target], returning whether state changed.
  bool updatePointerDrag(FdcGridCellRef target);

  /// Finishes the active pointer range gesture.
  bool endPointerDrag();

  /// Dismisses current range state and returns whether anything changed.
  bool dismissRange();

  /// Resolves the current rectangular range against the active visual column order.
  FdcGridRangeSelectionBounds? resolveBounds({
    required bool enabled,
    required FdcGridCellRef? selectedCell,
    required List<int> visualColumnIndexes,
  });

  /// Serializes [bounds] as tabular text and writes it to the system clipboard.
  Future<void> copySelectionToClipboard({
    required FdcGridRangeSelectionBounds bounds,
    required int rowCount,
    required int columnCount,
    required FdcGridRangeSelectionCellTextReader readCellText,
  });

  /// Reads tabular clipboard text and builds a validated paste plan for [bounds].
  ///
  /// Returns `null` when clipboard content cannot produce an applicable update.
  Future<FdcGridRangeSelectionPastePlan?> readClipboardPastePlan({
    required FdcGridRangeSelectionBounds bounds,
    required int rowCount,
    required int columnCount,
    required bool fillSingleValue,
    required FdcGridRangeSelectionCellEditablePredicate isCellEditable,
    required FdcGridRangeSelectionCellTextParser parseCellText,
  });

  /// Builds context-menu entries for the current range-selection state.
  List<FdcMenuEntry> buildContextMenuEntries(
    BuildContext context,
    FdcGridRangeSelectionContextMenuContext menuContext,
  );

  /// Builds the visual overlay for the selected range.
  Widget buildOverlay(
    BuildContext context,
    FdcGridRangeSelectionOverlayContext overlayContext,
  );
}

class _FdcGridNoopRangeSelectionSession extends FdcGridRangeSelectionSession {
  _FdcGridNoopRangeSelectionSession();

  @override
  FdcGridCellRef? anchorCell;

  @override
  FdcGridCellRef? extentCell;

  @override
  bool modifierDown = false;

  @override
  bool pointerDragActive = false;

  @override
  FdcGridCellRef? pointerHoverCell;

  @override
  bool scrollOffsetLockActive = false;

  @override
  bool get hasExplicitCellRange => false;

  @override
  bool get hasRangeState => false;

  @override
  bool get hasInputState => false;

  @override
  bool get modifierActive => false;

  @override
  bool isModifierKeyEvent(KeyEvent event) => false;

  @override
  bool isModifierPressedEvent(KeyEvent event) => false;

  @override
  bool shouldProcessGlobalModifierEvent({
    required bool enabled,
    required bool modifierKey,
    required bool pressed,
    required FdcGridCellRef? hoverCell,
    required bool hasActiveCellEditor,
    required bool hasGridTextInputFocus,
  }) => false;

  @override
  bool updateModifierFromKeyboard({
    required bool enabled,
    required bool pressed,
    required FdcGridCellRef? currentCell,
  }) => false;

  @override
  bool shouldHandleCopyShortcut({
    required bool enabled,
    required bool copyEnabled,
    required bool hasActiveCellEditor,
    required bool gridCellHasPrimaryFocus,
  }) => false;

  @override
  bool shouldHandlePasteShortcut({
    required bool enabled,
    required bool pasteEnabled,
    required bool hasActiveCellEditor,
    required bool gridCellHasPrimaryFocus,
  }) => false;

  @override
  bool shouldHandleEscape({required bool enabled}) => false;

  @override
  bool containsCell(
    FdcGridRangeSelectionBounds? bounds,
    FdcGridCellRef? cell,
  ) => false;

  @override
  bool updatePointerHoverCell(FdcGridCellRef? next) => false;

  @override
  bool beginModifierRange(FdcGridCellRef? current) => false;

  @override
  bool endModifierRange() => false;

  @override
  void reset() {}

  @override
  void releaseInput() {}

  @override
  void clearRange() {}

  @override
  bool beginOrExtendFromSelectedCell({
    required FdcGridCellRef previousCell,
    required FdcGridCellRef currentCell,
  }) => false;

  @override
  bool startPointerDrag({
    required bool enabled,
    required bool modifierActive,
    required FdcGridCellRef target,
    required FdcGridCellRef? selectedCell,
  }) => false;

  @override
  bool startSelectionHandleDrag({
    required bool enabled,
    required FdcGridCellRef anchor,
    required FdcGridCellRef extent,
  }) => false;

  @override
  bool updatePointerDrag(FdcGridCellRef target) => false;

  @override
  bool endPointerDrag() => false;

  @override
  bool dismissRange() => false;

  @override
  FdcGridRangeSelectionBounds? resolveBounds({
    required bool enabled,
    required FdcGridCellRef? selectedCell,
    required List<int> visualColumnIndexes,
  }) => null;

  @override
  Future<void> copySelectionToClipboard({
    required FdcGridRangeSelectionBounds bounds,
    required int rowCount,
    required int columnCount,
    required FdcGridRangeSelectionCellTextReader readCellText,
  }) async {}

  @override
  Future<FdcGridRangeSelectionPastePlan?> readClipboardPastePlan({
    required FdcGridRangeSelectionBounds bounds,
    required int rowCount,
    required int columnCount,
    required bool fillSingleValue,
    required FdcGridRangeSelectionCellEditablePredicate isCellEditable,
    required FdcGridRangeSelectionCellTextParser parseCellText,
  }) async {
    return null;
  }

  @override
  List<FdcMenuEntry> buildContextMenuEntries(
    BuildContext context,
    FdcGridRangeSelectionContextMenuContext menuContext,
  ) => const <FdcMenuEntry>[];

  @override
  Widget buildOverlay(
    BuildContext context,
    FdcGridRangeSelectionOverlayContext overlayContext,
  ) => const SizedBox.shrink();
}

/// Extension contract for grid range-selection behavior.
///
/// The Community grid host calls this policy/configuration object and owns the
/// attachment lifecycle. Extension packages implement it to provide capability
/// policy, visual styling, per-grid session creation, clipboard behavior, keyboard
/// handling, and lifecycle hooks while the Community grid remains neutral.
///
/// This class is part of the stable `fdc_ext.dart` extension seam and may be
/// implemented by compatible third-party packages. A feature instance should keep
/// public configuration immutable where practical; mutable per-grid state belongs in
/// the [FdcGridRangeSelectionSession] returned by [createSession].
abstract class FdcGridRangeSelectionFeature {
  /// Creates a [FdcGridRangeSelectionFeature].
  const FdcGridRangeSelectionFeature();

  /// Whether the feature is enabled by its public configuration.
  bool get enabled;

  /// Resolves whether the feature is currently available for the attached grid.
  bool isAvailable(FdcGridRangeSelectionHost host);

  /// Resolves whether range copy commands are currently allowed.
  bool canCopyRange(FdcGridRangeSelectionHost host);

  /// Resolves whether range paste commands are currently allowed.
  bool canPasteRange(FdcGridRangeSelectionHost host);

  /// Resolves whether the range context menu is currently allowed.
  bool canShowContextMenu(FdcGridRangeSelectionHost host);

  /// Resolves whether a single clipboard value can fill the selected range.
  bool canFillSingleValue(FdcGridRangeSelectionHost host);

  /// Resolves the range outline color supplied by the feature.
  ///
  /// Extension implementations must return a non-null value.
  Color resolveBorderColor(FdcGridRangeSelectionHost host);

  /// Resolves the optional selected range background color supplied by the
  /// feature.
  Color? resolveBackgroundColor(FdcGridRangeSelectionHost host);

  /// Resolves the range outline thickness supplied by the feature.
  ///
  /// Extension implementations must return a positive value.
  double resolveBorderThickness(FdcGridRangeSelectionHost host);

  /// Resolves whether the selection resize handle is visible.
  bool resolveShowSelectionHandle(FdcGridRangeSelectionHost host) => false;

  /// Resolves the visible selection resize-handle size.
  double resolveSelectionHandleSize(FdcGridRangeSelectionHost host) => 0.0;

  /// Creates mutable runtime state for one grid attachment.
  FdcGridRangeSelectionSession createSession(FdcGridRangeSelectionHost host) {
    return _FdcGridNoopRangeSelectionSession();
  }

  /// Called when the feature is connected to a grid instance.
  void attach(FdcGridRangeSelectionHost host) {}

  /// Called when the feature is disconnected from a grid instance.
  void detach() {}

  /// Notifies the feature that the attached grid reset its range state.
  ///
  /// Immutable feature configuration objects can ignore this. Feature
  /// implementations that keep external state may use it to synchronize with
  /// dataset, column, and lifecycle changes.
  void reset({bool rebuild = true}) {}

  /// Gives the feature first chance to handle grid keyboard input.
  ///
  /// Returning `null` lets default grid key handling continue.
  KeyEventResult? handleKeyEvent(KeyEvent event) => null;
}

/// Read-only and command surface exposed by the Community grid to range-selection
/// features.
///
/// The Community runtime implements this host and passes it to extension feature
/// policy and lifecycle methods. Extension packages consume the contract; they must
/// not implement it for normal grid integration. State getters describe the attached
/// grid instance at call time, and command methods request host-owned rebuild or reset
/// behavior.
///
/// This class is part of the stable `fdc_ext.dart` extension seam.
abstract class FdcGridRangeSelectionHost {
  /// Creates a [FdcGridRangeSelectionHost].
  const FdcGridRangeSelectionHost();

  /// Dataset attached to the host grid for the lifetime of this host view.
  ///
  /// Extension code may inspect public dataset state and values through this
  /// reference but must not assume that the dataset current record is the same
  /// row as an arbitrary range-selection cell.
  FdcDataSet get dataSet;

  /// Live dataset state observed by the host at call time.
  ///
  /// Extensions use this to gate commands such as paste against edit/insert or
  /// other non-browse states; the host remains the owner of dataset lifecycle.
  FdcDataSetState get dataSetState;

  /// Host-selected cell at call time, or `null` when the grid has no cell
  /// selection.
  ///
  /// Its row index is zero-based in the current data-row space. Column identity
  /// follows [FdcGridCellRef]'s source-column contract rather than visible order.
  FdcGridCellRef? get selectedCell;

  /// Snapshot of columns currently visible in the host, ordered by current
  /// visual position from left to right across pinned and scrollable regions.
  ///
  /// Extension code may use the list for coordinate translation and command
  /// planning but must not mutate it or retain it as authoritative after host
  /// layout changes.
  List<FdcGridColumn<dynamic>> get visibleColumns;

  /// Number of data rows currently addressable by host range-selection coordinates.
  ///
  /// Row indexes accepted by the seam are zero-based and valid from zero through
  /// `rowCount - 1`; extensions must read this value again after dataset/view
  /// changes rather than retaining it as a schema-level constant.
  int get rowCount;

  /// Whether the attached grid currently contains one or more expanded detail rows.
  ///
  /// Features can use this state when determining whether range interaction or
  /// projection is compatible with the current row layout.
  bool get hasExpandedDetailRows;

  /// Whether an in-place cell editor is currently active in the attached grid.
  ///
  /// Features should avoid claiming keyboard shortcuts or modifier transitions that
  /// belong to the active editor.
  bool get hasActiveCellEditor;

  /// Requests a host rebuild after range-selection state changes.
  void requestRebuild();

  /// Resets host-owned range-selection state and optionally requests a rebuild.
  void resetRangeSelectionState({bool rebuild = true});
}
