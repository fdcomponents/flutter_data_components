// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Central scroll-state owner for the grid viewport.
///
/// Pinned regions never become scrollable containers; they read and mutate the
/// same coordinator offsets used by the center ListView and the viewport-level
/// scrollbars.
class FdcGridScrollCoordinator {
  FdcGridScrollCoordinator() {
    _verticalController.addListener(_syncVerticalOffsetFromController);
    _horizontalController.addListener(_syncHorizontalOffsetFromController);
  }

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  /// Raw controller exposed only for Flutter Scrollable/Scrollbar plumbing.
  /// Grid logic should use coordinator methods and cached metrics instead.
  ScrollController get verticalFlutterController => _verticalController;

  /// Raw controller exposed only for Flutter Scrollable/Scrollbar plumbing.
  /// Grid logic should use coordinator methods and cached metrics instead.
  ScrollController get horizontalFlutterController => _horizontalController;

  final ValueNotifier<double> verticalOffset = ValueNotifier<double>(0.0);
  final ValueNotifier<double> horizontalOffset = ValueNotifier<double>(0.0);

  /// Repaint-only signal for horizontal visual geometry changes that keep the
  /// logical scroll offset locked. During right-pinned resize the effective
  /// horizontal origin is read through currentHorizontalOffset, so the double
  /// offset value may not change even though header/body geometry must repaint
  /// in realtime.
  final ValueNotifier<int> horizontalResizeTick = ValueNotifier<int>(0);

  /// Rebuild signal for detached vertical bands. It is advanced only from
  /// metrics confirmed by the center ListView/ScrollPosition, so row indicator
  /// and pinned regions never project a new viewport height before Flutter's
  /// central scrollable has accepted it.
  final ValueNotifier<int> verticalViewportTick = ValueNotifier<int>(0);

  double _confirmedVerticalViewportDimension = 0.0;
  double? _pendingViewportHeight;
  bool _confirmedVerticalPublishScheduled = false;
  bool _disposed = false;

  double _verticalMinScrollExtent = 0.0;
  double _verticalMaxScrollExtent = 0.0;
  double _verticalViewportDimension = 0.0;
  var _verticalOffsetRestoreLockDepth = 0;
  var _verticalJumpSuppressionDepth = 0;
  double? _lockedVerticalOffsetDuringRestore;
  double? _suppressedVerticalJumpOffset;
  double _horizontalMinScrollExtent = 0.0;
  double _horizontalMaxScrollExtent = 0.0;
  double _horizontalViewportDimension = 0.0;
  var _horizontalResizeLockDepth = 0;
  var _horizontalOffsetRestoreLockDepth = 0;
  double? _lockedHorizontalOffsetDuringResize;
  double? _lockedHorizontalOffsetDuringRestore;
  bool _pendingResizeOffsetRestore = false;
  int _horizontalResizeLayoutGeneration = 0;
  int _horizontalResizeRestoredGeneration = 0;
  bool _pendingHorizontalResizeEndReconcile = false;

  double get currentVerticalOffset =>
      _lockedVerticalOffsetDuringRestore ?? verticalOffset.value;

  /// Best available live vertical origin for pointer hit-testing and UX
  /// actions that must preserve the user's current viewport.
  double get liveVerticalOffset {
    final lockedOffset = _lockedVerticalOffsetDuringRestore;
    if (lockedOffset != null) {
      return lockedOffset;
    }

    final position = _firstAttachedPosition(
      _verticalController,
      currentOffset: verticalOffset.value,
    );
    return position?.pixels ?? verticalOffset.value;
  }

  /// Viewport height last confirmed by the center ListView. Detached bands
  /// use this dimension instead of reacting to shell constraints one frame
  /// before the central ScrollPosition has accepted the new viewport.
  double confirmedVerticalViewportDimension(double fallback) {
    return _confirmedVerticalViewportDimension > 0
        ? _confirmedVerticalViewportDimension
        : fallback;
  }

  /// During an active column resize the center Scrollable can temporarily
  /// report a different pixel offset while its content extent is changing.
  /// Treat the resize lock as the visual source of truth so detached header
  /// transforms, body rows, and diagnostics all read the same origin.
  double get currentHorizontalOffset =>
      _lockedHorizontalOffset ?? horizontalOffset.value;

  /// Best available live horizontal origin for UX actions that need to
  /// preserve the user's current viewport. The cached notifier can be stale
  /// after overlay/menu layout notifications; the attached controller position
  /// remains authoritative when available.
  double get liveHorizontalOffset {
    if (_lockedHorizontalOffset != null) {
      return _lockedHorizontalOffset!;
    }

    final position = _firstAttachedPosition(
      _horizontalController,
      currentOffset: horizontalOffset.value,
    );
    return position?.pixels ?? horizontalOffset.value;
  }

  bool get hasVerticalClients => _verticalController.hasClients;
  bool get hasHorizontalClients => _horizontalController.hasClients;

  /// Captures the most trustworthy horizontal origin for menu/view actions.
  ///
  /// Menu overlays and focus changes can briefly attach an additional fresh
  /// horizontal position at pixels=0 before the real body position has been
  /// reconciled. For preservation snapshots, prefer the farthest attached
  /// non-zero body origin over the cached notifier so a direct controller jump
  /// or transient zero packet does not make a later clear-filter action restore
  /// the grid to the leading edge.
  double horizontalOffsetSnapshotForViewAction() {
    var snapshot = currentHorizontalOffset;
    if (_horizontalController.hasClients) {
      for (final position in _horizontalController.positions) {
        if (position.maxScrollExtent <= position.minScrollExtent) {
          continue;
        }
        if (position.pixels > snapshot) {
          snapshot = position.pixels;
        }
      }
    }

    if (snapshot <= horizontalMinScrollExtent) {
      return horizontalMinScrollExtent;
    }

    final maxExtent = math.max(horizontalMaxScrollExtent, snapshot);
    return snapshot.clamp(horizontalMinScrollExtent, maxExtent).toDouble();
  }

  bool get hasHorizontalScrollableRange {
    if (horizontalMaxScrollExtent > horizontalMinScrollExtent) {
      return true;
    }
    if (_horizontalController.hasClients) {
      for (final position in _horizontalController.positions) {
        if (position.maxScrollExtent > position.minScrollExtent) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _verticalOffsetRestoreLocked => _verticalOffsetRestoreLockDepth > 0;

  bool get _verticalJumpSuppressed => _verticalJumpSuppressionDepth > 0;

  bool get horizontalResizeLocked => _horizontalResizeLockDepth > 0;

  bool get _horizontalOffsetRestoreLocked =>
      _horizontalOffsetRestoreLockDepth > 0;

  bool get _horizontalOffsetLocked =>
      horizontalResizeLocked || _horizontalOffsetRestoreLocked;

  double? get _lockedHorizontalOffset =>
      _lockedHorizontalOffsetDuringResize ??
      _lockedHorizontalOffsetDuringRestore;

  /// Returns the real center content width. Horizontal resize must never
  /// freeze or inflate the Scrollable extent: the attached ScrollPosition is
  /// authoritative and may clamp as column widths change. Gesture stability
  /// is provided by screen-space pointer deltas, not by a synthetic extent.
  double effectiveHorizontalContentWidth(
    double contentWidth, {
    double? viewportWidth,
  }) {
    return contentWidth;
  }

  void beginColumnResizeLock() {
    final liveOffset = liveHorizontalOffset;
    // Column resize is a single-owner gesture. Treat a second begin as a
    // stale-session replacement rather than nesting locks indefinitely when a
    // virtualized resize handle vanished before drag end/cancel was delivered.
    _horizontalResizeLockDepth = 1;
    _lockedHorizontalOffsetDuringResize = liveOffset;
  }

  void endColumnResizeLock() {
    if (_horizontalResizeLockDepth <= 0) {
      _horizontalResizeLockDepth = 0;
      _lockedHorizontalOffsetDuringResize = null;
      return;
    }

    _horizontalResizeLockDepth--;
    if (_horizontalResizeLockDepth == 0) {
      final lockedOffset = _lockedHorizontalOffsetDuringResize;
      _lockedHorizontalOffsetDuringResize = null;
      _reconcileResizeOffset(lockedOffset);
    }
  }

  void _reconcileResizeOffset(double? resizeOffset) {
    if (resizeOffset == null || _pendingHorizontalResizeEndReconcile) {
      return;
    }

    _pendingHorizontalResizeEndReconcile = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pendingHorizontalResizeEndReconcile = false;
      if (_disposed || horizontalResizeLocked) {
        return;
      }

      final position = _firstAttachedPosition(
        _horizontalController,
        currentOffset: resizeOffset,
      );
      if (position == null) {
        return;
      }

      // Accept the real extent after the resize-ending layout and publish the
      // same clamped origin to the controller and detached horizontal bands.
      _horizontalMinScrollExtent = position.minScrollExtent;
      _horizontalMaxScrollExtent = position.maxScrollExtent;
      _horizontalViewportDimension = position.viewportDimension;
      final nextOffset = resizeOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      _setHorizontalOffset(nextOffset);
      if ((position.pixels - nextOffset).abs() >= 0.5) {
        _horizontalController.jumpTo(nextOffset);
      }
      notifyHorizontalResizeVisualChange();
    });
  }

  /// Suppresses delayed programmatic vertical jumps while a mouse-only cell
  /// control performs an in-place value mutation. Unlike a full restore lock,
  /// this guard does not write or jump the vertical controller. It only blocks
  /// stale scheduled reset/reveal commands, so inner cell controls do
  /// not wake the vertical scrollbar with a no-op restore.
  void beginVerticalJumpSuppression(double offset) {
    _verticalJumpSuppressionDepth++;
    _suppressedVerticalJumpOffset = offset;
  }

  void endVerticalJumpSuppression() {
    if (_verticalJumpSuppressionDepth <= 0) {
      _verticalJumpSuppressionDepth = 0;
      _suppressedVerticalJumpOffset = null;
      return;
    }

    _verticalJumpSuppressionDepth--;
    if (_verticalJumpSuppressionDepth == 0) {
      _suppressedVerticalJumpOffset = null;
    }
  }

  /// Preserves the vertical origin while a pointer cell action changes focus,
  /// selection, or an inline display value. This is intentionally narrower than
  /// keyboard navigation: keyboard moves may reveal rows, while mouse entry into
  /// an already visible cell must not reposition the viewport.
  void beginVerticalOffsetRestore(double offset) {
    _verticalOffsetRestoreLockDepth++;
    _lockedVerticalOffsetDuringRestore = offset;
    _setVerticalOffset(offset);
  }

  void endVerticalOffsetRestore() {
    if (_verticalOffsetRestoreLockDepth <= 0) {
      _verticalOffsetRestoreLockDepth = 0;
      _lockedVerticalOffsetDuringRestore = null;
      return;
    }

    _verticalOffsetRestoreLockDepth--;
    if (_verticalOffsetRestoreLockDepth == 0) {
      final lockedOffset = _lockedVerticalOffsetDuringRestore;
      _restoreVerticalLockedOffset(lockedOffset);
      _lockedVerticalOffsetDuringRestore = null;
    }
  }

  /// Releases a pending mouse-cell vertical restore without jumping the
  /// controller back to the preserved offset. User wheel input has priority
  /// over the delayed post-frame restore scheduled by a cell click.
  void cancelVerticalOffsetRestore() {
    _verticalOffsetRestoreLockDepth = 0;
    _lockedVerticalOffsetDuringRestore = null;
  }

  bool restoreVerticalOffset(double offset) {
    if (!_verticalOffsetRestoreLocked) {
      return jumpVerticalTo(offset);
    }

    _lockedVerticalOffsetDuringRestore ??= offset;
    _restoreVerticalLockedOffset(_lockedVerticalOffsetDuringRestore ?? offset);
    return true;
  }

  /// Moves the active vertical restore-lock origin.
  ///
  /// Range-selection auto-scroll is an intentional scroll while native drag
  /// scrolling remains locked. Updating the origin prevents the restore guard
  /// from snapping the viewport back to the Shift-session start offset.
  bool moveVerticalOffsetRestoreLock(double offset) {
    if (!_verticalOffsetRestoreLocked) {
      return jumpVerticalTo(offset);
    }
    final nextOffset = offset
        .clamp(_verticalMinScrollExtent, _verticalMaxScrollExtent)
        .toDouble();
    _lockedVerticalOffsetDuringRestore = nextOffset;
    _setVerticalOffset(nextOffset);
    _restoreVerticalLockedOffset(nextOffset);
    return true;
  }

  /// Preserves the horizontal origin while a view mutation rebuilds or
  /// reattaches the center scrollable. Flutter can briefly attach a fresh
  /// horizontal position at pixels=0 during filter/sort/menu transitions; this
  /// lock keeps that transient position from becoming the grid's visual origin.
  void beginHorizontalOffsetRestore(double offset) {
    _horizontalOffsetRestoreLockDepth++;
    _lockedHorizontalOffsetDuringRestore = offset;
    _setHorizontalOffset(offset);
  }

  void endHorizontalOffsetRestore() {
    if (_horizontalOffsetRestoreLockDepth <= 0) {
      _horizontalOffsetRestoreLockDepth = 0;
      _lockedHorizontalOffsetDuringRestore = null;
      return;
    }

    _horizontalOffsetRestoreLockDepth--;
    if (_horizontalOffsetRestoreLockDepth == 0) {
      final lockedOffset = _lockedHorizontalOffsetDuringRestore;
      // Keep the restore lock active during the final jump. The grid can receive
      // a zero-range metrics packet while the header-filter clear rebuild is
      // settling; releasing the lock first would make the final clamp use that
      // stale max extent and snap the controller to the left edge.
      _restoreHorizontalLockedOffset(lockedOffset);
      _lockedHorizontalOffsetDuringRestore = null;
    }
  }

  bool restoreHorizontalOffset(double offset) {
    if (!_horizontalOffsetLocked) {
      return jumpHorizontalTo(offset);
    }

    _lockedHorizontalOffsetDuringRestore ??= offset;
    _restoreHorizontalLockedOffset(_lockedHorizontalOffset ?? offset);
    return true;
  }

  /// Moves the active horizontal restore-lock origin for an intentional
  /// range-selection auto-scroll step.
  bool moveHorizontalOffsetRestoreLock(double offset) {
    if (!_horizontalOffsetRestoreLocked) {
      return jumpHorizontalTo(offset);
    }
    final nextOffset = offset
        .clamp(_horizontalMinScrollExtent, _horizontalMaxScrollExtent)
        .toDouble();
    _lockedHorizontalOffsetDuringRestore = nextOffset;
    _setHorizontalOffset(nextOffset);
    _restoreHorizontalLockedOffset(nextOffset);
    return true;
  }

  void addVerticalScrollListener(VoidCallback listener) {
    _verticalController.addListener(listener);
  }

  void removeVerticalScrollListener(VoidCallback listener) {
    _verticalController.removeListener(listener);
  }

  void addHorizontalScrollListener(VoidCallback listener) {
    _horizontalController.addListener(listener);
  }

  void removeHorizontalScrollListener(VoidCallback listener) {
    _horizontalController.removeListener(listener);
  }

  /// Resynchronizes the cached vertical offset from the currently attached
  /// Flutter position without changing the offset when the ListView is
  /// temporarily detached during a viewport rebuild.
  void syncVerticalOffsetFromAttachedPosition() {
    final position = _firstAttachedPosition(
      _verticalController,
      currentOffset: currentVerticalOffset,
    );
    if (position == null) {
      return;
    }
    updateMetrics(position);
  }

  void updateMetrics(ScrollMetrics metrics) {
    if (metrics.axis == Axis.vertical) {
      _publishConfirmedVerticalMetrics(metrics);
    }
    _updateExtents(metrics);
    if (metrics.axis == Axis.vertical) {
      if (_verticalJumpSuppressed) {
        _keepSuppressedVerticalOffset();
        return;
      }
      if (_verticalOffsetRestoreLocked) {
        _keepLockedVerticalOffset();
        return;
      }
      _setVerticalOffset(metrics.pixels);
      return;
    }

    if (metrics.axis == Axis.horizontal) {
      if (_horizontalOffsetLocked) {
        _keepLockedHorizontalOffset();
        return;
      }
      _setHorizontalOffset(metrics.pixels);
    }
  }

  /// Updates viewport/extents after Flutter relayout without treating the
  /// notification as user scroll. ScrollMetricsNotification can be emitted while
  /// a Scrollable is being reattached/relaid out and may temporarily report
  /// pixels=0. Accepting that as the real horizontal offset breaks detached
  /// header/body alignment during column resize. Keep the cached offset and
  /// only clamp it if the new extents make it invalid.
  void updateViewportMetrics(ScrollMetrics metrics) {
    if (metrics.axis == Axis.vertical) {
      // Viewport metrics are layout notifications, not user-scroll updates.
      // Ignore packets that do not describe one of this coordinator's attached
      // vertical positions; nested grids and arbitrary detail Scrollables must
      // never resize or repaint the parent grid's detached vertical regions.
      if (!_matchesAttachedVerticalPosition(metrics)) {
        return;
      }
      _publishConfirmedVerticalMetrics(metrics);
      _updateVerticalViewportExtents(metrics);
      if (_verticalJumpSuppressed) {
        _keepSuppressedVerticalOffset();
        return;
      }
      if (_verticalOffsetRestoreLocked) {
        _keepLockedVerticalOffset();
        return;
      }
      _clampCachedVerticalOffsetToExtents();
      return;
    }

    if (metrics.axis == Axis.horizontal &&
        _shouldIgnoreHorizontalMetrics(metrics)) {
      return;
    }

    _updateExtents(metrics);
    if (metrics.axis == Axis.horizontal) {
      if (_horizontalOffsetLocked) {
        _keepLockedHorizontalOffset();
        return;
      }
      _clampCachedHorizontalOffsetToExtents();
    }
  }

  bool _matchesAttachedVerticalPosition(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical || !_verticalController.hasClients) {
      return false;
    }

    for (final position in _verticalController.positions) {
      if ((position.pixels - metrics.pixels).abs() < 0.5 &&
          (position.minScrollExtent - metrics.minScrollExtent).abs() < 0.5 &&
          (position.maxScrollExtent - metrics.maxScrollExtent).abs() < 0.5 &&
          (position.viewportDimension - metrics.viewportDimension).abs() <
              0.5) {
        return true;
      }
    }
    return false;
  }

  void _publishConfirmedVerticalMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical || metrics.viewportDimension <= 0) {
      return;
    }

    _pendingViewportHeight = metrics.viewportDimension;

    // ScrollMetricsNotification can be dispatched from RenderViewport layout.
    // Publishing the detached-band viewport synchronously from that callback
    // would schedule a rebuild during layout, so coalesce packets and publish
    // only the latest dimension after the frame. Live row positioning remains
    // driven directly by the central ScrollPosition pixels.
    if (_confirmedVerticalPublishScheduled) {
      return;
    }
    _confirmedVerticalPublishScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _confirmedVerticalPublishScheduled = false;
      if (_disposed) {
        return;
      }
      _flushConfirmedVerticalViewport();
    });
  }

  void _flushConfirmedVerticalViewport() {
    final nextViewportDimension = _pendingViewportHeight;
    if (nextViewportDimension == null) {
      return;
    }

    _pendingViewportHeight = null;
    if ((_confirmedVerticalViewportDimension - nextViewportDimension).abs() <
        0.5) {
      return;
    }

    _confirmedVerticalViewportDimension = nextViewportDimension;
    verticalViewportTick.value++;
  }

  bool _shouldIgnoreHorizontalMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.horizontal) {
      return false;
    }

    // The viewport-level NotificationListener receives ScrollMetricsNotification
    // from every horizontal Scrollable below the grid, including header-filter
    // text fields and popup/menu internals. Those packets must not overwrite the
    // grid center scroll extent. When the real horizontal controller is attached,
    // its active ScrollPosition is the authoritative grid-center metrics source.
    if (_horizontalController.hasClients && _horizontalMaxScrollExtent > 0) {
      var matchesAttachedGridPosition = false;
      for (final position in _horizontalController.positions) {
        matchesAttachedGridPosition =
            (position.pixels - metrics.pixels).abs() < 0.5 &&
            (position.minScrollExtent - metrics.minScrollExtent).abs() < 0.5 &&
            (position.maxScrollExtent - metrics.maxScrollExtent).abs() < 0.5 &&
            (position.viewportDimension - metrics.viewportDimension).abs() <
                0.5;
        if (matchesAttachedGridPosition) {
          break;
        }
      }
      if (!matchesAttachedGridPosition) {
        return true;
      }
    }

    // If no attached controller position is available yet, fall back to shape
    // checks. Tiny or zero-range descendant metrics cannot represent the real
    // grid center viewport once the grid has already observed a non-zero range.
    if (_horizontalMaxScrollExtent <= 0) {
      return false;
    }

    if (metrics.viewportDimension <= 0) {
      return true;
    }
    if (_horizontalViewportDimension > 0 &&
        metrics.viewportDimension < _horizontalViewportDimension - 1.0) {
      return true;
    }

    // A zero-range horizontal metrics packet cannot represent the real grid
    // center viewport while the cached origin is still valid in the previous
    // non-zero extent. Menu overlays, text fields, and temporarily reattached
    // descendants can otherwise make a horizontally scrolled grid jump to the
    // leading edge before filter/sort actions restore the preserved origin.
    if (metrics.maxScrollExtent <= 0 &&
        currentHorizontalOffset > metrics.maxScrollExtent &&
        currentHorizontalOffset > metrics.minScrollExtent &&
        _horizontalMaxScrollExtent >= currentHorizontalOffset) {
      return true;
    }

    return false;
  }

  void _updateVerticalViewportExtents(ScrollMetrics metrics) {
    final cachedOffset = currentVerticalOffset;
    final reportedMax = metrics.maxScrollExtent;

    // ScrollMetricsNotification is layout-only. During overlay/focus changes
    // Flutter can briefly report a smaller vertical extent, sometimes even a
    // fresh zero-range position, before the real ListView position settles.
    // Treat that entire packet as transient, not as proof that the visual
    // origin or visible row range should move. Actual ScrollUpdate/controller
    // sync and explicit reset/clamp operations remain authoritative for moving
    // the offset.
    if (cachedOffset > reportedMax &&
        cachedOffset > metrics.minScrollExtent &&
        reportedMax < _verticalMaxScrollExtent) {
      return;
    }

    _verticalMinScrollExtent = metrics.minScrollExtent;
    _verticalMaxScrollExtent = reportedMax;
    _verticalViewportDimension = metrics.viewportDimension;
  }

  void _updateExtents(ScrollMetrics metrics) {
    if (metrics.axis == Axis.vertical) {
      _verticalMinScrollExtent = metrics.minScrollExtent;
      _verticalMaxScrollExtent = metrics.maxScrollExtent;
      _verticalViewportDimension = metrics.viewportDimension;
      return;
    }

    if (metrics.axis == Axis.horizontal) {
      _horizontalMinScrollExtent = metrics.minScrollExtent;
      _horizontalViewportDimension = metrics.viewportDimension;

      if (_horizontalOffsetLocked) {
        final lockedOffset = _lockedHorizontalOffset ?? currentHorizontalOffset;
        // Resizing a column changes the horizontal scrollable content width.
        // During that relayout Flutter can briefly report a fresh horizontal
        // position with maxScrollExtent=0/pixels=0 from the reattached
        // scrollable. Do not let that transient metrics packet collapse the
        // cached extent below the locked visual origin. Larger extents are safe
        // to accept because the content can grow while the user drags.
        if (metrics.maxScrollExtent >= lockedOffset ||
            metrics.maxScrollExtent > _horizontalMaxScrollExtent) {
          _horizontalMaxScrollExtent = metrics.maxScrollExtent;
        }
        return;
      }

      _horizontalMaxScrollExtent = metrics.maxScrollExtent;
    }
  }

  void _syncVerticalOffsetFromController() {
    _syncControllerState(_verticalController, Axis.vertical);
  }

  void _syncHorizontalOffsetFromController() {
    _syncControllerState(_horizontalController, Axis.horizontal);
  }

  void _syncControllerState(ScrollController controller, Axis axis) {
    final position = _firstAttachedPosition(
      controller,
      currentOffset: axis == Axis.vertical
          ? currentVerticalOffset
          : currentHorizontalOffset,
    );
    if (position == null) {
      if (axis == Axis.vertical) {
        // A cell pointer action can rebuild/reattach the body ListView while
        // its viewport is being restored. A temporary no-client window is not
        // proof that the user scrolled back to the first row; keep the cached
        // visual origin until an attached vertical position reports real
        // metrics again.
        if (_verticalOffsetRestoreLocked) {
          _keepLockedVerticalOffset();
        }
      } else if (!_horizontalOffsetLocked && !hasHorizontalScrollableRange) {
        _setHorizontalOffset(0.0);
      }
      return;
    }

    updateMetrics(position);
  }

  double get verticalMinScrollExtent => _verticalMinScrollExtent;
  double get verticalMaxScrollExtent => _verticalMaxScrollExtent;
  double get horizontalMinScrollExtent => _horizontalMinScrollExtent;
  double get horizontalMaxScrollExtent => _horizontalMaxScrollExtent;

  double verticalViewportDimension(double fallback) {
    return _verticalViewportDimension > 0
        ? _verticalViewportDimension
        : fallback;
  }

  double horizontalViewportDimension(double fallback) {
    return _horizontalViewportDimension > 0
        ? _horizontalViewportDimension
        : fallback;
  }

  void updateVerticalLayoutExtents({
    required double viewportDimension,
    required double contentExtent,
  }) {
    if (viewportDimension <= 0) {
      return;
    }

    final resolvedMaxScrollExtent = math.max(
      0.0,
      contentExtent - viewportDimension,
    );
    _verticalMinScrollExtent = 0.0;
    _verticalViewportDimension = viewportDimension;
    _verticalMaxScrollExtent = resolvedMaxScrollExtent;
  }

  bool isHorizontalRangeOutside({
    required double leadingEdge,
    required double trailingEdge,
    double fallbackViewportDimension = 0.0,
  }) {
    return _isRangeOutside(
      currentOffset: currentHorizontalOffset,
      viewportDimension: horizontalViewportDimension(fallbackViewportDimension),
      leadingEdge: leadingEdge,
      trailingEdge: trailingEdge,
    );
  }

  bool isVerticalRangeOutside({
    required double leadingEdge,
    required double trailingEdge,
    double fallbackViewportDimension = 0.0,
  }) {
    return _isRangeOutside(
      currentOffset: currentVerticalOffset,
      viewportDimension: verticalViewportDimension(fallbackViewportDimension),
      leadingEdge: leadingEdge,
      trailingEdge: trailingEdge,
    );
  }

  bool _isRangeOutside({
    required double currentOffset,
    required double viewportDimension,
    required double leadingEdge,
    required double trailingEdge,
  }) {
    if (viewportDimension <= 0) {
      return trailingEdge > leadingEdge;
    }

    final currentTrailingEdge = currentOffset + viewportDimension;
    return trailingEdge <= currentOffset || leadingEdge >= currentTrailingEdge;
  }

  ScrollPosition? _firstAttachedPosition(
    ScrollController controller, {
    required double currentOffset,
  }) {
    if (!controller.hasClients || controller.positions.isEmpty) {
      return null;
    }

    // Do not use ScrollController.position here: Flutter asserts when a
    // controller is attached to more than one ScrollPosition. During relayout a
    // controller can briefly expose multiple positions; prefer the one closest
    // to the last cached offset so a fresh zero-pixel position does not reset
    // the detached header while resizing columns.
    ScrollPosition? best;
    var bestDistance = double.infinity;
    for (final position in controller.positions) {
      final distance = (position.pixels - currentOffset).abs();
      if (distance < bestDistance) {
        best = position;
        bestDistance = distance;
      }
    }
    return best ?? controller.positions.first;
  }

  bool clampVerticalToExtents() {
    if (_verticalJumpSuppressed) {
      return false;
    }

    if (_verticalOffsetRestoreLocked) {
      // Layout-time clamps can be scheduled by row refreshes that happen inside
      // pointer cell actions. While a restore lock is active, the preserved
      // offset is the source of truth; otherwise a transient zero/small extent
      // can clamp the controller to the first row before the restore frame runs.
      final before = currentVerticalOffset;
      _keepLockedVerticalOffset();
      _restoreVerticalLockedOffset(_lockedVerticalOffsetDuringRestore);
      return (currentVerticalOffset - before).abs() >= 0.5;
    }

    return _clampToExtents(
      currentOffset: currentVerticalOffset,
      minScrollExtent: verticalMinScrollExtent,
      maxScrollExtent: verticalMaxScrollExtent,
      jumpTo: jumpVerticalTo,
    );
  }

  bool clampHorizontalToExtents() {
    return _clampToExtents(
      currentOffset: currentHorizontalOffset,
      minScrollExtent: horizontalMinScrollExtent,
      maxScrollExtent: horizontalMaxScrollExtent,
      jumpTo: jumpHorizontalTo,
    );
  }

  bool revealVerticalRange({
    required double leadingEdge,
    required double trailingEdge,
  }) {
    return _revealRange(
      currentOffset: currentVerticalOffset,
      minScrollExtent: verticalMinScrollExtent,
      maxScrollExtent: verticalMaxScrollExtent,
      viewportDimension: verticalViewportDimension(0.0),
      leadingEdge: leadingEdge,
      trailingEdge: trailingEdge,
      preferLeadingContext: false,
      jumpTo: jumpVerticalTo,
    );
  }

  bool revealHorizontalRange({
    required double leadingEdge,
    required double trailingEdge,
    bool preferLeadingContext = false,
  }) {
    return _revealRange(
      currentOffset: currentHorizontalOffset,
      minScrollExtent: horizontalMinScrollExtent,
      maxScrollExtent: horizontalMaxScrollExtent,
      viewportDimension: horizontalViewportDimension(0.0),
      leadingEdge: leadingEdge,
      trailingEdge: trailingEdge,
      preferLeadingContext: preferLeadingContext,
      jumpTo: jumpHorizontalTo,
    );
  }

  bool jumpVerticalToStart() {
    return jumpVerticalTo(verticalMinScrollExtent);
  }

  bool jumpHorizontalToStart() {
    return jumpHorizontalTo(horizontalMinScrollExtent);
  }

  bool jumpHorizontalToEnd() {
    return jumpHorizontalTo(horizontalMaxScrollExtent);
  }

  bool _clampToExtents({
    required double currentOffset,
    required double minScrollExtent,
    required double maxScrollExtent,
    required bool Function(double offset) jumpTo,
  }) {
    final nextOffset = currentOffset
        .clamp(minScrollExtent, maxScrollExtent)
        .toDouble();
    return jumpTo(nextOffset);
  }

  bool _revealRange({
    required double currentOffset,
    required double minScrollExtent,
    required double maxScrollExtent,
    required double viewportDimension,
    required double leadingEdge,
    required double trailingEdge,
    required bool preferLeadingContext,
    required bool Function(double offset) jumpTo,
  }) {
    if (viewportDimension <= 0) {
      return false;
    }

    final currentTrailingEdge = currentOffset + viewportDimension;

    var targetOffset = currentOffset;
    if (leadingEdge < currentOffset) {
      targetOffset = preferLeadingContext
          ? math.max(minScrollExtent, trailingEdge - viewportDimension)
          : leadingEdge;
    } else if (trailingEdge > currentTrailingEdge) {
      targetOffset = trailingEdge - viewportDimension;
    }

    final nextOffset = targetOffset
        .clamp(minScrollExtent, maxScrollExtent)
        .toDouble();
    if ((nextOffset - currentOffset).abs() < 0.5) {
      return false;
    }

    return jumpTo(nextOffset);
  }

  bool jumpVerticalTo(double offset) {
    if (_verticalOffsetRestoreLocked) {
      // Mouse/pointer viewport locks have priority over delayed vertical
      // navigation commands. A header filter/search refresh may schedule a
      // reset-to-top before a mouse cell-control click enters edit mode; if that reset
      // lands during the pointer lock, moving the physical controller to zero
      // produces a visible top-scroll flash before the restore frame runs.
      _restoreVerticalLockedOffset(_lockedVerticalOffsetDuringRestore);
      return false;
    }

    if (_verticalJumpSuppressed) {
      // Mouse cell-control actions must not cause any vertical controller
      // movement. Suppress stale scheduled reset/reveal jumps without issuing a
      // compensating jump back to the preserved offset; otherwise the scrollbar
      // wakes even when the final visual position is unchanged.
      _keepSuppressedVerticalOffset();
      return false;
    }

    return _jumpTo(
      controller: _verticalController,
      offset: offset,
      minScrollExtent: verticalMinScrollExtent,
      maxScrollExtent: verticalMaxScrollExtent,
      updateOffset: _setVerticalOffset,
    );
  }

  bool jumpHorizontalTo(double offset) {
    return _jumpTo(
      controller: _horizontalController,
      offset: offset,
      minScrollExtent: horizontalMinScrollExtent,
      maxScrollExtent: horizontalMaxScrollExtent,
      updateOffset: _setHorizontalOffset,
    );
  }

  bool scrollVerticalBy(double delta) {
    return _scrollBy(
      currentOffset: currentVerticalOffset,
      delta: delta,
      minScrollExtent: verticalMinScrollExtent,
      maxScrollExtent: verticalMaxScrollExtent,
      jumpTo: jumpVerticalTo,
    );
  }

  bool flingVertical(double velocity) {
    if (_verticalOffsetRestoreLocked ||
        _verticalJumpSuppressed ||
        velocity.abs() < 1.0) {
      return false;
    }

    final position = _firstAttachedPosition(
      _verticalController,
      currentOffset: currentVerticalOffset,
    );
    if (position == null) {
      return false;
    }

    final targetOffset = (position.pixels + (velocity * 0.18))
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    final distance = (targetOffset - position.pixels).abs();
    if (distance < 0.5) {
      return false;
    }

    final durationMs = (distance / velocity.abs() * 1800.0)
        .clamp(120.0, 420.0)
        .round();
    unawaited(
      position.animateTo(
        targetOffset,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.decelerate,
      ),
    );
    return true;
  }

  bool scrollHorizontalBy(double delta) {
    return _scrollBy(
      currentOffset: currentHorizontalOffset,
      delta: delta,
      minScrollExtent: horizontalMinScrollExtent,
      maxScrollExtent: horizontalMaxScrollExtent,
      jumpTo: jumpHorizontalTo,
    );
  }

  bool _scrollBy({
    required double currentOffset,
    required double delta,
    required double minScrollExtent,
    required double maxScrollExtent,
    required bool Function(double offset) jumpTo,
  }) {
    final nextOffset = (currentOffset + delta)
        .clamp(minScrollExtent, maxScrollExtent)
        .toDouble();
    if ((currentOffset - nextOffset).abs() < 0.5) {
      return false;
    }

    jumpTo(nextOffset);
    return true;
  }

  bool _jumpTo({
    required ScrollController controller,
    required double offset,
    required double minScrollExtent,
    required double maxScrollExtent,
    required void Function(double offset) updateOffset,
  }) {
    final nextOffset = offset
        .clamp(minScrollExtent, maxScrollExtent)
        .toDouble();
    final currentOffset = controller.hasClients
        ? _firstAttachedPosition(controller, currentOffset: offset)?.pixels ??
              nextOffset
        : nextOffset;
    if ((currentOffset - nextOffset).abs() < 0.5) {
      updateOffset(nextOffset);
      return false;
    }

    if (controller.hasClients) {
      controller.jumpTo(nextOffset);
    }
    updateOffset(nextOffset);
    return true;
  }

  void _setVerticalOffset(double offset) {
    if ((verticalOffset.value - offset).abs() < 0.5) {
      return;
    }
    verticalOffset.value = offset;
  }

  void _setHorizontalOffset(double offset) {
    if ((horizontalOffset.value - offset).abs() < 0.5) {
      return;
    }
    horizontalOffset.value = offset;
  }

  void _keepSuppressedVerticalOffset() {
    final offset = _suppressedVerticalJumpOffset;
    if (offset != null) {
      _setVerticalOffset(offset);
    }
  }

  void _keepLockedVerticalOffset() {
    final lockedOffset =
        _lockedVerticalOffsetDuringRestore ?? verticalOffset.value;
    final nextOffset = lockedOffset
        .clamp(
          verticalMinScrollExtent,
          math.max(verticalMaxScrollExtent, lockedOffset),
        )
        .toDouble();
    _lockedVerticalOffsetDuringRestore = nextOffset;
  }

  void _restoreVerticalLockedOffset(double? lockedOffset) {
    if (lockedOffset == null) {
      return;
    }

    final position = _firstAttachedPosition(
      _verticalController,
      currentOffset: lockedOffset,
    );
    final attachedMaxScrollExtent = position?.maxScrollExtent;
    final maxExtent = _verticalOffsetRestoreLocked
        ? math.max(verticalMaxScrollExtent, lockedOffset)
        : math.max(
            verticalMaxScrollExtent,
            attachedMaxScrollExtent ?? verticalMaxScrollExtent,
          );
    final nextOffset = lockedOffset
        .clamp(verticalMinScrollExtent, maxExtent)
        .toDouble();
    _setVerticalOffset(nextOffset);
    if (!_verticalController.hasClients) {
      return;
    }

    if (position == null || (position.pixels - nextOffset).abs() < 0.5) {
      return;
    }

    _verticalController.jumpTo(nextOffset);
  }

  void _keepLockedHorizontalOffset() {
    final lockedOffset = _lockedHorizontalOffset ?? horizontalOffset.value;
    final nextOffset = lockedOffset
        .clamp(
          horizontalMinScrollExtent,
          math.max(horizontalMaxScrollExtent, lockedOffset),
        )
        .toDouble();
    // Do not notify ValueNotifier listeners while handling scroll/layout
    // notifications during a horizontal lock. Those notifications can be
    // dispatched from layout/paint, and notifying here schedules a build during
    // the frame. The lock itself is the current visual origin until it ends.
    if (horizontalResizeLocked) {
      _lockedHorizontalOffsetDuringResize = nextOffset;
    } else if (_horizontalOffsetRestoreLocked) {
      _lockedHorizontalOffsetDuringRestore = nextOffset;
    }
  }

  void notifyHorizontalResizeVisualChange() {
    if (!horizontalResizeLocked) {
      return;
    }
    horizontalResizeTick.value++;
  }

  void restoreLockedHorizontalOffset() {
    if (!_horizontalOffsetLocked) {
      return;
    }

    _keepLockedHorizontalOffset();
    _restoreHorizontalLockedOffset(_lockedHorizontalOffset);
  }

  void restoreResizeLockedOffset() {
    if (!horizontalResizeLocked) {
      return;
    }
    restoreLockedHorizontalOffset();
  }

  void _restoreHorizontalLockedOffset(double? lockedOffset) {
    if (lockedOffset == null) {
      return;
    }

    final position = _firstAttachedPosition(
      _horizontalController,
      currentOffset: lockedOffset,
    );
    final attachedMaxScrollExtent = position?.maxScrollExtent;
    final maxExtent = _horizontalOffsetLocked
        ? math.max(horizontalMaxScrollExtent, lockedOffset)
        : math.max(
            horizontalMaxScrollExtent,
            attachedMaxScrollExtent ?? horizontalMaxScrollExtent,
          );
    final nextOffset = lockedOffset
        .clamp(horizontalMinScrollExtent, maxExtent)
        .toDouble();
    _setHorizontalOffset(nextOffset);
    if (!_horizontalController.hasClients) {
      return;
    }

    if (position == null || (position.pixels - nextOffset).abs() < 0.5) {
      return;
    }

    _horizontalController.jumpTo(nextOffset);
  }

  void _clampCachedVerticalOffsetToExtents() {
    // During a viewport-height change Flutter may keep the attached ListView
    // position temporarily outside the newly reported extents while a ballistic
    // correction animates it back into range. That raw position is the visual
    // source of truth for the detached indicator and pinned bands. Clamping the
    // notifier here creates a max -> live -> max ping-pong on every animation
    // frame and causes avoidable rebuild churn.
    final position = _firstAttachedPosition(
      _verticalController,
      currentOffset: currentVerticalOffset,
    );
    if (position != null) {
      _setVerticalOffset(position.pixels);
      return;
    }

    // Only clamp the cached value while the central ListView is detached. Once
    // a position attaches, its pixels value will become authoritative again.
    final nextOffset = currentVerticalOffset
        .clamp(verticalMinScrollExtent, verticalMaxScrollExtent)
        .toDouble();
    _setVerticalOffset(nextOffset);
  }

  void _clampCachedHorizontalOffsetToExtents() {
    if (_horizontalOffsetLocked) {
      _keepLockedHorizontalOffset();
      return;
    }

    final nextOffset = currentHorizontalOffset
        .clamp(horizontalMinScrollExtent, horizontalMaxScrollExtent)
        .toDouble();
    _setHorizontalOffset(nextOffset);
  }

  void restoreResizeLockedOffsetAfterLayout() {
    if (!horizontalResizeLocked) {
      return;
    }

    _horizontalResizeLayoutGeneration++;
    _scheduleResizeOffsetRestore();
  }

  void _scheduleResizeOffsetRestore() {
    if (_pendingResizeOffsetRestore) {
      return;
    }

    _pendingResizeOffsetRestore = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pendingResizeOffsetRestore = false;
      if (!horizontalResizeLocked) {
        return;
      }

      final targetGeneration = _horizontalResizeLayoutGeneration;
      final lockedOffset = _lockedHorizontalOffsetDuringResize;
      final position = _firstAttachedPosition(
        _horizontalController,
        currentOffset: lockedOffset ?? horizontalOffset.value,
      );
      if (lockedOffset != null && position != null) {
        // The Scrollable now exposes the real content extent. During a shrink
        // from the far-right edge Flutter may clamp its pixels to the new max.
        // Adopt that real, clamped origin for all detached horizontal bands so
        // header, body, filters, and summary remain on one projection.
        _horizontalMinScrollExtent = position.minScrollExtent;
        _horizontalMaxScrollExtent = position.maxScrollExtent;
        _horizontalViewportDimension = position.viewportDimension;
        final nextOffset = lockedOffset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
        _lockedHorizontalOffsetDuringResize = nextOffset;
        _setHorizontalOffset(nextOffset);
        if ((position.pixels - nextOffset).abs() >= 0.5) {
          _horizontalController.jumpTo(nextOffset);
        }
      }
      notifyHorizontalResizeVisualChange();
      _horizontalResizeRestoredGeneration = targetGeneration;

      if (_horizontalResizeRestoredGeneration <
          _horizontalResizeLayoutGeneration) {
        _scheduleResizeOffsetRestore();
      }
    });
  }

  void dispose() {
    _disposed = true;
    _verticalController.removeListener(_syncVerticalOffsetFromController);
    _horizontalController.removeListener(_syncHorizontalOffsetFromController);
    _verticalController.dispose();
    _horizontalController.dispose();
    verticalOffset.dispose();
    horizontalOffset.dispose();
    horizontalResizeTick.dispose();
    verticalViewportTick.dispose();
  }
}
