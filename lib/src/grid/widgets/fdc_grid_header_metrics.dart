// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FdcGridHeaderMetrics {
  const FdcGridHeaderMetrics._();

  static const double minWidthForSortIcon = 48;

  static const double labelStartPadding = 4;
  static const double menuGap = 6;
  static const double menuEndPadding = 0;
  static const double menuButtonWidth = 28;
  static const double headerMenuReservedWidth =
      menuGap + menuButtonWidth + menuEndPadding;
  static const double filterRowTopPadding = 8;
  static const double filterRowBottomPadding = 8;
  static const double filterFieldLabelTopInset = 6;
  static const double filterFieldLabelLeft = 9;
  static const double filterFieldLabelFontSize = 12;
  static const double filterFieldLabelHorizontalPadding = 5;
  static const double filterFieldBorderRadius = 4;
  static const double filterFieldHorizontalPadding = 8;
  static const double filterDropdownIconSize = 18;
  static const double filterClearButtonWidth = 22;
  static const double filterClearButtonGap = 4;
  static const double filterClearButtonVerticalOffset = 1;
  static const double filterClearIconSize = 12;
  static const double filterInlineClearMinimumWidth = 72;
  static const double rowIndicatorLabelGap = 4;
  static const double rowIndicatorStatusIconSize = 16;
  static const double rowIndicatorCheckboxSize = 24;
  static const double rowIndicatorControlSlotWidth = 44;
  static const double rowIndicatorStatusWidth = rowIndicatorControlSlotWidth;
  static const double rowIndicatorCompositeStatusWidth = 24;
  static const double rowIndicatorCompositeStatusIconOffset = 2;
  static const double rowIndicatorSelectWidth =
      rowIndicatorControlSlotWidth - 12;
  static const double rowIndicatorNumberMinWidth = rowIndicatorControlSlotWidth;
  static const double rowIndicatorNumberDigitWidth = 9;
  static const double rowIndicatorNumberHorizontalPadding = 0;
  static const double rowIndicatorMainMenuMinWidth = menuButtonWidth;
  static const double headerControlHeight = 28;
  static const double filterFieldControlHeight = 34;
  static double get filterRowHeight =>
      filterRowHeightFor(filterFieldControlHeight);

  static double filterRowHeightFor(double filterControlHeight) =>
      filterRowTopPadding +
      filterFieldLabelTopInset +
      filterControlHeight +
      filterRowBottomPadding +
      2;
  static const double menuIconSize = 15;
  static const double filterIconSize = 15;
  static const double headerIconHitTestSize = 28;
  static const double headerIconInkRadius = headerIconHitTestSize / 2;
  static const double verticalSeparatorInset = 8;
  static const double verticalSeparatorWidth = 1;

  static const double columnDragFeedbackWidth = 180;
  static const double columnDragFeedbackHeight = 36;
  static const Offset columnDragFeedbackOffset = Offset(12, -46);

  static const double sortIconGap = 3;
  static const double sortIconSize = 13;
  static const double sortPositionWidth = 10;
  static const double sortPositionSuperscriptGap = 2;
  static const double sortPositionSuperscriptLeft =
      sortIconSize + sortPositionSuperscriptGap;
  static const double sortIndicatorWidth =
      sortPositionSuperscriptLeft + sortPositionWidth;
  static const double sortAffordanceMaxWidth = sortIconGap + sortIndicatorWidth;
  static const double sortPositionFontSize = 9.5;
  static const double sortPositionSuperscriptTop = 0;

  static const Duration sortFadeInDuration = Duration(milliseconds: 140);
  static const Duration sortFadeOutDuration = Duration(milliseconds: 110);

  static bool hasRoomForHeaderMenu(double width) {
    return width >= headerMenuReservedWidth;
  }

  static bool hasRoomForSortIcon(double width) {
    return width >= minWidthForSortIcon;
  }

  static bool hasRoomForSortAffordance(double width) {
    return width >= sortAffordanceMaxWidth;
  }

  static double rowIndicatorStatusSlotWidth({
    required bool showRecordStatus,
    required bool showRowSelect,
    required bool showRowNumbers,
  }) {
    if (!showRecordStatus) {
      return 0.0;
    }
    return showRowSelect || showRowNumbers
        ? rowIndicatorCompositeStatusWidth
        : rowIndicatorStatusWidth;
  }

  static double rowIndicatorSelectLeadingWidth({
    required bool showRecordStatus,
    required bool showRowSelect,
    required bool showRowNumbers,
  }) {
    return rowIndicatorStatusSlotWidth(
      showRecordStatus: showRecordStatus,
      showRowSelect: showRowSelect,
      showRowNumbers: showRowNumbers,
    );
  }

  static double rowIndicatorNumberLeadingWidth({
    required bool showRecordStatus,
    required bool showRowSelect,
    required bool showRowNumbers,
  }) {
    if (!showRowNumbers) {
      return 0.0;
    }

    var width = 0.0;
    width += rowIndicatorStatusSlotWidth(
      showRecordStatus: showRecordStatus,
      showRowSelect: showRowSelect,
      showRowNumbers: showRowNumbers,
    );
    if (showRowSelect) {
      width += rowIndicatorSelectWidth;
    }
    return width;
  }

  static double rowIndicatorNumberWidth(int rowCount) {
    return math.max(
      rowIndicatorNumberMinWidth,
      rowCount.toString().length * rowIndicatorNumberDigitWidth +
          rowIndicatorNumberHorizontalPadding,
    );
  }

  static bool hasRoomForRowIndicatorSelect(double width) {
    return width >= rowIndicatorSelectWidth;
  }

  static bool hasRoomForRowIndicatorLabel(double width) {
    return width >= rowIndicatorLabelGap;
  }

  static bool hasRoomForRowIndicatorMainMenu(double width) {
    return width >= rowIndicatorMainMenuMinWidth;
  }
}
