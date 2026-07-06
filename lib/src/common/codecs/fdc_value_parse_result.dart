// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

sealed class FdcValueParseResult<T> {
  const FdcValueParseResult();

  const factory FdcValueParseResult.success(
    T? value, {
    String? normalizedText,
  }) = FdcValueParseSuccess<T>;

  const factory FdcValueParseResult.error(String errorText) =
      FdcValueParseError<T>;

  T? get value;

  String? get normalizedText;

  String? get errorText;

  bool get isSuccess => this is FdcValueParseSuccess<T>;

  bool get isError => this is FdcValueParseError<T>;
}

final class FdcValueParseSuccess<T> extends FdcValueParseResult<T> {
  const FdcValueParseSuccess(this.value, {this.normalizedText});

  @override
  final T? value;

  @override
  final String? normalizedText;

  @override
  String? get errorText => null;
}

final class FdcValueParseError<T> extends FdcValueParseResult<T> {
  const FdcValueParseError(this.errorText);

  @override
  T? get value => null;

  @override
  String? get normalizedText => null;

  @override
  final String errorText;
}
