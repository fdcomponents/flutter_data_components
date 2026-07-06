// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../core/fdc_grid_core.dart';

class FdcGridRowIndicatorContent {
  const FdcGridRowIndicatorContent({
    required this.showRecordStatus,
    required this.showRowNumbers,
    required this.showRowSelect,
  });

  factory FdcGridRowIndicatorContent.fromOptions(
    FdcGridRowIndicatorOptions options,
  ) {
    return FdcGridRowIndicatorContent(
      showRecordStatus: options.showRecordStatus,
      showRowNumbers: options.showRowNumbers,
      showRowSelect: options.showRowSelect,
    );
  }

  final bool showRecordStatus;
  final bool showRowNumbers;
  final bool showRowSelect;

  bool get hasContent => showRecordStatus || showRowNumbers || showRowSelect;
}

class FdcGridRowIndicatorLayout {
  const FdcGridRowIndicatorLayout({
    required this.reserved,
    required this.width,
    required this.content,
  });

  static const none = FdcGridRowIndicatorLayout(
    reserved: false,
    width: 0,
    content: FdcGridRowIndicatorContent(
      showRecordStatus: false,
      showRowNumbers: false,
      showRowSelect: false,
    ),
  );

  // `reserved` means the grid needs the leading row indicator layout region. This
  // can be true even when the row indicator content itself is empty, for example
  // when the header filter row needs the leading area for alignment.
  final bool reserved;
  final double width;
  final FdcGridRowIndicatorContent content;

  bool get hasContent => content.hasContent;
  bool get isVisible => reserved;
}
