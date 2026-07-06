// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'fdc_text_value_codec.dart';

class FdcMemoValueCodec<T> extends FdcTextValueCodec<T> {
  const FdcMemoValueCodec({required super.config});

  @override
  TextInputType? keyboardType() => TextInputType.multiline;
}
