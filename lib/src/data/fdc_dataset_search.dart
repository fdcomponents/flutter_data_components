// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../common/format/fdc_date_format.dart';
import '../common/format/fdc_decimal_math.dart';
import '../common/format/fdc_format_settings.dart';
import 'fdc_data_type.dart';
import 'fdc_field_def.dart';
import 'fdc_field_name.dart';
import 'fdc_record.dart';
import 'types/fdc_decimal.dart';
import 'types/fdc_time.dart';

/// Converts a field value into searchable text for prepared dataset search.
///
/// Dataset search preparation calls this formatter for values of the field it is
/// registered against. Implementations should return deterministic user-facing text
/// suitable for the configured search semantics. The input may be `null`; exceptions
/// are not converted to non-matches and therefore propagate to the caller.
///
/// This typedef is part of the stable `fdc_ext.dart` extension seam.
typedef FdcSearchFieldTextFormatter = String Function(Object? value);

/// Global dataset search matching mode.
///
/// Search is a dataset view criterion that is AND-combined with active filters.
/// Modes define how the search text is matched across the configured fields.
enum FdcSearchMode {
  /// A whole phrase must be contained in at least one searchable field.
  phrase,

  /// Every token must be contained somewhere across the searchable fields.
  allWords,

  /// At least one token must be contained somewhere across the searchable
  /// fields.
  anyWord,

  /// A whole field value must exactly equal the phrase.
  exactPhrase,

  /// At least one searchable field must start with the phrase.
  startsWith,
}

/// Immutable dataset search state.
class FdcDataSetSearchState {
  /// Creates a [FdcDataSetSearchState].
  const FdcDataSetSearchState({
    this.text = '',
    this.mode = FdcSearchMode.phrase,
    this.caseSensitive = false,
    this.fields,
    this.fieldTextFormatters,
    this.fieldFormatSettings,
    this.formatSettings = const FdcFormatSettings(),
  });

  /// Text displayed to the user.
  final String text;

  /// Search matching strategy used for [text].
  final FdcSearchMode mode;

  /// Whether text comparisons preserve letter case.
  final bool caseSensitive;

  /// Field definitions included in this object.
  final Set<String>? fields;

  /// Search text formatters keyed by participating record field index.
  final Map<String, FdcSearchFieldTextFormatter>? fieldTextFormatters;

  /// Formatting overrides keyed by participating record field index.
  final Map<String, FdcFormatSettings>? fieldFormatSettings;

  /// Format settings applied to FDC controls.
  final FdcFormatSettings formatSettings;

  /// Whether [text] contains a non-whitespace search term.
  bool get isActive => text.trim().isNotEmpty;

  /// Returns a canonical search state with trimmed text and normalized field keys.
  ///
  /// An empty search term normalizes to the default inactive state.
  FdcDataSetSearchState normalized() {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const FdcDataSetSearchState();
    }
    return FdcDataSetSearchState(
      text: trimmed,
      mode: mode,
      caseSensitive: caseSensitive,
      fields: fields == null
          ? null
          : Set<String>.unmodifiable(
              fields!
                  .map(FdcFieldName.normalize)
                  .where((name) => name.isNotEmpty),
            ),
      fieldTextFormatters: fieldTextFormatters == null
          ? null
          : Map<String, FdcSearchFieldTextFormatter>.unmodifiable(
              <String, FdcSearchFieldTextFormatter>{
                for (final entry in fieldTextFormatters!.entries)
                  if (FdcFieldName.normalize(entry.key).isNotEmpty)
                    FdcFieldName.normalize(entry.key): entry.value,
              },
            ),
      fieldFormatSettings: fieldFormatSettings == null
          ? null
          : Map<String, FdcFormatSettings>.unmodifiable(
              <String, FdcFormatSettings>{
                for (final entry in fieldFormatSettings!.entries)
                  if (FdcFieldName.normalize(entry.key).isNotEmpty)
                    FdcFieldName.normalize(entry.key): entry.value,
              },
            ),
      formatSettings: formatSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FdcDataSetSearchState &&
        other.text == text &&
        other.mode == mode &&
        other.caseSensitive == caseSensitive &&
        _setsEqual(other.fields, fields) &&
        _formatterMapsEqual(other.fieldTextFormatters, fieldTextFormatters) &&
        _formatSettingsMapsEqual(
          other.fieldFormatSettings,
          fieldFormatSettings,
        ) &&
        other.formatSettings == formatSettings;
  }

  @override
  int get hashCode => Object.hash(
    text,
    mode,
    caseSensitive,
    _stringSetHash(fields),
    _formatterMapHash(fieldTextFormatters),
    _formatSettingsMapHash(fieldFormatSettings),
    formatSettings,
  );
}

/// Precomputed search matcher optimized for repeated record evaluation.
///
/// Instances are created by [prepareDataSetSearch] after field names, formatting
/// rules, search tokens, and typed fast-path terms have been normalized.
class FdcPreparedDataSetSearch {
  FdcPreparedDataSetSearch._({
    required this.mode,
    required this.caseSensitive,
    required this.formatSettings,
    required this.phrase,
    required this.tokens,
    required this.fieldIndexes,
    required this.fieldDataTypes,
    required this.fieldTextFormatters,
    required this.fieldFormatSettings,
    required List<int?> integerFastTokenValues,
    required int? integerFastPhraseValue,
    required List<FdcDecimal?> decimalFastTokenValues,
    required FdcDecimal? decimalFastPhraseValue,
    required this.structuredTimeOnly,
    required List<_FdcTimeFastTerm?> timeFastTokenTerms,
    required _FdcTimeFastTerm? timeFastPhraseTerm,
    required List<_FdcDateFastTerm?> dateFastTokenTerms,
    required _FdcDateFastTerm? dateFastPhraseTerm,
  }) : _integerFastTokenValues = integerFastTokenValues,
       _integerFastPhraseValue = integerFastPhraseValue,
       _decimalFastTokenValues = decimalFastTokenValues,
       _decimalFastPhraseValue = decimalFastPhraseValue,
       _timeFastTokenTerms = timeFastTokenTerms,
       _timeFastPhraseTerm = timeFastPhraseTerm,
       _dateFastTokenTerms = dateFastTokenTerms,
       _dateFastPhraseTerm = dateFastPhraseTerm;

  /// Search matching strategy used by this prepared matcher.
  final FdcSearchMode mode;

  /// Whether text comparisons preserve letter case.
  final bool caseSensitive;

  /// Format settings applied to FDC controls.
  final FdcFormatSettings formatSettings;

  /// Normalized phrase used by phrase-oriented search modes.
  final String phrase;

  /// Tokenized search terms used by word-oriented search modes.
  final List<String> tokens;

  /// Record field indexes participating in matching.
  final List<int> fieldIndexes;

  /// Data types keyed by participating record field index.
  final Map<int, FdcDataType> fieldDataTypes;

  /// Search text formatters keyed by participating record field index.
  final Map<int, FdcSearchFieldTextFormatter> fieldTextFormatters;

  /// Formatting overrides keyed by participating record field index.
  final Map<int, FdcFormatSettings> fieldFormatSettings;

  final List<int?> _integerFastTokenValues;
  final int? _integerFastPhraseValue;

  final List<FdcDecimal?> _decimalFastTokenValues;
  final FdcDecimal? _decimalFastPhraseValue;

  /// Whether the search can use the optimized structured time-only path.
  final bool structuredTimeOnly;
  final List<_FdcTimeFastTerm?> _timeFastTokenTerms;
  final _FdcTimeFastTerm? _timeFastPhraseTerm;

  final List<_FdcDateFastTerm?> _dateFastTokenTerms;
  final _FdcDateFastTerm? _dateFastPhraseTerm;

  /// Returns whether [record] satisfies this prepared search expression.
  bool matches(FdcRecord record) {
    final structuredTimeTerm = _structuredTimeSingleTerm;
    return structuredTimeTerm == null
        ? switch (mode) {
            FdcSearchMode.phrase => _matchesPhrase(record),
            FdcSearchMode.allWords => _matchesAllWords(record),
            FdcSearchMode.anyWord => _matchesAnyWord(record),
            FdcSearchMode.exactPhrase => _matchesExactPhrase(record),
            FdcSearchMode.startsWith => _matchesStartsWith(record),
          }
        : _matchesStructuredTimeOnly(record, structuredTimeTerm);
  }

  FdcFormatSettings _formatSettingsForField(int fieldIndex) {
    return fieldFormatSettings[fieldIndex] ?? formatSettings;
  }

  _FdcTimeFastTerm? get _structuredTimeSingleTerm {
    if (!structuredTimeOnly) {
      return null;
    }
    if (tokens.length > 1) {
      return null;
    }
    return _timeFastPhraseTerm;
  }

  bool _matchesStructuredTimeOnly(FdcRecord record, _FdcTimeFastTerm term) {
    for (final fieldIndex in fieldIndexes) {
      final value = _fieldValue(record, fieldIndex);

      if (_fieldSupportsTimeFastPath(fieldIndex)) {
        final timeTicks = _coerceTimeFastTicks(value);
        if (timeTicks == null) {
          continue;
        }
        if (term.matchesTicks(timeTicks)) {
          return true;
        }
        continue;
      }

      if (_structuredTimeTextFallbackMatches(value, fieldIndex)) {
        return true;
      }
    }
    return false;
  }

  bool _structuredTimeTextFallbackMatches(Object? value, int fieldIndex) {
    final dataType = fieldDataTypes[fieldIndex];
    if (!_isTextSearchableDataType(dataType ?? FdcDataType.object)) {
      return false;
    }
    final text = _fieldTextFromValue(value, fieldIndex);
    if (text.isEmpty) {
      return false;
    }
    switch (mode) {
      case FdcSearchMode.exactPhrase:
        return text == phrase;
      case FdcSearchMode.startsWith:
        return _textStartsWithSearchTerm(text, phrase);
      case FdcSearchMode.phrase:
      case FdcSearchMode.allWords:
      case FdcSearchMode.anyWord:
        return _textContainsSearchTerm(text, phrase);
    }
  }

  bool _textContainsSearchTerm(String text, String term) {
    if (!_isPlainNumericTextSearchTerm(term)) {
      return text.contains(term);
    }
    return _containsNumericTextSegment(text, term);
  }

  bool _textStartsWithSearchTerm(String text, String term) {
    if (!_isPlainNumericTextSearchTerm(term)) {
      return text.startsWith(term);
    }
    if (!text.startsWith(term)) {
      return false;
    }
    return _isNumericTextBoundary(text, term.length);
  }

  bool _isPlainNumericTextSearchTerm(String term) {
    return RegExp(r'^-?\d+$').hasMatch(term.trim());
  }

  bool _containsNumericTextSegment(String text, String term) {
    var start = 0;
    while (start <= text.length - term.length) {
      final index = text.indexOf(term, start);
      if (index < 0) {
        return false;
      }
      final before = index == 0 || _isNumericTextBoundary(text, index - 1);
      final after = _isNumericTextBoundary(text, index + term.length);
      if (before && after) {
        return true;
      }
      start = index + 1;
    }
    return false;
  }

  bool _isNumericTextBoundary(String text, int index) {
    if (index < 0 || index >= text.length) {
      return true;
    }
    return !_isAsciiDigitCodeUnit(text.codeUnitAt(index));
  }

  bool _matchesPhrase(FdcRecord record) {
    for (final fieldIndex in fieldIndexes) {
      final value = _fieldValue(record, fieldIndex);
      if (_fieldSupportsIntegerFastPath(fieldIndex)) {
        final integerMatch = _integerFastMatch(value, _integerFastPhraseValue);
        if (integerMatch == _FdcIntegerFastMatch.matched) {
          return true;
        }
        if (integerMatch == _FdcIntegerFastMatch.handled) {
          continue;
        }
      }
      if (_fieldSupportsDecimalFastPath(fieldIndex)) {
        final decimalMatch = _decimalFastMatch(value, _decimalFastPhraseValue);
        if (decimalMatch == _FdcDecimalFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (decimalMatch == _FdcDecimalFastMatch.handled ||
            decimalMatch == _FdcDecimalFastMatch.notHandled) {
          continue;
        }
      }
      if (_fieldSupportsTimeFastPath(fieldIndex)) {
        final timeMatch = _timeFastMatch(value, _timeFastPhraseTerm);
        if (timeMatch == _FdcTimeFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (timeMatch == _FdcTimeFastMatch.handled) {
          continue;
        }
      }
      if (_fieldSupportsDateFastPath(fieldIndex)) {
        final dateMatch = _dateFastMatch(
          value,
          fieldIndex,
          _dateFastPhraseTerm,
        );
        if (dateMatch == _FdcDateFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (dateMatch == _FdcDateFastMatch.handled) {
          continue;
        }
      }
      if (_shouldSkipTextFallback(fieldIndex)) {
        continue;
      }
      if (_textContainsSearchTerm(
        _fieldTextFromValue(value, fieldIndex),
        phrase,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _matchesAllWords(FdcRecord record) {
    if (tokens.isEmpty) {
      return true;
    }

    var matchedTokenMask = 0;
    final allTokensMask = (1 << tokens.length) - 1;

    for (final fieldIndex in fieldIndexes) {
      final value = _fieldValue(record, fieldIndex);
      String? text;

      for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
        final tokenMask = 1 << tokenIndex;
        if ((matchedTokenMask & tokenMask) != 0) {
          continue;
        }
        if (_fieldSupportsIntegerFastPath(fieldIndex)) {
          final integerMatch = _integerFastMatch(
            value,
            _integerFastTokenValueAt(tokenIndex),
          );
          if (integerMatch == _FdcIntegerFastMatch.matched) {
            matchedTokenMask |= tokenMask;
            if (matchedTokenMask == allTokensMask) {
              return true;
            }
            continue;
          }
          if (integerMatch == _FdcIntegerFastMatch.handled) {
            continue;
          }
        }
        if (_fieldSupportsDecimalFastPath(fieldIndex)) {
          final decimalMatch = _decimalFastMatch(
            value,
            _decimalFastTokenValueAt(tokenIndex),
          );
          if (decimalMatch == _FdcDecimalFastMatch.matched) {
            matchedTokenMask |= tokenMask;
            if (matchedTokenMask == allTokensMask) {
              return true;
            }
            continue;
          }
          if (_displayFormatterExactMatch(
            value,
            fieldIndex,
            tokens[tokenIndex],
          )) {
            matchedTokenMask |= tokenMask;
            if (matchedTokenMask == allTokensMask) {
              return true;
            }
          }
          if (decimalMatch == _FdcDecimalFastMatch.handled ||
              decimalMatch == _FdcDecimalFastMatch.notHandled) {
            continue;
          }
        }
        if (_fieldSupportsTimeFastPath(fieldIndex)) {
          final timeMatch = _timeFastMatch(
            value,
            _timeFastTokenTermAt(tokenIndex),
          );
          if (timeMatch == _FdcTimeFastMatch.matched) {
            matchedTokenMask |= tokenMask;
            if (matchedTokenMask == allTokensMask) {
              return true;
            }
            continue;
          }
          if (_displayFormatterExactMatch(
            value,
            fieldIndex,
            tokens[tokenIndex],
          )) {
            matchedTokenMask |= tokenMask;
            if (matchedTokenMask == allTokensMask) {
              return true;
            }
            continue;
          }
          if (timeMatch == _FdcTimeFastMatch.handled) {
            continue;
          }
        }
        if (_fieldSupportsDateFastPath(fieldIndex)) {
          final dateMatch = _dateFastMatch(
            value,
            fieldIndex,
            _dateFastTokenTermAt(tokenIndex),
          );
          if (dateMatch == _FdcDateFastMatch.matched) {
            matchedTokenMask |= tokenMask;
            if (matchedTokenMask == allTokensMask) {
              return true;
            }
            continue;
          }
          if (_displayFormatterExactMatch(
            value,
            fieldIndex,
            tokens[tokenIndex],
          )) {
            matchedTokenMask |= tokenMask;
            if (matchedTokenMask == allTokensMask) {
              return true;
            }
            continue;
          }
          if (dateMatch == _FdcDateFastMatch.handled) {
            continue;
          }
        }
        if (_shouldSkipTextFallback(fieldIndex)) {
          continue;
        }
        text ??= _fieldTextFromValue(value, fieldIndex);
        if (text.isEmpty) {
          continue;
        }
        if (_textContainsSearchTerm(text, tokens[tokenIndex])) {
          matchedTokenMask |= tokenMask;
          if (matchedTokenMask == allTokensMask) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _matchesAnyWord(FdcRecord record) {
    if (tokens.isEmpty) {
      return true;
    }

    for (final fieldIndex in fieldIndexes) {
      final value = _fieldValue(record, fieldIndex);
      String? text;
      for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
        if (_fieldSupportsIntegerFastPath(fieldIndex)) {
          final integerMatch = _integerFastMatch(
            value,
            _integerFastTokenValueAt(tokenIndex),
          );
          if (integerMatch == _FdcIntegerFastMatch.matched) {
            return true;
          }
          if (integerMatch == _FdcIntegerFastMatch.handled) {
            continue;
          }
        }
        if (_fieldSupportsDecimalFastPath(fieldIndex)) {
          final decimalMatch = _decimalFastMatch(
            value,
            _decimalFastTokenValueAt(tokenIndex),
          );
          if (decimalMatch == _FdcDecimalFastMatch.matched) {
            return true;
          }
          if (_displayFormatterExactMatch(
            value,
            fieldIndex,
            tokens[tokenIndex],
          )) {
            return true;
          }
          if (decimalMatch == _FdcDecimalFastMatch.handled ||
              decimalMatch == _FdcDecimalFastMatch.notHandled) {
            continue;
          }
        }
        if (_fieldSupportsTimeFastPath(fieldIndex)) {
          final timeMatch = _timeFastMatch(
            value,
            _timeFastTokenTermAt(tokenIndex),
          );
          if (timeMatch == _FdcTimeFastMatch.matched) {
            return true;
          }
          if (_displayFormatterExactMatch(
            value,
            fieldIndex,
            tokens[tokenIndex],
          )) {
            return true;
          }
          if (timeMatch == _FdcTimeFastMatch.handled) {
            continue;
          }
        }
        if (_fieldSupportsDateFastPath(fieldIndex)) {
          final dateMatch = _dateFastMatch(
            value,
            fieldIndex,
            _dateFastTokenTermAt(tokenIndex),
          );
          if (dateMatch == _FdcDateFastMatch.matched) {
            return true;
          }
          if (_displayFormatterExactMatch(
            value,
            fieldIndex,
            tokens[tokenIndex],
          )) {
            return true;
          }
          if (dateMatch == _FdcDateFastMatch.handled) {
            continue;
          }
        }
        if (_shouldSkipTextFallback(fieldIndex)) {
          continue;
        }
        text ??= _fieldTextFromValue(value, fieldIndex);
        if (text.isNotEmpty &&
            _textContainsSearchTerm(text, tokens[tokenIndex])) {
          return true;
        }
      }
    }

    return false;
  }

  bool _matchesExactPhrase(FdcRecord record) {
    for (final fieldIndex in fieldIndexes) {
      final value = _fieldValue(record, fieldIndex);
      if (_fieldSupportsIntegerFastPath(fieldIndex)) {
        final integerMatch = _integerFastMatch(value, _integerFastPhraseValue);
        if (integerMatch == _FdcIntegerFastMatch.matched) {
          return true;
        }
        if (integerMatch == _FdcIntegerFastMatch.handled) {
          continue;
        }
      }
      if (_fieldSupportsDecimalFastPath(fieldIndex)) {
        final decimalMatch = _decimalFastMatch(value, _decimalFastPhraseValue);
        if (decimalMatch == _FdcDecimalFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (decimalMatch == _FdcDecimalFastMatch.handled ||
            decimalMatch == _FdcDecimalFastMatch.notHandled) {
          continue;
        }
      }
      if (_fieldSupportsTimeFastPath(fieldIndex)) {
        final timeMatch = _timeFastMatch(value, _timeFastPhraseTerm);
        if (timeMatch == _FdcTimeFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (timeMatch == _FdcTimeFastMatch.handled) {
          continue;
        }
      }
      if (_fieldSupportsDateFastPath(fieldIndex)) {
        final dateMatch = _dateFastMatch(
          value,
          fieldIndex,
          _dateFastPhraseTerm,
        );
        if (dateMatch == _FdcDateFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (dateMatch == _FdcDateFastMatch.handled) {
          continue;
        }
      }
      if (_shouldSkipTextFallback(fieldIndex)) {
        continue;
      }
      if (_fieldTextFromValue(value, fieldIndex) == phrase) {
        return true;
      }
    }
    return false;
  }

  bool _matchesStartsWith(FdcRecord record) {
    for (final fieldIndex in fieldIndexes) {
      final value = _fieldValue(record, fieldIndex);
      if (_fieldSupportsIntegerFastPath(fieldIndex)) {
        final integerMatch = _integerFastMatch(value, _integerFastPhraseValue);
        if (integerMatch == _FdcIntegerFastMatch.matched) {
          return true;
        }
        if (integerMatch == _FdcIntegerFastMatch.handled) {
          continue;
        }
      }
      if (_fieldSupportsDecimalFastPath(fieldIndex)) {
        final decimalMatch = _decimalFastMatch(value, _decimalFastPhraseValue);
        if (decimalMatch == _FdcDecimalFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (decimalMatch == _FdcDecimalFastMatch.handled ||
            decimalMatch == _FdcDecimalFastMatch.notHandled) {
          continue;
        }
      }
      if (_fieldSupportsTimeFastPath(fieldIndex)) {
        final timeMatch = _timeFastMatch(value, _timeFastPhraseTerm);
        if (timeMatch == _FdcTimeFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (timeMatch == _FdcTimeFastMatch.handled) {
          continue;
        }
      }
      if (_fieldSupportsDateFastPath(fieldIndex)) {
        final dateMatch = _dateFastMatch(
          value,
          fieldIndex,
          _dateFastPhraseTerm,
        );
        if (dateMatch == _FdcDateFastMatch.matched) {
          return true;
        }
        if (_displayFormatterExactMatch(value, fieldIndex, phrase)) {
          return true;
        }
        if (dateMatch == _FdcDateFastMatch.handled) {
          continue;
        }
      }
      if (_shouldSkipTextFallback(fieldIndex)) {
        continue;
      }
      if (_textStartsWithSearchTerm(
        _fieldTextFromValue(value, fieldIndex),
        phrase,
      )) {
        return true;
      }
    }
    return false;
  }

  Object? _fieldValue(FdcRecord record, int fieldIndex) {
    return record.valueAt(fieldIndex);
  }

  String _fieldTextFromValue(Object? value, int fieldIndex) {
    final dataType = fieldDataTypes[fieldIndex] ?? FdcDataType.object;
    final displayFormatter = fieldTextFormatters[fieldIndex];
    final text = displayFormatter == null
        ? _valueToSearchText(
            value,
            dataType,
            _formatSettingsForField(fieldIndex),
          )
        : _displayAwareSearchText(
            value,
            dataType,
            displayFormatter,
            _formatSettingsForField(fieldIndex),
          );
    return caseSensitive ? text : text.toLowerCase();
  }

  bool _fieldSupportsTimeFastPath(int fieldIndex) {
    final dataType = fieldDataTypes[fieldIndex];
    return dataType == FdcDataType.time || dataType == FdcDataType.dateTime;
  }

  bool _fieldSupportsDateFastPath(int fieldIndex) {
    final dataType = fieldDataTypes[fieldIndex];
    return dataType == FdcDataType.date || dataType == FdcDataType.dateTime;
  }

  bool _shouldSkipTextFallback(int fieldIndex) {
    final dataType = fieldDataTypes[fieldIndex] ?? FdcDataType.object;
    return !_isTextSearchableDataType(dataType);
  }

  bool _fieldSupportsIntegerFastPath(int fieldIndex) {
    return fieldDataTypes[fieldIndex] == FdcDataType.integer;
  }

  bool _fieldSupportsDecimalFastPath(int fieldIndex) {
    return fieldDataTypes[fieldIndex] == FdcDataType.decimal;
  }

  /// Returns the compiled integer fast-path value for the ordered search token.
  ///
  /// This mirrors the local dataset search matcher and is used by backend
  /// adapters that need to translate the same search semantics to a native
  /// query language.
  int? integerFastTokenValueAt(int tokenIndex) =>
      _integerFastTokenValueAt(tokenIndex);

  /// Returns the compiled integer fast-path value for the whole search phrase.
  int? get integerFastPhraseValue => _integerFastPhraseValue;

  int? _integerFastTokenValueAt(int tokenIndex) {
    if (tokenIndex < 0 || tokenIndex >= _integerFastTokenValues.length) {
      return null;
    }
    return _integerFastTokenValues[tokenIndex];
  }

  _FdcIntegerFastMatch _integerFastMatch(Object? value, int? term) {
    if (term == null) {
      return _FdcIntegerFastMatch.notHandled;
    }

    final integerValue = _coerceIntegerFastValue(value);
    if (integerValue == null) {
      return _FdcIntegerFastMatch.notHandled;
    }

    if (integerValue == term) {
      return _FdcIntegerFastMatch.matched;
    }
    return _FdcIntegerFastMatch.handled;
  }

  int? _coerceIntegerFastValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite && value % 1 == 0) {
      return value.toInt();
    }
    return null;
  }

  /// Returns the compiled decimal fast-path value for the ordered search token.
  ///
  /// This mirrors the local dataset search matcher and is used by backend
  /// adapters that need to translate the same search semantics to a native
  /// query language.
  FdcDecimal? decimalFastTokenValueAt(int tokenIndex) =>
      _decimalFastTokenValueAt(tokenIndex);

  /// Returns the compiled decimal fast-path value for the whole search phrase.
  FdcDecimal? get decimalFastPhraseValue => _decimalFastPhraseValue;

  FdcDecimal? _decimalFastTokenValueAt(int tokenIndex) {
    if (tokenIndex < 0 || tokenIndex >= _decimalFastTokenValues.length) {
      return null;
    }
    return _decimalFastTokenValues[tokenIndex];
  }

  _FdcDecimalFastMatch _decimalFastMatch(Object? value, FdcDecimal? term) {
    if (term == null) {
      return _FdcDecimalFastMatch.notHandled;
    }

    final decimalValue = _coerceDecimalFastValue(value);
    if (decimalValue == null) {
      return _FdcDecimalFastMatch.notHandled;
    }

    if (decimalValue.compareTo(term) == 0) {
      return _FdcDecimalFastMatch.matched;
    }
    return _FdcDecimalFastMatch.handled;
  }

  FdcDecimal? _coerceDecimalFastValue(Object? value) {
    if (value is FdcDecimal) {
      return value;
    }
    if (value is int) {
      return FdcDecimal.fromScaled(BigInt.from(value), scale: 0);
    }
    if (value is num && value.isFinite) {
      return FdcDecimal.tryFromNum(value);
    }
    return null;
  }

  bool _displayFormatterExactMatch(
    Object? value,
    int fieldIndex,
    String searchTerm,
  ) {
    final formatter = fieldTextFormatters[fieldIndex];
    if (formatter == null) {
      return false;
    }

    final display = formatter(value).trim();
    if (display.isEmpty) {
      return false;
    }
    final normalizedDisplays = display
        .split('\n')
        .map((part) => caseSensitive ? part.trim() : part.trim().toLowerCase())
        .where((part) => part.isNotEmpty);
    return normalizedDisplays.any((part) => part == searchTerm);
  }

  _FdcTimeFastTerm? _timeFastTokenTermAt(int tokenIndex) {
    if (tokenIndex < 0 || tokenIndex >= _timeFastTokenTerms.length) {
      return null;
    }
    return _timeFastTokenTerms[tokenIndex];
  }

  _FdcDateFastTerm? _dateFastTokenTermAt(int tokenIndex) {
    if (tokenIndex < 0 || tokenIndex >= _dateFastTokenTerms.length) {
      return null;
    }
    return _dateFastTokenTerms[tokenIndex];
  }

  _FdcTimeFastMatch _timeFastMatch(Object? value, _FdcTimeFastTerm? term) {
    if (term == null) {
      return _FdcTimeFastMatch.notHandled;
    }

    final timeTicks = _coerceTimeFastTicks(value);
    if (timeTicks == null) {
      return _FdcTimeFastMatch.notHandled;
    }

    if (term.matchesTicks(timeTicks)) {
      return _FdcTimeFastMatch.matched;
    }
    return _FdcTimeFastMatch.handled;
  }

  int? _coerceTimeFastTicks(Object? value) {
    if (value is FdcTime) {
      return value.ticksSinceMidnight;
    }
    if (value is DateTime) {
      return value.hour * FdcTime.ticksPerHour +
          value.minute * FdcTime.ticksPerMinute +
          value.second * FdcTime.ticksPerSecond +
          value.millisecond * FdcTime.ticksPerMillisecond +
          value.microsecond * FdcTime.ticksPerMicrosecond;
    }
    return null;
  }

  _FdcDateFastMatch _dateFastMatch(
    Object? value,
    int fieldIndex,
    _FdcDateFastTerm? term,
  ) {
    if (term == null) {
      return _FdcDateFastMatch.notHandled;
    }

    final dataType = fieldDataTypes[fieldIndex];
    if (dataType == FdcDataType.date && term.hasTimeComponent) {
      return _FdcDateFastMatch.handled;
    }

    final dateValue = _coerceDateFastValue(value);
    if (dateValue == null) {
      return _FdcDateFastMatch.notHandled;
    }

    if (term.matches(dateValue)) {
      return _FdcDateFastMatch.matched;
    }
    return _FdcDateFastMatch.handled;
  }

  DateTime? _coerceDateFastValue(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Prepares normalized search state for efficient local dataset evaluation.
FdcPreparedDataSetSearch? prepareDataSetSearch({
  required FdcDataSetSearchState search,
  required List<FdcFieldDef> fields,
  required Map<String, int> fieldIndexByName,
  required FdcFormatSettings formatSettings,
}) {
  final normalized = search.normalized();
  if (!normalized.isActive) {
    return null;
  }

  final resolvedFields = _resolveSearchFieldIndexes(
    search: normalized,
    fields: fields,
    fieldIndexByName: fieldIndexByName,
    formatSettings: formatSettings,
  );

  final phrase = _normalizeSearchPhrase(
    normalized.text,
    caseSensitive: normalized.caseSensitive,
  );
  final shouldDeduplicateTokens = _searchModeUsesWordTokens(normalized.mode);
  final tokens = _orderSearchTokensForMatching(
    _normalizeSearchTokens(
      normalized.text,
      caseSensitive: normalized.caseSensitive,
      deduplicate: shouldDeduplicateTokens,
    ),
  );
  final rawTokens = _orderSearchTokensForMatching(
    _normalizeSearchTokens(
      normalized.text,
      caseSensitive: true,
      deduplicate: shouldDeduplicateTokens,
    ),
  );
  final integerFastTokenValues = _integerFastTerms(
    rawTokens,
    formatSettings: formatSettings,
  );
  final integerFastPhrase = _integerFastPhraseForSearch(
    phrase: normalized.text,
    formatSettings: formatSettings,
  );
  final decimalFastTokenValues = _decimalFastTerms(
    rawTokens,
    formatSettings: formatSettings,
  );
  final timeFastTokenTerms = _timeFastTerms(
    rawTokens,
    formatSettings: formatSettings,
  );
  final timeFastPhrase = _timeFastPhraseForSearch(
    phrase: normalized.text,
    formatSettings: formatSettings,
  );
  final dateFastTokenTerms = _dateFastTerms(
    rawTokens,
    formatSettings: formatSettings,
  );
  final dateFastPhrase = _dateFastPhraseForSearch(
    phrase: normalized.text,
    formatSettings: formatSettings,
  );
  return FdcPreparedDataSetSearch._(
    mode: normalized.mode,
    caseSensitive: normalized.caseSensitive,
    formatSettings: formatSettings,
    phrase: phrase,
    tokens: tokens,
    fieldIndexes: resolvedFields.fieldIndexes,
    fieldDataTypes: Map<int, FdcDataType>.unmodifiable(<int, FdcDataType>{
      for (var index = 0; index < fields.length; index++)
        index: fields[index].dataType,
    }),
    fieldTextFormatters: Map<int, FdcSearchFieldTextFormatter>.unmodifiable(
      <int, FdcSearchFieldTextFormatter>{
        for (var index = 0; index < fields.length; index++)
          if (normalized.fieldTextFormatters?[FdcFieldName.normalize(
                fields[index].name,
              )] !=
              null)
            index:
                normalized.fieldTextFormatters![FdcFieldName.normalize(
                  fields[index].name,
                )]!,
      },
    ),
    fieldFormatSettings:
        Map<int, FdcFormatSettings>.unmodifiable(<int, FdcFormatSettings>{
          for (var index = 0; index < fields.length; index++)
            if (normalized.fieldFormatSettings?[FdcFieldName.normalize(
                  fields[index].name,
                )] !=
                null)
              index:
                  normalized.fieldFormatSettings![FdcFieldName.normalize(
                    fields[index].name,
                  )]!,
        }),
    integerFastTokenValues: integerFastTokenValues,
    integerFastPhraseValue: _integerFastSearchTermForText(integerFastPhrase),
    decimalFastTokenValues: decimalFastTokenValues,
    decimalFastPhraseValue: _decimalFastSearchTermForText(
      _decimalFastPhraseForSearch(
        phrase: normalized.text,
        formatSettings: formatSettings,
      ),
    ),
    structuredTimeOnly: _structuredTimeOnlyForSearch(
      timeFastPhrase: timeFastPhrase,
      fieldIndexes: resolvedFields.fieldIndexes,
      fields: fields,
    ),
    timeFastTokenTerms: timeFastTokenTerms,
    timeFastPhraseTerm: _timeFastSearchTermForText(
      timeFastPhrase,
      formatSettings: formatSettings,
    ),
    dateFastTokenTerms: dateFastTokenTerms,
    dateFastPhraseTerm: _dateFastSearchTermForText(
      dateFastPhrase,
      formatSettings: formatSettings,
    ),
  );
}

enum _FdcIntegerFastMatch { notHandled, handled, matched }

enum _FdcDecimalFastMatch { notHandled, handled, matched }

enum _FdcTimeFastMatch { notHandled, handled, matched }

enum _FdcDateFastMatch { notHandled, handled, matched }

class _FdcTimeFastTerm {
  const _FdcTimeFastTerm({
    required this.startTicks,
    required this.endTicksExclusive,
  });

  final int startTicks;
  final int endTicksExclusive;

  bool matchesTicks(int ticksSinceMidnight) {
    return ticksSinceMidnight >= startTicks &&
        ticksSinceMidnight < endTicksExclusive;
  }
}

class _FdcDateFastTerm {
  const _FdcDateFastTerm({required this.parts, required this.isPrefix});

  final Map<String, String> parts;
  final bool isPrefix;

  bool get hasTimeComponent =>
      parts.containsKey('HH') ||
      parts.containsKey('mm') ||
      parts.containsKey('ss');

  bool matches(DateTime value) {
    for (final entry in parts.entries) {
      final actual = switch (entry.key) {
        'yyyy' => value.year.toString().padLeft(4, '0'),
        'MM' => value.month.toString().padLeft(2, '0'),
        'dd' => value.day.toString().padLeft(2, '0'),
        'HH' => value.hour.toString().padLeft(2, '0'),
        'mm' => value.minute.toString().padLeft(2, '0'),
        'ss' => value.second.toString().padLeft(2, '0'),
        _ => '',
      };
      final expected = entry.value;
      if (expected.length == _dateTokenLength(entry.key)) {
        if (actual != expected) {
          return false;
        }
      } else if (!actual.startsWith(expected)) {
        return false;
      }
    }
    return true;
  }
}

List<_FdcDateFastTerm?> _dateFastTerms(
  List<String> tokens, {
  required FdcFormatSettings formatSettings,
}) {
  return List<_FdcDateFastTerm?>.unmodifiable(
    tokens.map(
      (token) =>
          _dateFastSearchTermForText(token, formatSettings: formatSettings),
    ),
  );
}

_FdcDateFastTerm? _dateFastSearchTermForText(
  String? text, {
  required FdcFormatSettings formatSettings,
}) {
  if (text == null || text.trim().isEmpty) {
    return null;
  }
  final trimmed = text.trim();
  final dateTerm = _parseDateFastTerm(
    text: trimmed,
    pattern: formatSettings.dateFormat,
  );
  if (dateTerm != null && !dateTerm.isPrefix) {
    return dateTerm;
  }

  final dateTimeTerm = _parseDateFastTerm(
    text: trimmed,
    pattern: formatSettings.effectiveDateTimeFormat,
  );
  if (dateTimeTerm != null &&
      !dateTimeTerm.isPrefix &&
      dateTimeTerm.hasTimeComponent) {
    return dateTimeTerm;
  }
  return null;
}

_FdcDateFastTerm? _parseDateFastTerm({
  required String text,
  required String pattern,
}) {
  final parts = <String, String>{};
  var textIndex = 0;
  var patternIndex = 0;
  var consumedToken = false;
  var prefix = false;

  while (patternIndex < pattern.length) {
    if (textIndex >= text.length) {
      prefix = true;
      break;
    }

    final token = _dateTokenAt(pattern, patternIndex);
    if (token != null) {
      final maxLength = _dateTokenLength(token);
      final start = textIndex;
      while (textIndex < text.length &&
          textIndex - start < maxLength &&
          _isAsciiDigitCodeUnit(text.codeUnitAt(textIndex))) {
        textIndex++;
      }
      if (textIndex == start) {
        return null;
      }
      final value = text.substring(start, textIndex);
      parts[token] = value;
      consumedToken = true;
      if (value.length < maxLength) {
        prefix = true;
        break;
      }
      patternIndex += token.length;
      continue;
    }

    if (text.codeUnitAt(textIndex) != pattern.codeUnitAt(patternIndex)) {
      return null;
    }
    textIndex++;
    patternIndex++;
  }

  if (textIndex != text.length || !consumedToken) {
    return null;
  }
  if (!_dateFastPartsCouldBeValid(parts)) {
    return null;
  }

  return _FdcDateFastTerm(
    parts: Map<String, String>.unmodifiable(parts),
    isPrefix: prefix || _hasPartialDateFastToken(parts),
  );
}

bool _dateFastPartsCouldBeValid(Map<String, String> parts) {
  for (final entry in parts.entries) {
    final value = int.tryParse(entry.value);
    if (value == null) {
      return false;
    }
    final complete = entry.value.length == _dateTokenLength(entry.key);
    if (!complete) {
      continue;
    }
    if (entry.key == 'yyyy' && (value < 1 || value > 9999)) {
      return false;
    }
    if (entry.key == 'MM' && (value < 1 || value > 12)) {
      return false;
    }
    if (entry.key == 'dd' && (value < 1 || value > 31)) {
      return false;
    }
    if (entry.key == 'HH' && (value < 0 || value > 23)) {
      return false;
    }
    if ((entry.key == 'mm' || entry.key == 'ss') && (value < 0 || value > 59)) {
      return false;
    }
  }

  final year = _completeDatePart(parts, 'yyyy');
  final month = _completeDatePart(parts, 'MM');
  final day = _completeDatePart(parts, 'dd');
  if (year != null && month != null && day != null) {
    final value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      return false;
    }
  }
  return true;
}

int? _completeDatePart(Map<String, String> parts, String token) {
  final value = parts[token];
  if (value == null || value.length != _dateTokenLength(token)) {
    return null;
  }
  return int.tryParse(value);
}

bool _hasPartialDateFastToken(Map<String, String> parts) {
  for (final entry in parts.entries) {
    if (entry.value.length < _dateTokenLength(entry.key)) {
      return true;
    }
  }
  return false;
}

String? _dateFastPhraseForSearch({
  required String phrase,
  required FdcFormatSettings formatSettings,
}) {
  final normalized = phrase.trim();
  return _dateFastSearchTermForText(
            normalized,
            formatSettings: formatSettings,
          ) ==
          null
      ? null
      : normalized;
}

int _dateTokenLength(String token) => token == 'yyyy' ? 4 : 2;

String? _dateTokenAt(String value, int index) {
  for (final token in const ['yyyy', 'MM', 'dd', 'HH', 'mm', 'ss']) {
    if (value.startsWith(token, index)) {
      return token;
    }
  }
  return null;
}

bool _isAsciiDigitCodeUnit(int codeUnit) {
  return codeUnit >= 0x30 && codeUnit <= 0x39;
}

bool _structuredTimeOnlyForSearch({
  required String? timeFastPhrase,
  required List<int> fieldIndexes,
  required List<FdcFieldDef> fields,
}) {
  if (timeFastPhrase == null) {
    return false;
  }
  for (final fieldIndex in fieldIndexes) {
    final dataType = fields[fieldIndex].dataType;
    if (dataType == FdcDataType.time || dataType == FdcDataType.dateTime) {
      return true;
    }
  }
  return false;
}

List<_FdcTimeFastTerm?> _timeFastTerms(
  List<String> tokens, {
  required FdcFormatSettings formatSettings,
}) {
  return List<_FdcTimeFastTerm?>.unmodifiable(
    tokens.map(
      (token) =>
          _timeFastSearchTermForText(token, formatSettings: formatSettings),
    ),
  );
}

_FdcTimeFastTerm? _timeFastSearchTermForText(
  String? text, {
  required FdcFormatSettings formatSettings,
}) {
  if (text == null || text.isEmpty) {
    return null;
  }

  final trimmed = text.trim();
  final formatter = FdcDateFormat(formatSettings.timeFormat);
  final time = formatter.parseTime(trimmed);
  if (time == null || formatter.formatTime(time) != trimmed) {
    return null;
  }

  final precision = _timeSearchPrecisionForPattern(formatSettings.timeFormat);
  return _FdcTimeFastTerm(
    startTicks: time.ticksSinceMidnight,
    endTicksExclusive: _timeFastEndTicksExclusive(
      time.ticksSinceMidnight,
      precision.ticks,
    ),
  );
}

int _timeFastEndTicksExclusive(int startTicks, int precisionTicks) {
  final end = startTicks + (precisionTicks <= 1 ? 1 : precisionTicks);
  return end > FdcTime.ticksPerDay ? FdcTime.ticksPerDay : end;
}

class _FdcTimeSearchPrecision {
  const _FdcTimeSearchPrecision({required this.ticks});

  final int ticks;
}

_FdcTimeSearchPrecision _timeSearchPrecisionForPattern(String pattern) {
  if (pattern.contains('ss')) {
    return const _FdcTimeSearchPrecision(ticks: FdcTime.ticksPerSecond);
  }
  return const _FdcTimeSearchPrecision(ticks: FdcTime.ticksPerMinute);
}

String? _timeFastPhraseForSearch({
  required String phrase,
  required FdcFormatSettings formatSettings,
}) {
  final normalized = phrase.trim();
  return _timeFastSearchTermForText(
            normalized,
            formatSettings: formatSettings,
          ) ==
          null
      ? null
      : normalized;
}

List<int?> _integerFastTerms(
  List<String> tokens, {
  required FdcFormatSettings formatSettings,
}) {
  return List<int?>.unmodifiable(
    tokens.map((token) {
      final normalized = _normalizeIntegerSearchToken(
        token,
        formatSettings: formatSettings,
      );
      return _integerFastSearchTermForText(normalized);
    }),
  );
}

String? _integerFastPhraseForSearch({
  required String phrase,
  required FdcFormatSettings formatSettings,
}) {
  return _normalizeIntegerSearchToken(phrase, formatSettings: formatSettings);
}

int? _integerFastSearchTermForText(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }
  if (!_isCanonicalIntegerSearchText(text)) {
    return null;
  }
  return int.tryParse(text);
}

String? _normalizeIntegerSearchToken(
  String token, {
  required FdcFormatSettings formatSettings,
}) {
  final trimmed = token.trim();
  if (!_isFullIntegerSearchToken(trimmed, formatSettings: formatSettings)) {
    return null;
  }
  if (formatSettings.showThousandSeparator &&
      formatSettings.thousandSeparator.isNotEmpty) {
    return trimmed.replaceAll(formatSettings.thousandSeparator, '');
  }
  return trimmed;
}

List<FdcDecimal?> _decimalFastTerms(
  List<String> tokens, {
  required FdcFormatSettings formatSettings,
}) {
  return List<FdcDecimal?>.unmodifiable(
    tokens.map((token) {
      final normalized = _normalizeDecimalSearchToken(
        token,
        formatSettings: formatSettings,
      );
      return _decimalFastSearchTermForText(normalized);
    }),
  );
}

FdcDecimal? _decimalFastSearchTermForText(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }
  return FdcDecimal.tryParseNormalized(
    text,
    scale: _decimalSearchTextScale(text),
  );
}

int _decimalSearchTextScale(String normalizedText) {
  final dot = normalizedText.indexOf('.');
  return dot < 0 ? 0 : normalizedText.length - dot - 1;
}

String? _decimalFastPhraseForSearch({
  required String phrase,
  required FdcFormatSettings formatSettings,
}) {
  return _normalizeDecimalSearchToken(phrase, formatSettings: formatSettings);
}

String? _normalizeDecimalSearchToken(
  String token, {
  required FdcFormatSettings formatSettings,
}) {
  final trimmed = token.trim();
  if (trimmed.isEmpty || !_startsWithDecimalSearchChar(trimmed)) {
    return null;
  }
  if (trimmed.endsWith(',') || trimmed.endsWith('.')) {
    return null;
  }

  final decimalSeparator = formatSettings.decimalSeparator;
  final thousandSeparator = formatSettings.showThousandSeparator
      ? formatSettings.thousandSeparator
      : '';
  final hasThousandSeparator =
      thousandSeparator.isNotEmpty &&
      thousandSeparator != decimalSeparator &&
      trimmed.contains(thousandSeparator);
  final hasDecimalSeparator =
      decimalSeparator.isNotEmpty && trimmed.contains(decimalSeparator);

  if (!_usesConfiguredSeparators(
    trimmed,
    decimalSeparator: decimalSeparator,
    thousandSeparator: thousandSeparator,
  )) {
    return null;
  }

  if (hasDecimalSeparator) {
    if (!_isStrictConfiguredDecimalText(
      trimmed,
      decimalSeparator: decimalSeparator,
      thousandSeparator: thousandSeparator,
    )) {
      return null;
    }
    final configured = FdcDecimalMath.normalizeTextForParsing(
      trimmed,
      decimalSeparator: decimalSeparator,
      thousandSeparator: hasThousandSeparator ? thousandSeparator : null,
      allowCommaDecimalFallback: false,
    );
    return configured == null || configured.isEmpty ? null : configured;
  }

  if (hasThousandSeparator) {
    if (!_isStrictGroupedIntegerText(trimmed, thousandSeparator)) {
      return null;
    }
    final configured = FdcDecimalMath.normalizeTextForParsing(
      trimmed,
      decimalSeparator: decimalSeparator.isEmpty ? '.' : decimalSeparator,
      thousandSeparator: thousandSeparator,
      allowCommaDecimalFallback: false,
    );
    return configured == null || configured.isEmpty ? null : configured;
  }

  if (!RegExp(r'^-?\d+$').hasMatch(trimmed) ||
      !_isCanonicalIntegerSearchText(trimmed)) {
    return null;
  }
  return trimmed;
}

bool _usesConfiguredSeparators(
  String text, {
  required String decimalSeparator,
  required String thousandSeparator,
}) {
  for (var i = 0; i < text.length; i++) {
    final codeUnit = text.codeUnitAt(i);
    if (_isAsciiDigitCodeUnit(codeUnit) || (i == 0 && text[i] == '-')) {
      continue;
    }
    final char = text[i];
    if (decimalSeparator.isNotEmpty && char == decimalSeparator) {
      continue;
    }
    if (thousandSeparator.isNotEmpty && char == thousandSeparator) {
      continue;
    }
    return false;
  }
  return true;
}

bool _isStrictConfiguredDecimalText(
  String text, {
  required String decimalSeparator,
  required String thousandSeparator,
}) {
  if (decimalSeparator.isEmpty) {
    return false;
  }
  final decimalIndex = text.indexOf(decimalSeparator);
  if (decimalIndex < 0 || decimalIndex != text.lastIndexOf(decimalSeparator)) {
    return false;
  }

  final integerPart = text.substring(0, decimalIndex);
  final fractionPart = text.substring(decimalIndex + decimalSeparator.length);
  if (fractionPart.isEmpty || !RegExp(r'^\d+$').hasMatch(fractionPart)) {
    return false;
  }
  if (thousandSeparator.isNotEmpty &&
      thousandSeparator != decimalSeparator &&
      integerPart.contains(thousandSeparator)) {
    return _isStrictGroupedIntegerText(integerPart, thousandSeparator);
  }
  return RegExp(r'^-?\d+$').hasMatch(integerPart);
}

bool _isStrictGroupedIntegerText(String text, String separator) {
  if (separator.isEmpty) {
    return false;
  }
  final escaped = RegExp.escape(separator);
  return RegExp('^-?\\d{1,3}(?:$escaped\\d{3})+\$').hasMatch(text);
}

bool _hasDisplayDecimalSearchToken(String text) {
  final tokens = _tokenizeSearchText(text);
  if (tokens.isEmpty) {
    return _looksLikeDisplayDecimal(text);
  }
  return tokens.any(_looksLikeDisplayDecimal);
}

bool _looksLikeDisplayDecimal(String token) {
  final trimmed = token.trim();
  if (trimmed.isEmpty || trimmed.endsWith(',') || trimmed.endsWith('.')) {
    return false;
  }
  if (RegExp(r'^\d{2}\.\d{2}$').hasMatch(trimmed)) {
    return false;
  }
  return RegExp(
    r'^-?\d+(?:[.,]\d{3})*(?:[.,]\d+)?$|^-?\d+(?:[.,]\d+)?$',
  ).hasMatch(trimmed);
}

bool _hasDisplayDateSearchToken(String text) {
  return RegExp(r'(^|\s)\d{1,4}[-./]\d{1,2}[-./]\d{4}($|\s)').hasMatch(text);
}

bool _hasDisplayTimeSearchToken(String text) {
  return RegExp(r'(^|\s)\d{2}:\d{2}(?::\d{2})?($|\s)').hasMatch(text);
}

bool _startsWithDecimalSearchChar(String text) {
  if (text.isEmpty) {
    return false;
  }
  final first = text.codeUnitAt(0);
  if (_isAsciiDigitCodeUnit(first)) {
    return true;
  }
  return text.length > 1 &&
      text[0] == '-' &&
      _isAsciiDigitCodeUnit(text.codeUnitAt(1));
}

_FdcResolvedSearchFields _resolveSearchFieldIndexes({
  required FdcDataSetSearchState search,
  required List<FdcFieldDef> fields,
  required Map<String, int> fieldIndexByName,
  required FdcFormatSettings formatSettings,
}) {
  final textFieldIndexes = <int>[];
  final longTextFieldIndexes = <int>[];
  final integerFieldIndexes = <int>[];
  final decimalFieldIndexes = <int>[];
  final dateFieldIndexes = <int>[];
  final dateTimeFieldIndexes = <int>[];
  final timeFieldIndexes = <int>[];

  void addFieldIndex(int fieldIndex) {
    final field = fields[fieldIndex];
    final dataType = field.dataType;
    final normalizedFieldName = FdcFieldName.normalize(field.name);
    final fieldFormatSettings =
        search.fieldFormatSettings?[normalizedFieldName] ?? formatSettings;
    final fieldFormatter = search.fieldTextFormatters?[normalizedFieldName];
    final fieldTokenProfile = _FdcSearchTokenProfile.fromText(
      search.text,
      formatSettings: fieldFormatSettings,
    );

    if (dataType == FdcDataType.boolean || dataType == FdcDataType.guid) {
      return;
    }

    if (_isTextSearchableDataType(dataType)) {
      final target = _isLongTextSearchField(field.name)
          ? longTextFieldIndexes
          : textFieldIndexes;
      target.add(fieldIndex);
      return;
    }

    if (dataType == FdcDataType.integer) {
      if (fieldTokenProfile.hasIntegerToken) {
        integerFieldIndexes.add(fieldIndex);
      }
      return;
    }

    if (dataType == FdcDataType.decimal) {
      if (fieldTokenProfile.hasDecimalToken ||
          (fieldFormatter != null &&
              _hasDisplayDecimalSearchToken(search.text))) {
        decimalFieldIndexes.add(fieldIndex);
      }
      return;
    }

    if (dataType == FdcDataType.date) {
      if (fieldTokenProfile.hasDateToken ||
          (fieldFormatter != null && _hasDisplayDateSearchToken(search.text))) {
        dateFieldIndexes.add(fieldIndex);
      }
      return;
    }

    if (dataType == FdcDataType.dateTime) {
      if (fieldTokenProfile.hasDateTimeTokenOrPhrase ||
          fieldTokenProfile.hasDateToken ||
          fieldTokenProfile.hasTimeToken ||
          (fieldFormatter != null &&
              (_hasDisplayDateSearchToken(search.text) ||
                  _hasDisplayTimeSearchToken(search.text)))) {
        dateTimeFieldIndexes.add(fieldIndex);
      }
      return;
    }

    if (dataType == FdcDataType.time &&
        (fieldTokenProfile.hasTimeToken ||
            (fieldFormatter != null &&
                _hasDisplayTimeSearchToken(search.text)))) {
      timeFieldIndexes.add(fieldIndex);
    }
  }

  final explicitFields = search.fields;
  if (explicitFields != null) {
    for (final fieldName in explicitFields) {
      final fieldIndex = fieldIndexByName[FdcFieldName.normalize(fieldName)];
      if (fieldIndex != null) {
        addFieldIndex(fieldIndex);
      }
    }
  } else {
    for (var i = 0; i < fields.length; i++) {
      addFieldIndex(i);
    }
  }

  return _FdcResolvedSearchFields(
    fieldIndexes: List<int>.unmodifiable(<int>[
      ...integerFieldIndexes,
      ...decimalFieldIndexes,
      ...dateFieldIndexes,
      ...dateTimeFieldIndexes,
      ...timeFieldIndexes,
      ...textFieldIndexes,
      ...longTextFieldIndexes,
    ]),
  );
}

class _FdcSearchTokenProfile {
  const _FdcSearchTokenProfile({
    required this.hasIntegerToken,
    required this.hasDecimalToken,
    required this.hasDateToken,
    required this.hasDateTimeTokenOrPhrase,
    required this.hasTimeToken,
  });

  factory _FdcSearchTokenProfile.fromText(
    String text, {
    required FdcFormatSettings formatSettings,
  }) {
    final tokens = _tokenizeSearchText(text);
    var hasIntegerToken = false;
    var hasDecimalToken = false;
    var hasDateToken = false;
    var hasDateTimeToken = false;
    var hasTimeToken = false;

    for (final token in tokens) {
      if (_isFullIntegerSearchToken(token, formatSettings: formatSettings)) {
        hasIntegerToken = true;
      }
      if (_normalizeDecimalSearchToken(token, formatSettings: formatSettings) !=
          null) {
        hasDecimalToken = true;
      }
      final dateTerm = _dateFastSearchTermForText(
        token,
        formatSettings: formatSettings,
      );
      if (dateTerm != null) {
        if (dateTerm.hasTimeComponent) {
          hasDateTimeToken = true;
        } else {
          hasDateToken = true;
        }
      }
      if (_timeFastSearchTermForText(token, formatSettings: formatSettings) !=
          null) {
        hasTimeToken = true;
      }
    }

    final phraseDateTerm = _dateFastSearchTermForText(
      text,
      formatSettings: formatSettings,
    );
    final hasDateTimePhrase =
        phraseDateTerm != null && phraseDateTerm.hasTimeComponent;

    return _FdcSearchTokenProfile(
      hasIntegerToken: hasIntegerToken,
      hasDecimalToken: hasDecimalToken,
      hasDateToken: hasDateToken,
      hasDateTimeTokenOrPhrase: hasDateTimeToken || hasDateTimePhrase,
      hasTimeToken: hasTimeToken,
    );
  }

  final bool hasIntegerToken;
  final bool hasDecimalToken;
  final bool hasDateToken;
  final bool hasDateTimeTokenOrPhrase;
  final bool hasTimeToken;
}

class _FdcResolvedSearchFields {
  const _FdcResolvedSearchFields({required this.fieldIndexes});

  final List<int> fieldIndexes;
}

String _normalizeSearchPhrase(String text, {required bool caseSensitive}) {
  final trimmed = text.trim();
  return caseSensitive ? trimmed : trimmed.toLowerCase();
}

List<String> _normalizeSearchTokens(
  String text, {
  required bool caseSensitive,
  required bool deduplicate,
}) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final token in _tokenizeSearchText(text)) {
    final normalizedToken = caseSensitive ? token : token.toLowerCase();
    if (!deduplicate || seen.add(normalizedToken)) {
      normalized.add(normalizedToken);
    }
  }
  return List<String>.unmodifiable(normalized);
}

bool _searchModeUsesWordTokens(FdcSearchMode mode) {
  return mode == FdcSearchMode.allWords || mode == FdcSearchMode.anyWord;
}

List<String> _tokenizeSearchText(String text) {
  return text
      .trim()
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

List<String> _orderSearchTokensForMatching(List<String> tokens) {
  if (tokens.length < 2) {
    return tokens;
  }
  final indexed = <({int index, String token})>[
    for (var i = 0; i < tokens.length; i++) (index: i, token: tokens[i]),
  ];
  indexed.sort((left, right) {
    final lengthCompare = right.token.length.compareTo(left.token.length);
    if (lengthCompare != 0) {
      return lengthCompare;
    }
    return left.index.compareTo(right.index);
  });
  return List<String>.unmodifiable(indexed.map((entry) => entry.token));
}

bool _isTextSearchableDataType(FdcDataType dataType) {
  return dataType == FdcDataType.string;
}

String _valueToSearchText(
  Object? value,
  FdcDataType dataType,
  FdcFormatSettings formatSettings,
) {
  if (value == null) {
    return '';
  }

  return switch (dataType) {
    FdcDataType.date => _dateSearchText(value, includeTime: false),
    FdcDataType.dateTime => _dateSearchText(value, includeTime: true),
    FdcDataType.time => _timeSearchText(value),
    FdcDataType.integer => _integerSearchText(value, formatSettings),
    _ => value.toString(),
  };
}

String _displayAwareSearchText(
  Object? value,
  FdcDataType dataType,
  FdcSearchFieldTextFormatter formatter,
  FdcFormatSettings formatSettings,
) {
  final display = formatter(value);
  final fallback = _valueToSearchText(value, dataType, formatSettings);
  if (display.isEmpty) {
    return fallback;
  }
  if (fallback.isEmpty || fallback == display) {
    return display;
  }
  return '$display $fallback';
}

String _integerSearchText(Object value, FdcFormatSettings formatSettings) {
  final raw = value.toString();
  final parsed = value is int ? value : int.tryParse(raw);
  if (parsed == null ||
      !formatSettings.showThousandSeparator ||
      formatSettings.thousandSeparator.isEmpty) {
    return raw;
  }

  final grouped = _formatIntegerForSearch(
    parsed,
    formatSettings.thousandSeparator,
  );
  if (grouped == raw) {
    return raw;
  }
  return '$raw $grouped';
}

String _formatIntegerForSearch(int value, String thousandSeparator) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(thousandSeparator);
    }
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

String _dateSearchText(Object value, {required bool includeTime}) {
  final raw = value.toString();
  final dateTime = value is DateTime ? value : DateTime.tryParse(raw);
  if (dateTime == null) {
    return raw;
  }

  final yyyy = dateTime.year.toString().padLeft(4, '0');
  final mm = dateTime.month.toString().padLeft(2, '0');
  final dd = dateTime.day.toString().padLeft(2, '0');
  final m = dateTime.month.toString();
  final d = dateTime.day.toString();

  final dates = <String>{
    raw,
    '$yyyy-$mm-$dd',
    '$dd.$mm.$yyyy',
    '$d.$m.$yyyy',
    '$dd/$mm/$yyyy',
    '$d/$m/$yyyy',
    '$mm/$dd/$yyyy',
    '$m/$d/$yyyy',
  };

  if (!includeTime) {
    return dates.join(' ');
  }

  final timeText = _timeSearchText(dateTime);
  final values = <String>{...dates, timeText};
  for (final date in dates) {
    for (final time in _timeSearchVariants(FdcTime.fromDateTime(dateTime))) {
      values.add('$date $time');
    }
  }
  return values.join(' ');
}

String _timeSearchText(Object value) {
  final raw = value.toString();
  final time = switch (value) {
    final FdcTime value => value,
    final DateTime value => FdcTime.fromDateTime(value),
    _ => FdcTime.tryParse(raw),
  };
  if (time == null) {
    return raw;
  }

  return <String>{raw, ..._timeSearchVariants(time)}.join(' ');
}

Iterable<String> _timeSearchVariants(FdcTime time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final h = time.hour.toString();
  final mm = time.minute.toString().padLeft(2, '0');
  final ss = time.second.toString().padLeft(2, '0');

  return <String>{'$hh:$mm', '$h:$mm', '$hh:$mm:$ss', '$h:$mm:$ss'};
}

bool _isLongTextSearchField(String fieldName) {
  final normalized = FdcFieldName.normalize(fieldName);
  return normalized.contains('review') ||
      normalized.contains('description') ||
      normalized.contains('comment') ||
      normalized.contains('note') ||
      normalized.contains('memo') ||
      normalized.contains('remark');
}

bool _isCanonicalIntegerSearchText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  var digits = trimmed;
  if (digits.startsWith('-')) {
    digits = digits.substring(1);
  }
  if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) {
    return false;
  }
  return digits.length == 1 || !digits.startsWith('0');
}

bool _isFullIntegerSearchToken(
  String token, {
  required FdcFormatSettings formatSettings,
}) {
  final trimmed = token.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (formatSettings.decimalSeparator.isNotEmpty &&
      trimmed.contains(formatSettings.decimalSeparator)) {
    return false;
  }

  final thousandSeparator = formatSettings.showThousandSeparator
      ? formatSettings.thousandSeparator
      : '';
  if (!_usesConfiguredSeparators(
    trimmed,
    decimalSeparator: '',
    thousandSeparator: thousandSeparator,
  )) {
    return false;
  }

  if (thousandSeparator.isNotEmpty && trimmed.contains(thousandSeparator)) {
    return _isStrictGroupedIntegerText(trimmed, thousandSeparator);
  }

  return RegExp(r'^-?\d+$').hasMatch(trimmed);
}

bool _formatterMapsEqual(
  Map<String, FdcSearchFieldTextFormatter>? left,
  Map<String, FdcSearchFieldTextFormatter>? right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (!identical(right[entry.key], entry.value)) {
      return false;
    }
  }
  return true;
}

bool _formatSettingsMapsEqual(
  Map<String, FdcFormatSettings>? left,
  Map<String, FdcFormatSettings>? right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int? _stringSetHash(Set<String>? values) {
  if (values == null) {
    return null;
  }
  final sortedValues = values.toList()..sort();
  return Object.hashAll(sortedValues);
}

int? _formatterMapHash(Map<String, FdcSearchFieldTextFormatter>? values) {
  if (values == null) {
    return null;
  }
  final sortedKeys = values.keys.toList()..sort();
  return Object.hashAll(sortedKeys.map((key) => Object.hash(key, values[key])));
}

int? _formatSettingsMapHash(Map<String, FdcFormatSettings>? values) {
  if (values == null) {
    return null;
  }
  final sortedKeys = values.keys.toList()..sort();
  return Object.hashAll(sortedKeys.map((key) => Object.hash(key, values[key])));
}

bool _setsEqual(Set<String>? left, Set<String>? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (final value in left) {
    if (!right.contains(value)) {
      return false;
    }
  }
  return true;
}

/// Dataset-level global search API.
///
/// The dataset owns exactly one active global search state. This object is the
/// public entry point for applying and clearing that search state.
class FdcDataSetSearchApi {
  /// Creates a [FdcDataSetSearchApi].
  FdcDataSetSearchApi.internal({
    required FdcDataSetSearchState Function() readState,
    required Future<void> Function(
      String text, {
      FdcSearchMode mode,
      bool caseSensitive,
      Iterable<String>? fields,
      Map<String, FdcSearchFieldTextFormatter>? fieldTextFormatters,
      Map<String, FdcFormatSettings>? fieldFormatSettings,
      FdcFormatSettings? formatSettings,
    })
    applySearch,
    required Future<void> Function() clearSearch,
  }) : _readState = readState,
       _applySearch = applySearch,
       _clearSearch = clearSearch;

  /// Runs the function operation.
  final FdcDataSetSearchState Function() _readState;

  /// Runs the function operation.
  final Future<void> Function(
    String text, {
    FdcSearchMode mode,
    bool caseSensitive,
    Iterable<String>? fields,
    Map<String, FdcSearchFieldTextFormatter>? fieldTextFormatters,
    Map<String, FdcFormatSettings>? fieldFormatSettings,
    FdcFormatSettings? formatSettings,
  })
  _applySearch;

  /// Runs the function operation.
  final Future<void> Function() _clearSearch;

  /// Current global dataset search state.
  FdcDataSetSearchState get state => _readState();

  /// True when the dataset has an active global search criterion.
  bool get active => state.isActive;

  /// Whether no global search criterion is active.
  bool get isEmpty => !active;

  /// Whether a global search criterion is active.
  bool get isNotEmpty => active;

  /// Applies a global search to the dataset view.
  ///
  /// [fields] restricts the search scope; omitting it searches compatible
  /// dataset fields. Field-specific text formatters and format settings can be
  /// supplied for values whose searchable representation differs from storage.
  Future<void> apply(
    String text, {
    FdcSearchMode mode = FdcSearchMode.phrase,
    bool caseSensitive = false,
    Iterable<String>? fields,
    Map<String, FdcSearchFieldTextFormatter>? fieldTextFormatters,
    Map<String, FdcFormatSettings>? fieldFormatSettings,
    FdcFormatSettings? formatSettings,
  }) {
    return _applySearch(
      text,
      mode: mode,
      caseSensitive: caseSensitive,
      fields: fields,
      fieldTextFormatters: fieldTextFormatters,
      fieldFormatSettings: fieldFormatSettings,
      formatSettings: formatSettings,
    );
  }

  /// Clears the active global search and restores the unsearched query/view.
  Future<void> clear() {
    return _clearSearch();
  }
}
