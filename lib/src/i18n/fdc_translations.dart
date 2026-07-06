// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:ui' show Locale;

import '../common/fdc_aggregate.dart';

part 'translations/fdc_translations_en_us.dart';
part 'translations/fdc_translations_hr_hr.dart';
part 'translations/fdc_translations_it_it.dart';
part 'translations/fdc_translations_de_de.dart';
part 'translations/fdc_translations_fr_fr.dart';
part 'translations/fdc_translations_es_es.dart';

/// Resolves FDC translations for a Flutter [Locale].
abstract interface class FdcTranslationResolver {
  /// Resolves translations for [locale].
  FdcTranslations resolve(Locale locale);
}

/// Default built-in FDC translation resolver.
///
/// Resolves built-in FDC translation locales by language code and falls back
/// to [FdcTranslations.enUs] for all other locales.
class FdcDefaultTranslationResolver implements FdcTranslationResolver {
  /// Creates the default FDC translation resolver.
  const FdcDefaultTranslationResolver();

  @override
  FdcTranslations resolve(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    switch (languageCode) {
      case 'hr':
        return FdcTranslations.hrHr();
      case 'it':
        return FdcTranslations.itIt();
      case 'de':
        return FdcTranslations.deDe();
      case 'fr':
        return FdcTranslations.frFr();
      case 'es':
        return FdcTranslations.esEs();
    }
    return FdcTranslations.enUs();
  }
}

/// User-facing FDC text resources.
///
/// The object is intentionally typed instead of map-based so component code and
/// application overrides remain discoverable, refactor-safe and testable.
class FdcTranslations {
  /// Creates a custom FDC translation set.
  const FdcTranslations({
    this.common = const FdcCommonTranslations(),
    this.dialogs = const FdcDialogTranslations(),
    this.grid = const FdcGridTranslations(),
    this.validation = const FdcValidationTranslations(),
  });

  /// English (United States) FDC translations.
  factory FdcTranslations.enUs() => _fdcTranslationsEnUs();

  /// Croatian (Croatia) FDC translations.
  factory FdcTranslations.hrHr() => _fdcTranslationsHrHr();

  /// Italian (Italy) FDC translations.
  factory FdcTranslations.itIt() => _fdcTranslationsItIt();

  /// German (Germany) FDC translations.
  factory FdcTranslations.deDe() => _fdcTranslationsDeDe();

  /// French (France) FDC translations.
  factory FdcTranslations.frFr() => _fdcTranslationsFrFr();

  /// Spanish (Spain) FDC translations.
  factory FdcTranslations.esEs() => _fdcTranslationsEsEs();

  /// Common component text resources.
  final FdcCommonTranslations common;

  /// Dialog text resources.
  final FdcDialogTranslations dialogs;

  /// Grid text resources.
  final FdcGridTranslations grid;

  /// Validation text resources.
  final FdcValidationTranslations validation;
}

/// Common FDC text shared by multiple component families.
class FdcCommonTranslations {
  /// Creates common translations.
  const FdcCommonTranslations({
    this.ok = 'OK',
    this.yes = 'Yes',
    this.no = 'No',
    this.cancel = 'Cancel',
    this.apply = 'Apply',
    this.clear = 'Clear',
    this.search = 'Search',
    this.all = 'All',
    this.delete = 'Delete',
    this.close = 'Close',
    this.pickDate = 'Pick date',
    this.lookup = 'Lookup',
    this.noResults = 'No results',
  });

  /// OK action text.
  final String ok;

  /// Yes action text.
  final String yes;

  /// No action text.
  final String no;

  /// Cancel action text.
  final String cancel;

  /// Apply action text.
  final String apply;

  /// Clear action text.
  final String clear;

  /// Search hint or action text.
  final String search;

  /// All values label.
  final String all;

  /// Delete action text.
  final String delete;

  /// Close action text.
  final String close;

  /// Date picker tooltip text.
  final String pickDate;

  /// Lookup action text.
  final String lookup;

  /// Empty search result text.
  final String noResults;
}

/// Dialog text resources.
class FdcDialogTranslations {
  /// Creates dialog translations.
  const FdcDialogTranslations({
    this.confirmDelete = 'Confirm delete',
    this.deleteCurrentRecord = 'Delete current record?',
  });

  /// Delete confirmation dialog title.
  final String confirmDelete;

  /// Delete confirmation dialog message.
  final String deleteCurrentRecord;
}

/// Grid text resources.
class FdcGridTranslations {
  /// Creates grid translations.
  const FdcGridTranslations({
    this.filters = 'Filters',
    this.showFilters = 'Show filters',
    this.hideFilters = 'Hide filters',
    this.clearFilter = 'Clear filter',
    this.clearFilters = 'Clear filters',
    this.clearAllFilters = 'Clear all filters',
    this.sorting = 'Sorting',
    this.sortAscending = 'Sort ascending',
    this.sortDescending = 'Sort descending',
    this.addAscendingSort = 'Add ascending sort',
    this.addDescendingSort = 'Add descending sort',
    this.clearSort = 'Clear sort',
    this.clearAllSorts = 'Clear all sorts',
    this.columnPinning = 'Column pinning',
    this.pinLeft = 'Pin to left',
    this.pinRight = 'Pin to right',
    this.unpin = 'Unpin',
    this.unpinAllColumns = 'Unpin all columns',
    this.resetGridLayout = 'Reset grid layout',
    this.noActionsAvailable = 'No actions available',
    this.mainMenu = 'Main menu',
    this.export = 'Export',
    String Function(String formatLabel)? exportTo,
    this.page = 'Page',
    this.of = 'of',
    this.noRangeFilter = 'No range filter',
    this.rangeFrom = 'From',
    this.rangeTo = 'To',
    this.searchHint = 'Search...',
    this.clearSearch = 'Clear search',
    this.caseSensitiveSearchOn = 'Case sensitive search is on',
    this.caseSensitiveSearchOff = 'Case sensitive search is off',
    this.searchOptions = 'Search options',
    this.searchAnyWord = 'Any word',
    this.searchAllWords = 'All words',
    this.searchExactPhrase = 'Exact phrase',
    this.firstPage = 'First page',
    this.previousPage = 'Previous page',
    this.nextPage = 'Next page',
    this.lastPage = 'Last page',
    String Function(int count)? selected,
    String Function(String value, String maximum)? valueOf,
    this.rating = 'Rating',
    this.trendNoData = 'Trend: No data',
    String Function(String points)? trend,
    this.browse = 'Browse',
    this.edit = 'Edit',
    this.insert = 'Insert',
    this.closed = 'Closed',
    this.loading = 'Loading',
    this.applyingUpdates = 'Applying updates',
    this.openingDataset = 'Opening dataset',
    this.loadingDataset = 'Loading dataset',
    this.filteringDataset = 'Filtering dataset',
    this.searchingDataset = 'Searching dataset',
    this.sortingDataset = 'Sorting dataset',
    this.datasetWork = 'Dataset work',
    this.aggregateSum = 'Sum',
    this.aggregateMin = 'Min',
    this.aggregateMax = 'Max',
    this.aggregateAvg = 'Avg',
    this.state = 'State',
    this.filtered = 'Filtered',
    this.sorted = 'Sorted',
    this.noRecords = '0 records',
    String Function(int recordNumber, int? totalCount)? record,
    this.showSelectedRows = 'Show selected rows',
    this.showUnselectedRows = 'Show unselected rows',
    this.clearSelectionFilter = 'Clear selection filter',
    this.containsPhrase = 'Contains phrase',
    this.startsWith = 'Starts with',
    this.operatorLabels = const FdcFilterOperatorTranslations(),
  }) : _exportTo = exportTo,
       _selected = selected,
       _valueOf = valueOf,
       _trend = trend,
       _record = record;

  /// Header filter group label.
  final String filters;

  /// Show filters menu action text.
  final String showFilters;

  /// Hide filters menu action text.
  final String hideFilters;

  /// Clear current filter action text.
  final String clearFilter;

  /// Clear all column filters from the main grid menu.
  final String clearFilters;

  /// Clear all filters action text from a column filter section.
  final String clearAllFilters;

  /// Sorting group label.
  final String sorting;

  /// Sort ascending action text.
  final String sortAscending;

  /// Sort descending action text.
  final String sortDescending;

  /// Add ascending sort action text for multi-column sort chains.
  final String addAscendingSort;

  /// Add descending sort action text for multi-column sort chains.
  final String addDescendingSort;

  /// Clear sort action text.
  final String clearSort;

  /// Clear all sort entries action text.
  final String clearAllSorts;

  /// Column pinning group label.
  final String columnPinning;

  /// Pin left action text.
  final String pinLeft;

  /// Pin right action text.
  final String pinRight;

  /// Unpin action text.
  final String unpin;

  /// Unpin all user-pinned columns action text.
  final String unpinAllColumns;

  /// Reset grid layout action text.
  final String resetGridLayout;

  /// Empty menu state text.
  final String noActionsAvailable;

  /// Toolbar/main-menu tooltip text.
  final String mainMenu;

  /// Toolbar/export menu tooltip text.
  final String export;

  final String Function(String formatLabel)? _exportTo;

  /// Formats a toolbar export menu action label.
  String exportTo(String formatLabel) =>
      (_exportTo ?? _defaultExportTo)(formatLabel);

  /// Page label.
  final String page;

  /// Count relation label.
  final String of;

  /// Range filter empty-state text.
  final String noRangeFilter;

  /// Range filter from-field label.
  final String rangeFrom;

  /// Range filter to-field label.
  final String rangeTo;

  /// Toolbar search field hint text.
  final String searchHint;

  /// Clear toolbar search action text.
  final String clearSearch;

  /// Case-sensitive search enabled tooltip text.
  final String caseSensitiveSearchOn;

  /// Case-sensitive search disabled tooltip text.
  final String caseSensitiveSearchOff;

  /// Search options menu tooltip text.
  final String searchOptions;

  /// Search match-mode label for any word.
  final String searchAnyWord;

  /// Search match-mode label for all words.
  final String searchAllWords;

  /// Search match-mode label for exact phrase.
  final String searchExactPhrase;

  /// First page action tooltip text.
  final String firstPage;

  /// Previous page action tooltip text.
  final String previousPage;

  /// Next page action tooltip text.
  final String nextPage;

  /// Last page action tooltip text.
  final String lastPage;

  final String Function(int count)? _selected;

  /// Formats a selected item count.
  String selected(int count) => (_selected ?? _defaultSelected)(count);

  final String Function(String value, String maximum)? _valueOf;

  /// Formats a value-of-maximum label.
  String valueOf(String value, String maximum) =>
      (_valueOf ?? _defaultValueOf)(value, maximum);

  /// Rating semantics label.
  final String rating;

  /// Sparkline empty semantics label.
  final String trendNoData;

  final String Function(String points)? _trend;

  /// Formats a sparkline trend semantics label.
  String trend(String points) => (_trend ?? _defaultTrend)(points);

  /// Browse row-state tooltip text.
  final String browse;

  /// Edit row-state tooltip text.
  final String edit;

  /// Insert row-state tooltip text.
  final String insert;

  /// Closed dataset state text.
  final String closed;

  /// Loading dataset state text.
  final String loading;

  /// Applying-updates dataset state text.
  final String applyingUpdates;

  /// Dataset open work semantics text.
  final String openingDataset;

  /// Dataset load work semantics text.
  final String loadingDataset;

  /// Dataset filter work semantics text.
  final String filteringDataset;

  /// Dataset search work semantics text.
  final String searchingDataset;

  /// Dataset sort work semantics text.
  final String sortingDataset;

  /// Generic dataset work semantics text.
  final String datasetWork;

  /// Sum aggregate label used in summary rows and menus.
  final String aggregateSum;

  /// Minimum aggregate label used in summary rows and menus.
  final String aggregateMin;

  /// Maximum aggregate label used in summary rows and menus.
  final String aggregateMax;

  /// Average aggregate label used in summary rows and menus.
  final String aggregateAvg;

  /// Dataset state status-bar label.
  final String state;

  /// Active filter status text.
  final String filtered;

  /// Active sort status text.
  final String sorted;

  /// Empty record-count status text.
  final String noRecords;

  final String Function(int recordNumber, int? totalCount)? _record;

  /// Formats the current record status text.
  String record(int recordNumber, int? totalCount) =>
      (_record ?? _defaultRecord)(recordNumber, totalCount);

  /// Row selection filter text for selected rows.
  final String showSelectedRows;

  /// Row selection filter text for unselected rows.
  final String showUnselectedRows;

  /// Clears row selection filter text.
  final String clearSelectionFilter;

  /// Global search mode label for contains-phrase search.
  final String containsPhrase;

  /// Global search mode label for starts-with search.
  final String startsWith;

  /// Filter operator labels.
  final FdcFilterOperatorTranslations operatorLabels;

  /// Resolves a localized label for a summary aggregate.
  String aggregateLabel(FdcAggregate aggregate) {
    return switch (aggregate) {
      FdcAggregate.sum => aggregateSum,
      FdcAggregate.min => aggregateMin,
      FdcAggregate.max => aggregateMax,
      FdcAggregate.avg => aggregateAvg,
    };
  }

  /// Resolves a localized label for a dataset work phase.
  String workPhaseLabel(String phaseName) {
    switch (phaseName) {
      case 'open':
        return openingDataset;
      case 'filter':
        return filteringDataset;
      case 'sort':
        return sortingDataset;
      case 'search':
        return searchingDataset;
      case 'applyUpdates':
        return applyingUpdates;
      case 'load':
        return loadingDataset;
      case 'idle':
      case 'custom':
        return datasetWork;
    }
    return datasetWork;
  }

  static String _defaultExportTo(String formatLabel) =>
      'Export to $formatLabel';

  static String _defaultSelected(int count) => '$count selected';

  static String _defaultValueOf(String value, String maximum) =>
      '$value of $maximum';

  static String _defaultTrend(String points) => 'Trend: $points';

  static String _defaultRecord(int recordNumber, int? totalCount) =>
      totalCount == null
      ? 'Record $recordNumber'
      : 'Record $recordNumber of $totalCount';
}

/// Header filter operator text resources.
class FdcFilterOperatorTranslations {
  /// Creates filter operator translations.
  const FdcFilterOperatorTranslations({
    this.contains = 'Contains',
    this.notContains = 'Does not contain',
    this.equals = 'Equals',
    this.notEquals = 'Not equal',
    this.startsWith = 'Starts with',
    this.endsWith = 'Ends with',
    this.greaterThan = 'Greater than',
    this.greaterThanOrEqual = 'Greater than or equal',
    this.lessThan = 'Less than',
    this.lessThanOrEqual = 'Less than or equal',
    this.between = 'Between',
    this.inList = 'In list',
    this.notInList = 'Not in list',
    this.isNull = 'Is null',
    this.isNotNull = 'Is not null',
    this.isEmpty = 'Is empty',
    this.isNotEmpty = 'Is not empty',
    this.isNullOrWhitespace = 'Is null or whitespace',
    this.isNotNullOrWhitespace = 'Is not null or whitespace',
    this.isTrue = 'Is true',
    this.isFalse = 'Is false',
  });

  /// Contains operator label.
  final String contains;

  /// Not contains operator label.
  final String notContains;

  /// Equals operator label.
  final String equals;

  /// Not equals operator label.
  final String notEquals;

  /// Starts with operator label.
  final String startsWith;

  /// Ends with operator label.
  final String endsWith;

  /// Greater-than operator label.
  final String greaterThan;

  /// Greater-than-or-equal operator label.
  final String greaterThanOrEqual;

  /// Less-than operator label.
  final String lessThan;

  /// Less-than-or-equal operator label.
  final String lessThanOrEqual;

  /// Between operator label.
  final String between;

  /// In-list operator label.
  final String inList;

  /// Not-in-list operator label.
  final String notInList;

  /// Is-null operator label.
  final String isNull;

  /// Is-not-null operator label.
  final String isNotNull;

  /// Is-empty operator label.
  final String isEmpty;

  /// Is-not-empty operator label.
  final String isNotEmpty;

  /// Null-or-whitespace operator label.
  final String isNullOrWhitespace;

  /// Not-null-or-whitespace operator label.
  final String isNotNullOrWhitespace;

  /// Is-true operator label.
  final String isTrue;

  /// Is-false operator label.
  final String isFalse;
}

/// Builds a validation message for a field label.
typedef FdcFieldValidationMessageBuilder = String Function(String fieldLabel);

/// Builds a validation message for a field and limit value.
typedef FdcFieldLimitValidationMessageBuilder =
    String Function(String fieldLabel, Object limit);

/// Builds a decimal precision and scale validation message.
typedef FdcDecimalPrecisionValidationMessageBuilder =
    String Function(int? precision, int? scale);

String _fdcRequiredFieldMessage(String fieldLabel) =>
    'Field $fieldLabel is required.';

String _fdcInvalidNumericFieldMessage(String fieldLabel) =>
    'Field $fieldLabel has invalid numeric value.';

String _fdcMinValueFieldMessage(String fieldLabel, Object limit) =>
    'Field $fieldLabel must be greater than or equal to $limit.';

String _fdcMaxValueFieldMessage(String fieldLabel, Object limit) =>
    'Field $fieldLabel must be less than or equal to $limit.';

String _fdcDecimalPrecisionMessage(int? precision, int? scale) {
  if (precision == null || scale == null) {
    return 'Decimal value exceeds allowed precision.';
  }
  return 'Decimal value exceeds precision $precision and scale $scale.';
}

/// Validation text resources.
class FdcValidationTranslations {
  /// Creates validation translations.
  const FdcValidationTranslations({
    this.validationError = 'Validation error',
    this.enterValidInteger = 'Enter a valid integer',
    this.enterValidDecimal = 'Enter a valid decimal number',
    this.decimalPrecisionExceeded = _fdcDecimalPrecisionMessage,
    this.validationFailed = 'Validation failed.',
    this.lookupFailed = 'Lookup failed.',
    this.dataOperationError = 'Data operation error',
    this.dataSetError = 'DataSet error',
    this.error = 'Error',
    this.requiredValue = 'Required',
    this.invalidValue = 'Invalid value',
    this.requiredField = _fdcRequiredFieldMessage,
    this.invalidNumericField = _fdcInvalidNumericFieldMessage,
    this.minValueField = _fdcMinValueFieldMessage,
    this.maxValueField = _fdcMaxValueFieldMessage,
  });

  /// Generic validation error title.
  final String validationError;

  /// Invalid integer message.
  final String enterValidInteger;

  /// Invalid decimal message.
  final String enterValidDecimal;

  /// Decimal precision/scale validation message.
  final FdcDecimalPrecisionValidationMessageBuilder decimalPrecisionExceeded;

  /// Generic validation failure fallback message.
  final String validationFailed;

  /// Generic lookup failure fallback message.
  final String lookupFailed;

  /// Data operation error title.
  final String dataOperationError;

  /// Dataset error title.
  final String dataSetError;

  /// Generic error title.
  final String error;

  /// Required value validation message.
  final String requiredValue;

  /// Invalid value validation message.
  final String invalidValue;

  /// Dataset required-field validation message.
  final FdcFieldValidationMessageBuilder requiredField;

  /// Dataset invalid numeric value validation message.
  final FdcFieldValidationMessageBuilder invalidNumericField;

  /// Dataset minimum-value validation message.
  final FdcFieldLimitValidationMessageBuilder minValueField;

  /// Dataset maximum-value validation message.
  final FdcFieldLimitValidationMessageBuilder maxValueField;
}
