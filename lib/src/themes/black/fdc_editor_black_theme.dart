// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../common/theme/fdc_editor_styles.dart';
import '../../common/theme/fdc_editor_theme_data.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';

const FdcEditorThemeData fdcEditorBlackTheme = FdcEditorThemeData(
  input: FdcEditorInputStyle(
    fillColor: Color(0xFF000000),
    focusedFillColor: Color(0xFF000000),
    readOnlyFillColor: Color(0xFF0A0A0A),
    disabledFillColor: Color(0xFF262626),
    borderColor: Color(0xFF333333),
    focusedBorderColor: Color(0xFF38BDF8),
    errorBorderColor: Color(0xFFF87171),
    disabledBorderColor: Color(0xFF333333),
    readOnlyBorderColor: Color(0xFF333333),
    textStyle: TextStyle(color: Color(0xFFEDEDED)),
    labelStyle: TextStyle(color: Color(0xFFE5E7EB)),
    floatingLabelStyle: TextStyle(color: Color(0xFF7DD3FC)),
    hintStyle: TextStyle(color: Color(0xFFA3A3A3)),
    errorStyle: TextStyle(color: Color(0xFFF87171)),
    cursorColor: Color(0xFF38BDF8),
  ),
  controls: FdcEditorControlsStyle(
    iconColor: Color(0xFFE5E7EB),
    disabledIconColor: Color(0xFF6B7280),
    activeIconColor: Color(0xFF38BDF8),
    checkboxFillColor: Color(0xFF38BDF8),
    checkboxCheckColor: Color(0xFF000000),
    checkboxBorderColor: Color(0xFFE5E7EB),
    checkboxDisabledFillColor: Color(0xFF262626),
    checkboxDisabledCheckColor: Color(0xFF737373),
    checkboxDisabledBorderColor: Color(0xFF525252),
    switchThumbColor: Color(0xFF38BDF8),
    switchTrackColor: Color(0x6638BDF8),
    switchDisabledThumbColor: Color(0xFF737373),
    switchDisabledTrackColor: Color(0xFF262626),
    labelStyle: TextStyle(color: Color(0xFFEDEDED)),
    disabledLabelStyle: TextStyle(color: Color(0xFF737373)),
  ),
  comboPopup: FdcEditorComboPopupStyle(
    backgroundColor: Color(0xFF0A0A0A),
    surfaceTintColor: Colors.transparent,
    shadowColor: Color(0x80000000),
    borderColor: Color(0xFF2A2A2A),
    highlightedItemColor: Color(0x3338BDF8),
    selectedIconColor: Color(0xFFEDEDED),
    itemTextStyle: TextStyle(color: Color(0xFFEDEDED)),
    emptyTextStyle: TextStyle(color: Color(0xFFA3A3A3)),
    searchFillColor: Color(0xFF000000),
    searchTextStyle: TextStyle(color: Color(0xFFEDEDED)),
    searchHintStyle: TextStyle(color: Color(0xFFA3A3A3)),
    searchIconColor: Color(0xFFE5E7EB),
    searchClearIconColor: Color(0xFFE5E7EB),
    searchBorderColor: Color(0xFF333333),
    searchFocusedBorderColor: Color(0xFF38BDF8),
  ),
  counter: FdcCounterStyle(
    textStyle: TextStyle(color: Color(0xFFEDEDED), fontSize: 11, height: 1),
  ),
);
