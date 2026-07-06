// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: avoid_redundant_argument_values

part of '../fdc_translations.dart';

/// Returns the built-in Italian (Italy) FDC translations.
FdcTranslations _fdcTranslationsItIt() => FdcTranslations(
  common: const FdcCommonTranslations(
    ok: 'OK',
    yes: 'Sì',
    no: 'No',
    cancel: 'Annulla',
    apply: 'Applica',
    clear: 'Cancella',
    search: 'Cerca',
    all: 'Tutti',
    delete: 'Elimina',
    close: 'Chiudi',
    pickDate: 'Seleziona data',
    lookup: 'Ricerca',
    noResults: 'Nessun risultato',
  ),
  dialogs: const FdcDialogTranslations(
    confirmDelete: 'Conferma eliminazione',
    deleteCurrentRecord: 'Eliminare il record corrente?',
  ),
  grid: FdcGridTranslations(
    filters: 'Filtri',
    showFilters: 'Mostra filtri',
    hideFilters: 'Nascondi filtri',
    clearFilter: 'Cancella filtro',
    clearFilters: 'Cancella filtri',
    clearAllFilters: 'Cancella tutti i filtri',
    sorting: 'Ordinamento',
    sortAscending: 'Ordina crescente',
    sortDescending: 'Ordina decrescente',
    addAscendingSort: 'Aggiungi ordinamento crescente',
    addDescendingSort: 'Aggiungi ordinamento decrescente',
    clearSort: 'Cancella ordinamento',
    clearAllSorts: 'Cancella tutti gli ordinamenti',
    columnPinning: 'Fissaggio colonne',
    pinLeft: 'Fissa a sinistra',
    pinRight: 'Fissa a destra',
    unpin: 'Sblocca colonna',
    unpinAllColumns: 'Sblocca tutte le colonne',
    resetGridLayout: 'Ripristina layout griglia',
    noActionsAvailable: 'Nessuna azione disponibile',
    mainMenu: 'Menu principale',
    export: 'Esporta',
    exportTo: (formatLabel) => 'Esporta in $formatLabel',
    page: 'Pagina',
    of: 'di',
    noRangeFilter: 'Nessun filtro intervallo',
    rangeFrom: 'Da',
    rangeTo: 'A',
    searchHint: 'Cerca...',
    clearSearch: 'Cancella ricerca',
    caseSensitiveSearchOn: 'Ricerca con distinzione maiuscole/minuscole attiva',
    caseSensitiveSearchOff: 'Ricerca senza distinzione maiuscole/minuscole',
    searchOptions: 'Opzioni di ricerca',
    searchAnyWord: 'Qualsiasi parola',
    searchAllWords: 'Tutte le parole',
    searchExactPhrase: 'Frase esatta',
    firstPage: 'Prima pagina',
    previousPage: 'Pagina precedente',
    nextPage: 'Pagina successiva',
    lastPage: 'Ultima pagina',
    selected: (count) => '$count selezionati',
    valueOf: (value, maximum) => '$value di $maximum',
    rating: 'Valutazione',
    trendNoData: 'Trend: nessun dato',
    trend: (points) => 'Trend: $points',
    browse: 'Sfoglia',
    edit: 'Modifica',
    insert: 'Inserimento',
    closed: 'Chiuso',
    loading: 'Caricamento',
    applyingUpdates: 'Applicazione modifiche',
    openingDataset: 'Apertura dataset',
    loadingDataset: 'Caricamento dataset',
    filteringDataset: 'Filtro dataset',
    searchingDataset: 'Ricerca nel dataset',
    sortingDataset: 'Ordinamento dataset',
    datasetWork: 'Operazione sul dataset',
    aggregateSum: 'Somma',
    aggregateMin: 'Min',
    aggregateMax: 'Max',
    aggregateAvg: 'Media',
    state: 'Stato',
    filtered: 'Filtrato',
    sorted: 'Ordinato',
    noRecords: '0 record',
    record: (recordNumber, totalCount) => totalCount == null
        ? 'Record $recordNumber'
        : 'Record $recordNumber di $totalCount',
    showSelectedRows: 'Mostra righe selezionate',
    showUnselectedRows: 'Mostra righe non selezionate',
    clearSelectionFilter: 'Cancella filtro selezione',
    containsPhrase: 'Contiene frase',
    startsWith: 'Inizia con',
    operatorLabels: const FdcFilterOperatorTranslations(
      contains: 'Contiene',
      notContains: 'Non contiene',
      equals: 'Uguale a',
      notEquals: 'Diverso da',
      startsWith: 'Inizia con',
      endsWith: 'Finisce con',
      greaterThan: 'Maggiore di',
      greaterThanOrEqual: 'Maggiore o uguale',
      lessThan: 'Minore di',
      lessThanOrEqual: 'Minore o uguale',
      between: 'Tra',
      inList: 'Nella lista',
      notInList: 'Non nella lista',
      isNull: 'È null',
      isNotNull: 'Non è null',
      isEmpty: 'È vuoto',
      isNotEmpty: 'Non è vuoto',
      isNullOrWhitespace: 'Null o solo spazi',
      isNotNullOrWhitespace: 'Non null né solo spazi',
      isTrue: 'Sì',
      isFalse: 'No',
    ),
  ),
  validation: const FdcValidationTranslations(
    validationError: 'Errore di validazione',
    enterValidInteger: 'Inserire un numero intero valido',
    enterValidDecimal: 'Inserire un numero decimale valido',
    decimalPrecisionExceeded: _itDecimalPrecisionExceeded,
    validationFailed: 'Validazione non riuscita.',
    lookupFailed: 'Ricerca non riuscita.',
    dataOperationError: 'Errore operazione dati',
    dataSetError: 'Errore dataset',
    error: 'Errore',
    requiredValue: 'Obbligatorio',
    invalidValue: 'Valore non valido',
    requiredField: _itRequiredField,
    invalidNumericField: _itInvalidNumericField,
    minValueField: _itMinValueField,
    maxValueField: _itMaxValueField,
  ),
);

String _itDecimalPrecisionExceeded(int? precision, int? scale) {
  if (precision == null || scale == null) {
    return 'Il valore decimale supera la precisione consentita.';
  }
  return 'Il valore decimale supera la precisione $precision e la scala $scale.';
}

String _itRequiredField(String fieldLabel) =>
    'Il campo $fieldLabel è obbligatorio.';

String _itInvalidNumericField(String fieldLabel) =>
    'Il campo $fieldLabel contiene un valore numerico non valido.';

String _itMinValueField(String fieldLabel, Object limit) =>
    'Il campo $fieldLabel deve essere maggiore o uguale a $limit.';

String _itMaxValueField(String fieldLabel, Object limit) =>
    'Il campo $fieldLabel deve essere minore o uguale a $limit.';
