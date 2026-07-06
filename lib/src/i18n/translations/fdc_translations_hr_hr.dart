// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: avoid_redundant_argument_values

part of '../fdc_translations.dart';

/// Returns the built-in Croatian (Croatia) FDC translations.
FdcTranslations _fdcTranslationsHrHr() => FdcTranslations(
  common: const FdcCommonTranslations(
    ok: 'U redu',
    yes: 'Da',
    no: 'Ne',
    cancel: 'Odustani',
    apply: 'Primijeni',
    clear: 'Očisti',
    search: 'Pretraži',
    all: 'Sve',
    delete: 'Izbriši',
    close: 'Zatvori',
    pickDate: 'Odaberi datum',
    lookup: 'Lookup',
    noResults: 'Nema rezultata',
  ),
  dialogs: const FdcDialogTranslations(
    confirmDelete: 'Potvrda brisanja',
    deleteCurrentRecord: 'Izbrisati trenutni zapis?',
  ),
  grid: FdcGridTranslations(
    filters: 'Filtri',
    showFilters: 'Prikaži filtre',
    hideFilters: 'Sakrij filtre',
    clearFilter: 'Očisti filtar',
    clearFilters: 'Očisti filtre',
    clearAllFilters: 'Očisti sve filtre',
    sorting: 'Sortiranje',
    sortAscending: 'Sortiraj uzlazno',
    sortDescending: 'Sortiraj silazno',
    addAscendingSort: 'Dodaj uzlazno sortiranje',
    addDescendingSort: 'Dodaj silazno sortiranje',
    clearSort: 'Očisti sortiranje',
    clearAllSorts: 'Očisti sva sortiranja',
    columnPinning: 'Fiksiranje stupca',
    pinLeft: 'Fiksiraj lijevo',
    pinRight: 'Fiksiraj desno',
    unpin: 'Oslobodi stupac',
    unpinAllColumns: 'Oslobodi sve stupce',
    resetGridLayout: 'Vrati raspored grida',
    noActionsAvailable: 'Nema dostupnih akcija',
    mainMenu: 'Glavni izbornik',
    export: 'Izvoz',
    exportTo: (formatLabel) => 'Izvoz u $formatLabel',
    page: 'Stranica',
    of: 'od',
    noRangeFilter: 'Nema rasponskog filtra',
    rangeFrom: 'Od',
    rangeTo: 'Do',
    searchHint: 'Pretraži...',
    clearSearch: 'Očisti pretragu',
    caseSensitiveSearchOn: 'Pretraga razlikuje velika i mala slova',
    caseSensitiveSearchOff: 'Pretraga ne razlikuje velika i mala slova',
    searchOptions: 'Opcije pretrage',
    searchAnyWord: 'Bilo koja riječ',
    searchAllWords: 'Sve riječi',
    searchExactPhrase: 'Točna fraza',
    firstPage: 'Prva stranica',
    previousPage: 'Prethodna stranica',
    nextPage: 'Sljedeća stranica',
    lastPage: 'Zadnja stranica',
    selected: (count) => '$count odabrano',
    valueOf: (value, maximum) => '$value od $maximum',
    rating: 'Ocjena',
    trendNoData: 'Trend: nema podataka',
    trend: (points) => 'Trend: $points',
    browse: 'Pregled',
    edit: 'Uređivanje',
    insert: 'Unos',
    closed: 'Zatvoreno',
    loading: 'Učitavanje',
    applyingUpdates: 'Primjena izmjena',
    openingDataset: 'Otvaranje dataseta',
    loadingDataset: 'Učitavanje dataseta',
    filteringDataset: 'Filtriranje dataseta',
    searchingDataset: 'Pretraživanje dataseta',
    sortingDataset: 'Sortiranje dataseta',
    datasetWork: 'Rad nad datasetom',
    aggregateSum: 'Zbroj',
    aggregateMin: 'Min',
    aggregateMax: 'Max',
    aggregateAvg: 'Prosjek',
    state: 'Stanje',
    filtered: 'Filtrirano',
    sorted: 'Sortirano',
    noRecords: '0 zapisa',
    record: (recordNumber, totalCount) => totalCount == null
        ? 'Zapis $recordNumber'
        : 'Zapis $recordNumber od $totalCount',
    showSelectedRows: 'Prikaži odabrane retke',
    showUnselectedRows: 'Prikaži neodabrane retke',
    clearSelectionFilter: 'Očisti filtar odabira',
    containsPhrase: 'Sadrži frazu',
    startsWith: 'Počinje s',
    operatorLabels: const FdcFilterOperatorTranslations(
      contains: 'Sadrži',
      notContains: 'Ne sadrži',
      equals: 'Jednako',
      notEquals: 'Nije jednako',
      startsWith: 'Počinje s',
      endsWith: 'Završava s',
      greaterThan: 'Veće od',
      greaterThanOrEqual: 'Veće ili jednako',
      lessThan: 'Manje od',
      lessThanOrEqual: 'Manje ili jednako',
      between: 'Između',
      inList: 'U listi',
      notInList: 'Nije u listi',
      isNull: 'Je null',
      isNotNull: 'Nije null',
      isEmpty: 'Prazno',
      isNotEmpty: 'Nije prazno',
      isNullOrWhitespace: 'Null ili prazno',
      isNotNullOrWhitespace: 'Nije null ni prazno',
      isTrue: 'Da',
      isFalse: 'Ne',
    ),
  ),
  validation: const FdcValidationTranslations(
    validationError: 'Greška validacije',
    enterValidInteger: 'Unesite ispravan cijeli broj',
    enterValidDecimal: 'Unesite ispravan decimalni broj',
    decimalPrecisionExceeded: _hrDecimalPrecisionExceeded,
    validationFailed: 'Validacija nije uspjela.',
    lookupFailed: 'Lookup nije uspio.',
    dataOperationError: 'Greška podatkovne operacije',
    dataSetError: 'Greška dataseta',
    error: 'Greška',
    requiredValue: 'Obavezno',
    invalidValue: 'Neispravna vrijednost',
    requiredField: _hrRequiredField,
    invalidNumericField: _hrInvalidNumericField,
    minValueField: _hrMinValueField,
    maxValueField: _hrMaxValueField,
  ),
);

String _hrDecimalPrecisionExceeded(int? precision, int? scale) {
  if (precision == null || scale == null) {
    return 'Decimalna vrijednost premašuje dopuštenu preciznost.';
  }
  return 'Decimalna vrijednost premašuje preciznost $precision i skalu $scale.';
}

String _hrRequiredField(String fieldLabel) => 'Polje $fieldLabel je obavezno.';

String _hrInvalidNumericField(String fieldLabel) =>
    'Polje $fieldLabel ima neispravnu numeričku vrijednost.';

String _hrMinValueField(String fieldLabel, Object limit) =>
    'Polje $fieldLabel mora biti veće ili jednako $limit.';

String _hrMaxValueField(String fieldLabel, Object limit) =>
    'Polje $fieldLabel mora biti manje ili jednako $limit.';
