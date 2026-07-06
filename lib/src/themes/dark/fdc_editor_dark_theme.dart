// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../common/theme/fdc_editor_styles.dart';
import '../../common/theme/fdc_editor_theme_data.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';

const FdcEditorThemeData fdcEditorDarkTheme = FdcEditorThemeData(
  input: FdcEditorInputStyle(
    fillColor: Color(0xFF111827),
    focusedFillColor: Color(0xFF111827),
    readOnlyFillColor: Color(0xFF1F2937),
    disabledFillColor: Color(0xFF374151),
    borderColor: Color(0xFF4B5563),
    focusedBorderColor: Color(0xFF60A5FA),
    errorBorderColor: Color(0xFFF87171),
    disabledBorderColor: Color(0xFF4B5563),
    readOnlyBorderColor: Color(0xFF4B5563),
    textStyle: TextStyle(color: Color(0xFFE5E7EB)),
    labelStyle: TextStyle(color: Color(0xFFD1D5DB)),
    floatingLabelStyle: TextStyle(color: Color(0xFF93C5FD)),
    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
    errorStyle: TextStyle(color: Color(0xFFF87171)),
    cursorColor: Color(0xFF60A5FA),
  ),
  controls: FdcEditorControlsStyle(
    iconColor: Color(0xFFD1D5DB),
    disabledIconColor: Color(0xFF6B7280),
    activeIconColor: Color(0xFF60A5FA),
    checkboxFillColor: Color(0xFF60A5FA),
    checkboxCheckColor: Color(0xFF111827),
    checkboxBorderColor: Color(0xFFD1D5DB),
    checkboxDisabledFillColor: Color(0xFF374151),
    checkboxDisabledCheckColor: Color(0xFF9CA3AF),
    checkboxDisabledBorderColor: Color(0xFF6B7280),
    switchThumbColor: Color(0xFF60A5FA),
    switchTrackColor: Color(0x664B9FFF),
    switchDisabledThumbColor: Color(0xFF6B7280),
    switchDisabledTrackColor: Color(0xFF374151),
    labelStyle: TextStyle(color: Color(0xFFE5E7EB)),
    disabledLabelStyle: TextStyle(color: Color(0xFF6B7280)),
  ),
  comboPopup: FdcEditorComboPopupStyle(
    backgroundColor: Color(0xFF1F2937),
    surfaceTintColor: Colors.transparent,
    shadowColor: Color(0x66000000),
    borderColor: Color(0xFF374151),
    highlightedItemColor: Color(0x334B9FFF),
    selectedIconColor: Color(0xFFE5E7EB),
    itemTextStyle: TextStyle(color: Color(0xFFE5E7EB)),
    emptyTextStyle: TextStyle(color: Color(0xFF9CA3AF)),
    searchFillColor: Color(0xFF111827),
    searchTextStyle: TextStyle(color: Color(0xFFE5E7EB)),
    searchHintStyle: TextStyle(color: Color(0xFF9CA3AF)),
    searchIconColor: Color(0xFFD1D5DB),
    searchClearIconColor: Color(0xFFD1D5DB),
    searchBorderColor: Color(0xFF4B5563),
    searchFocusedBorderColor: Color(0xFF60A5FA),
  ),
  counter: FdcCounterStyle(
    textStyle: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11, height: 1),
  ),
);
