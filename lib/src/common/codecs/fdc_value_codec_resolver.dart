// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_date_time_value_codec.dart';
import 'fdc_date_value_codec.dart';
import 'fdc_decimal_value_codec.dart';
import 'fdc_integer_value_codec.dart';
import 'fdc_memo_value_codec.dart';
import 'fdc_text_value_codec.dart';
import 'fdc_time_value_codec.dart';
import 'fdc_value_codec_base.dart';
import 'fdc_value_codec_config.dart';
import 'fdc_value_codec_kind.dart';

class FdcValueCodecResolver {
  const FdcValueCodecResolver._();

  static FdcValueCodec<T> resolve<T>(FdcValueCodecConfig config) {
    return switch (config.kind) {
      FdcValueCodecKind.text => FdcTextValueCodec<T>(config: config),
      FdcValueCodecKind.memo => FdcMemoValueCodec<T>(config: config),
      FdcValueCodecKind.integer => FdcIntegerValueCodec<T>(config: config),
      FdcValueCodecKind.decimal => FdcDecimalValueCodec<T>(config: config),
      FdcValueCodecKind.date => FdcDateValueCodec<T>(config: config),
      FdcValueCodecKind.dateTime => FdcDateTimeValueCodec<T>(config: config),
      FdcValueCodecKind.time => FdcTimeValueCodec<T>(config: config),
    };
  }
}
