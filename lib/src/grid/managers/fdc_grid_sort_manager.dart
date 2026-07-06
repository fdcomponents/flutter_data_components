// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../models/fdc_column_identity.dart';

class FdcGridSortItem {
  const FdcGridSortItem({
    required this.runtimeColumnId,
    required this.ascending,
  });

  final FdcColumnIdentity runtimeColumnId;
  final bool ascending;
}

class FdcGridSortManager {
  final List<FdcGridSortItem> _items = <FdcGridSortItem>[];

  List<FdcGridSortItem> get items => List<FdcGridSortItem>.unmodifiable(_items);

  void clear() {
    _items.clear();
  }

  void setSingle({
    required FdcColumnIdentity runtimeColumnId,
    required bool ascending,
  }) {
    _items
      ..clear()
      ..add(
        FdcGridSortItem(runtimeColumnId: runtimeColumnId, ascending: ascending),
      );
  }

  void setAll(Iterable<FdcGridSortItem> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  void addOrUpdate({
    required FdcColumnIdentity runtimeColumnId,
    required bool ascending,
  }) {
    remove(runtimeColumnId);
    _items.add(
      FdcGridSortItem(runtimeColumnId: runtimeColumnId, ascending: ascending),
    );
  }

  void update({
    required FdcColumnIdentity runtimeColumnId,
    required bool ascending,
  }) {
    final index = _indexOf(runtimeColumnId);
    if (index == -1) {
      addOrUpdate(runtimeColumnId: runtimeColumnId, ascending: ascending);
      return;
    }
    _items[index] = FdcGridSortItem(
      runtimeColumnId: runtimeColumnId,
      ascending: ascending,
    );
  }

  void remove(FdcColumnIdentity runtimeColumnId) {
    _items.removeWhere((item) => item.runtimeColumnId == runtimeColumnId);
  }

  bool get hasSort => _items.isNotEmpty;

  int get count => _items.length;

  bool isSortedRuntimeColumn(FdcColumnIdentity? runtimeColumnId) {
    return runtimeColumnId != null && _indexOf(runtimeColumnId) != -1;
  }

  bool? ascendingForRuntimeColumn(FdcColumnIdentity? runtimeColumnId) {
    if (runtimeColumnId == null) {
      return null;
    }
    final index = _indexOf(runtimeColumnId);
    if (index == -1) {
      return null;
    }
    return _items[index].ascending;
  }

  int sortPositionForRuntimeColumn(FdcColumnIdentity? runtimeColumnId) {
    if (runtimeColumnId == null) {
      return 0;
    }
    final index = _indexOf(runtimeColumnId);
    return index == -1 ? 0 : index + 1;
  }

  bool nextAscendingForRuntimeColumn(FdcColumnIdentity? runtimeColumnId) {
    final ascending = ascendingForRuntimeColumn(runtimeColumnId);
    return ascending == null ? true : !ascending;
  }

  int _indexOf(FdcColumnIdentity runtimeColumnId) {
    return _items.indexWhere((item) => item.runtimeColumnId == runtimeColumnId);
  }
}
