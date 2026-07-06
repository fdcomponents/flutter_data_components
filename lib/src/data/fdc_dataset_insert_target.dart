// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

/// Describes where a new dataset record should be physically inserted.
///
/// This class intentionally lives in its own file and is imported normally,
/// instead of being a `part` of `fdc_dataset.dart`. It keeps the insert/append
/// positioning policy separate from the dataset lifecycle code, while the
/// dataset itself remains responsible for events, state changes and buffers.
final class FdcDataSetInsertTarget {
  /// Adds the new record after the last raw record.
  const FdcDataSetInsertTarget.append()
    : _kind = _FdcDataSetInsertTargetKind.append;

  /// Inserts the new record before the current active record.
  ///
  /// If the dataset has no current record, this falls back to append semantics.
  const FdcDataSetInsertTarget.insertBeforeCurrent()
    : _kind = _FdcDataSetInsertTargetKind.insertBeforeCurrent;

  final _FdcDataSetInsertTargetKind _kind;

  /// True when the public operation was append().
  ///
  /// append() has a visual policy in FdcDataSet: while the new row is still
  /// unposted, it is kept at the bottom of the active view even if a sort is
  /// active.
  bool get isAppend => _kind == _FdcDataSetInsertTargetKind.append;

  /// True when the public operation was insert().
  ///
  /// insert() has a visual policy in FdcDataSet: while the new row is still
  /// unposted, it is kept immediately before the record that was current when
  /// insert() was called, even if a sort is active.
  bool get isInsertBeforeCurrent =>
      _kind == _FdcDataSetInsertTargetKind.insertBeforeCurrent;

  int resolveRawIndex({
    required int currentIndex,
    required int recordCount,
    required int Function(int activeIndex) rawIndexForActiveIndex,
  }) {
    switch (_kind) {
      case _FdcDataSetInsertTargetKind.append:
        return recordCount;
      case _FdcDataSetInsertTargetKind.insertBeforeCurrent:
        if (currentIndex < 0) {
          return recordCount;
        }
        return rawIndexForActiveIndex(currentIndex);
    }
  }
}

enum _FdcDataSetInsertTargetKind { append, insertBeforeCurrent }
