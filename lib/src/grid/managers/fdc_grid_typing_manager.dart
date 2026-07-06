// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/fdc_app.dart';
import '../columns/fdc_grid_columns.dart';
import '../format/fdc_field_value_codec.dart';
import '../models/fdc_column_identity.dart';

class FdcGridTypingManager {
  final RegExp _singleDigitRegex = RegExp(r'^\d$');
  final RegExp _singleDecimalCharRegex = RegExp(r'^[\d.,]$');
  final RegExp _singleDateCharRegex = RegExp(r'^[\d./:\-\s]$');

  bool canStartTyping(FdcGridColumn<dynamic> column, String text) {
    return switch (column.effectiveEditor) {
      FdcEditorType.text || FdcEditorType.memo => true,
      FdcEditorType.integer =>
        _singleDigitRegex.hasMatch(text) ||
            (column.allowNegative && text == '-'),
      FdcEditorType.decimal =>
        _singleDecimalCharRegex.hasMatch(text) ||
            (column.allowNegative && text == '-'),
      FdcEditorType.date ||
      FdcEditorType.dateTime ||
      FdcEditorType.time => _singleDateCharRegex.hasMatch(text),
      FdcEditorType.checkbox ||
      FdcEditorType.switcher ||
      FdcEditorType.badge ||
      FdcEditorType.progress ||
      FdcEditorType.custom ||
      FdcEditorType.action ||
      FdcEditorType.combo => false,
    };
  }

  Object? valueFromTypedText(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    String text, {
    FdcColumnIdentity? runtimeColumnId,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    return switch (column.effectiveEditor) {
      FdcEditorType.integer ||
      FdcEditorType.decimal ||
      FdcEditorType.date ||
      FdcEditorType.dateTime ||
      FdcEditorType.time => _codec(context).parseGridText(
        column,
        text,
        runtimeColumnId: runtimeColumnId,
        decimalScale: decimalScale,
        decimalPrecision: decimalPrecision,
      ),
      FdcEditorType.text || FdcEditorType.memo => text,
      FdcEditorType.checkbox ||
      FdcEditorType.switcher ||
      FdcEditorType.badge ||
      FdcEditorType.progress ||
      FdcEditorType.custom ||
      FdcEditorType.action ||
      FdcEditorType.combo => null,
    };
  }

  String formatTypedText(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    String text, {
    FdcColumnIdentity? runtimeColumnId,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    final formatter = _typedTextFormatter(
      context,
      column,
      runtimeColumnId: runtimeColumnId,
      decimalScale: decimalScale,
      decimalPrecision: decimalPrecision,
    );
    if (formatter == null) {
      return text;
    }

    return formatter
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        )
        .text;
  }

  bool isDateLikeEditor(FdcGridColumn<dynamic> column) {
    return column.effectiveEditor == FdcEditorType.date ||
        column.effectiveEditor == FdcEditorType.dateTime ||
        column.effectiveEditor == FdcEditorType.time;
  }

  TextInputFormatter? _typedTextFormatter(
    BuildContext context,
    FdcGridColumn<dynamic> column, {
    FdcColumnIdentity? runtimeColumnId,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    return _codec(context).typedTextFormatterForGridColumn(
      column,
      runtimeColumnId: runtimeColumnId,
      decimalScale: decimalScale,
      decimalPrecision: decimalPrecision,
    );
  }

  FdcFieldValueCodec _codec(BuildContext context) {
    return FdcFieldValueCodec(
      settings: FdcApp.formatsOf(context),
      translations: FdcApp.translationsOf(context),
    );
  }
}
