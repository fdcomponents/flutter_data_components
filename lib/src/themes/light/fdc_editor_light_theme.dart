// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../common/theme/fdc_editor_styles.dart';
import '../../common/theme/fdc_editor_theme_data.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';

const FdcEditorThemeData fdcEditorLightTheme = FdcEditorThemeData(
  input: FdcEditorInputStyle(
    fillColor: Color(0xFFFFFFFF),
    focusedFillColor: Color(0xFFFFFFFF),
    readOnlyFillColor: Color(0xFFF3F4F6),
    disabledFillColor: Color(0xFFE5E7EB),
    borderColor: Color(0xFFD1D5DB),
    focusedBorderColor: Color(0xFF2563EB),
    errorBorderColor: Color(0xFFDC2626),
    disabledBorderColor: Color(0xFFD1D5DB),
    readOnlyBorderColor: Color(0xFFD1D5DB),
    cursorColor: Color(0xFF2563EB),
  ),
  controls: FdcEditorControlsStyle(
    iconColor: Color(0xFF4B5563),
    disabledIconColor: Color(0xFF9CA3AF),
    activeIconColor: Color(0xFF2563EB),
    checkboxFillColor: Color(0x00000000),
    checkboxCheckColor: Color(0xFF000000),
    checkboxBorderColor: Color(0xFF9CA3AF),
    checkboxDisabledFillColor: Color(0xFFE5E7EB),
    checkboxDisabledCheckColor: Color(0xFF9CA3AF),
    checkboxDisabledBorderColor: Color(0xFF9CA3AF),
    switchThumbColor: Color(0xFF2563EB),
    switchTrackColor: Color(0x662563EB),
    switchDisabledThumbColor: Color(0xFF9CA3AF),
    switchDisabledTrackColor: Color(0xFFE5E7EB),
  ),
  comboPopup: FdcEditorComboPopupStyle(
    backgroundColor: Color(0xFFFFFFFF),
    surfaceTintColor: Colors.transparent,
    shadowColor: Color(0x33000000),
    borderColor: Color(0x00000000),
    highlightedItemColor: Color(0x1A2563EB),
    selectedIconColor: Color(0xFF111827),
    searchFillColor: Color(0xFFFFFFFF),
    searchIconColor: Color(0xFF4B5563),
    searchClearIconColor: Color(0xFF4B5563),
    searchBorderColor: Color(0xB3D1D5DB),
    searchFocusedBorderColor: Color(0xBF2563EB),
  ),
  counter: FdcCounterStyle(
    textStyle: TextStyle(color: Color(0xFF374151), fontSize: 11, height: 1),
  ),
);
