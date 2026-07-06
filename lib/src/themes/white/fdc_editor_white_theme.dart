// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../common/theme/fdc_editor_styles.dart';
import '../../common/theme/fdc_editor_theme_data.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';

const FdcEditorThemeData fdcEditorWhiteTheme = FdcEditorThemeData(
  input: FdcEditorInputStyle.defaults,
  controls: FdcEditorControlsStyle(
    iconColor: Color(0xFF374151),
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
  comboPopup: FdcEditorComboPopupStyle.defaults,
  counter: FdcCounterStyle(
    textStyle: TextStyle(color: Color(0xFF374151), fontSize: 11, height: 1),
  ),
);
