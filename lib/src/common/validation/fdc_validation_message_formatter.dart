// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../data/fdc_data_errors.dart';
import '../../data/fdc_data_validation.dart';
import '../../data/fdc_dataset.dart';
import '../../i18n/fdc_translations.dart';

/// Internal formatter for user-facing validation/error text.
///
/// This class intentionally contains no UI code. It only turns structured
/// dataset validation/error state into display text that can be used by grids,
/// editors, dialogs, logs, or any other presentation layer.
abstract final class FdcValidationMessageFormatter {
  const FdcValidationMessageFormatter._();

  static String defaultTitle([
    FdcValidationTranslations translations = const FdcValidationTranslations(),
  ]) => translations.validationError;

  static String defaultMessage([
    FdcValidationTranslations translations = const FdcValidationTranslations(),
  ]) => translations.validationError;

  static String fromDataSet(
    FdcDataSet dataSet, {
    String? fallbackMessage,
    FdcValidationTranslations translations = const FdcValidationTranslations(),
  }) {
    if (dataSet.errors.message.isNotEmpty) {
      return dataSet.errors.message;
    }
    if (fallbackMessage != null && fallbackMessage.isNotEmpty) {
      return fallbackMessage;
    }
    return defaultMessage(translations);
  }

  static String fromDataSetErrors(
    Iterable<FdcDataSetError> errors, {
    String? fallbackMessage,
    FdcValidationTranslations translations = const FdcValidationTranslations(),
  }) {
    final text = errors
        .map((error) => error.message.trim())
        .where((message) => message.isNotEmpty)
        .join('\n');
    if (text.isNotEmpty) {
      return text;
    }
    if (fallbackMessage != null && fallbackMessage.isNotEmpty) {
      return fallbackMessage;
    }
    return defaultMessage(translations);
  }

  static String fromValidationErrors(
    Iterable<FdcValidationError> errors, {
    String? fallbackMessage,
    FdcValidationTranslations translations = const FdcValidationTranslations(),
  }) {
    final text = errors
        .map((error) => error.message.trim())
        .where((message) => message.isNotEmpty)
        .join('\n');
    if (text.isNotEmpty) {
      return text;
    }
    if (fallbackMessage != null && fallbackMessage.isNotEmpty) {
      return fallbackMessage;
    }
    return defaultMessage(translations);
  }

  static String fromObject(
    Object? error, {
    FdcDataSet? dataSet,
    String? fallbackMessage,
    FdcValidationTranslations translations = const FdcValidationTranslations(),
  }) {
    if (error is FdcDataSetValidationException) {
      return fromValidationErrors(
        error.errors,
        fallbackMessage: fallbackMessage ?? translations.validationFailed,
        translations: translations,
      );
    }

    if (error is FdcDataSetException) {
      if (error.errors.isNotEmpty) {
        return fromDataSetErrors(
          error.errors,
          fallbackMessage: error.message,
          translations: translations,
        );
      }
      if (error.message.isNotEmpty) {
        return error.message;
      }
    }

    if (dataSet != null && dataSet.errors.messages.isNotEmpty) {
      return fromDataSet(
        dataSet,
        fallbackMessage: fallbackMessage,
        translations: translations,
      );
    }

    if (error == null) {
      return fallbackMessage ?? defaultMessage(translations);
    }

    final text = _exceptionText(error).trim();
    if (text.isNotEmpty) {
      return text;
    }
    return fallbackMessage ?? defaultMessage(translations);
  }

  static String _exceptionText(Object error) {
    final text = error.toString();
    const exceptionPrefix = 'Exception: ';
    if (text.startsWith(exceptionPrefix)) {
      return text.substring(exceptionPrefix.length);
    }
    return text;
  }
}
