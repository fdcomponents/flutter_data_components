// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: avoid_redundant_argument_values

part of '../fdc_translations.dart';

/// Returns the built-in German (Germany) FDC translations.
FdcTranslations _fdcTranslationsDeDe() => FdcTranslations(
  common: const FdcCommonTranslations(
    ok: 'OK',
    yes: 'Ja',
    no: 'Nein',
    cancel: 'Abbrechen',
    apply: 'Anwenden',
    clear: 'Löschen',
    search: 'Suchen',
    all: 'Alle',
    delete: 'Löschen',
    close: 'Schließen',
    pickDate: 'Datum auswählen',
    lookup: 'Nachschlagen',
    noResults: 'Keine Ergebnisse',
  ),
  dialogs: const FdcDialogTranslations(
    confirmDelete: 'Löschen bestätigen',
    deleteCurrentRecord: 'Aktuellen Datensatz löschen?',
  ),
  grid: FdcGridTranslations(
    filters: 'Filter',
    showFilters: 'Filter anzeigen',
    hideFilters: 'Filter ausblenden',
    clearFilter: 'Filter löschen',
    clearFilters: 'Filter löschen',
    clearAllFilters: 'Alle Filter löschen',
    sorting: 'Sortierung',
    sortAscending: 'Aufsteigend sortieren',
    sortDescending: 'Absteigend sortieren',
    addAscendingSort: 'Aufsteigende Sortierung hinzufügen',
    addDescendingSort: 'Absteigende Sortierung hinzufügen',
    clearSort: 'Sortierung löschen',
    clearAllSorts: 'Alle Sortierungen löschen',
    columnPinning: 'Spaltenfixierung',
    pinLeft: 'Links fixieren',
    pinRight: 'Rechts fixieren',
    unpin: 'Fixierung lösen',
    unpinAllColumns: 'Alle Spaltenfixierungen lösen',
    resetGridLayout: 'Grid-Layout zurücksetzen',
    noActionsAvailable: 'Keine Aktionen verfügbar',
    mainMenu: 'Hauptmenü',
    export: 'Exportieren',
    exportTo: (formatLabel) => 'Als $formatLabel exportieren',
    page: 'Seite',
    of: 'von',
    noRangeFilter: 'Kein Bereichsfilter',
    rangeFrom: 'Von',
    rangeTo: 'Bis',
    searchHint: 'Suchen...',
    clearSearch: 'Suche löschen',
    caseSensitiveSearchOn: 'Groß-/Kleinschreibung wird beachtet',
    caseSensitiveSearchOff: 'Groß-/Kleinschreibung wird ignoriert',
    searchOptions: 'Suchoptionen',
    searchAnyWord: 'Beliebiges Wort',
    searchAllWords: 'Alle Wörter',
    searchExactPhrase: 'Exakte Phrase',
    firstPage: 'Erste Seite',
    previousPage: 'Vorherige Seite',
    nextPage: 'Nächste Seite',
    lastPage: 'Letzte Seite',
    selected: (count) => '$count ausgewählt',
    valueOf: (value, maximum) => '$value von $maximum',
    rating: 'Bewertung',
    trendNoData: 'Trend: keine Daten',
    trend: (points) => 'Trend: $points',
    browse: 'Anzeigen',
    edit: 'Bearbeiten',
    insert: 'Einfügen',
    closed: 'Geschlossen',
    loading: 'Laden',
    applyingUpdates: 'Änderungen anwenden',
    openingDataset: 'Dataset öffnen',
    loadingDataset: 'Dataset laden',
    filteringDataset: 'Dataset filtern',
    searchingDataset: 'Dataset durchsuchen',
    sortingDataset: 'Dataset sortieren',
    datasetWork: 'Dataset-Vorgang',
    aggregateSum: 'Summe',
    aggregateMin: 'Min',
    aggregateMax: 'Max',
    aggregateAvg: 'Durchschnitt',
    state: 'Status',
    filtered: 'Gefiltert',
    sorted: 'Sortiert',
    noRecords: '0 Datensätze',
    record: (recordNumber, totalCount) => totalCount == null
        ? 'Datensatz $recordNumber'
        : 'Datensatz $recordNumber von $totalCount',
    showSelectedRows: 'Ausgewählte Zeilen anzeigen',
    showUnselectedRows: 'Nicht ausgewählte Zeilen anzeigen',
    clearSelectionFilter: 'Auswahlfilter löschen',
    containsPhrase: 'Enthält Phrase',
    startsWith: 'Beginnt mit',
    operatorLabels: const FdcFilterOperatorTranslations(
      contains: 'Enthält',
      notContains: 'Enthält nicht',
      equals: 'Gleich',
      notEquals: 'Ungleich',
      startsWith: 'Beginnt mit',
      endsWith: 'Endet mit',
      greaterThan: 'Größer als',
      greaterThanOrEqual: 'Größer oder gleich',
      lessThan: 'Kleiner als',
      lessThanOrEqual: 'Kleiner oder gleich',
      between: 'Zwischen',
      inList: 'In Liste',
      notInList: 'Nicht in Liste',
      isNull: 'Ist null',
      isNotNull: 'Ist nicht null',
      isEmpty: 'Ist leer',
      isNotEmpty: 'Ist nicht leer',
      isNullOrWhitespace: 'Null oder Leerzeichen',
      isNotNullOrWhitespace: 'Nicht null und nicht Leerzeichen',
      isTrue: 'Ja',
      isFalse: 'Nein',
    ),
  ),
  validation: const FdcValidationTranslations(
    validationError: 'Validierungsfehler',
    enterValidInteger: 'Geben Sie eine gültige ganze Zahl ein',
    enterValidDecimal: 'Geben Sie eine gültige Dezimalzahl ein',
    decimalPrecisionExceeded: _deDecimalPrecisionExceeded,
    validationFailed: 'Validierung fehlgeschlagen.',
    lookupFailed: 'Nachschlagen fehlgeschlagen.',
    dataOperationError: 'Datenoperationsfehler',
    dataSetError: 'Dataset-Fehler',
    error: 'Fehler',
    requiredValue: 'Erforderlich',
    invalidValue: 'Ungültiger Wert',
    requiredField: _deRequiredField,
    invalidNumericField: _deInvalidNumericField,
    minValueField: _deMinValueField,
    maxValueField: _deMaxValueField,
  ),
);

String _deDecimalPrecisionExceeded(int? precision, int? scale) {
  if (precision == null || scale == null) {
    return 'Der Dezimalwert überschreitet die erlaubte Genauigkeit.';
  }
  return 'Der Dezimalwert überschreitet Genauigkeit $precision und Skalierung $scale.';
}

String _deRequiredField(String fieldLabel) =>
    'Das Feld $fieldLabel ist erforderlich.';

String _deInvalidNumericField(String fieldLabel) =>
    'Das Feld $fieldLabel enthält einen ungültigen numerischen Wert.';

String _deMinValueField(String fieldLabel, Object limit) =>
    'Das Feld $fieldLabel muss größer oder gleich $limit sein.';

String _deMaxValueField(String fieldLabel, Object limit) =>
    'Das Feld $fieldLabel muss kleiner oder gleich $limit sein.';
