// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_date_like_value_codec.dart';
import 'fdc_value_parse_result.dart';

class FdcDateValueCodec<T> extends FdcDateLikeValueCodec<T> {
  FdcDateValueCodec({required super.config});

  @override
  Object? parseDateText(String text) {
    return dateFormatter().parseDate(text);
  }

  @override
  FdcValueParseResult<T> parseForCommit(String text) {
    if (text.trim().isEmpty) {
      return const FdcValueParseResult.success(null);
    }
    final resolvedText = completeMissingTrailingYear(text, DateTime.now().year);
    final parsedValue = parseDateText(resolvedText);
    if (parsedValue == null) {
      return const FdcValueParseResult.success(null);
    }
    return FdcValueParseResult<T>.success(
      parsedValue as T?,
      normalizedText: resolvedText == text ? null : resolvedText,
    );
  }

  @override
  String formatValue(Object? value, {bool forEditing = false}) {
    if (value == null) {
      return '';
    }
    if (value is DateTime) {
      return dateFormatter().formatDate(value);
    }
    return value.toString();
  }

  @override
  String dateFormatPattern() {
    return config.formatSettings.dateFormat;
  }
}
