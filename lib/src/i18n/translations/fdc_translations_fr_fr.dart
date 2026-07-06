// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: avoid_redundant_argument_values

part of '../fdc_translations.dart';

/// Returns the built-in French (France) FDC translations.
FdcTranslations _fdcTranslationsFrFr() => FdcTranslations(
  common: const FdcCommonTranslations(
    ok: 'OK',
    yes: 'Oui',
    no: 'Non',
    cancel: 'Annuler',
    apply: 'Appliquer',
    clear: 'Effacer',
    search: 'Rechercher',
    all: 'Tous',
    delete: 'Supprimer',
    close: 'Fermer',
    pickDate: 'Choisir une date',
    lookup: 'Recherche',
    noResults: 'Aucun résultat',
  ),
  dialogs: const FdcDialogTranslations(
    confirmDelete: 'Confirmer la suppression',
    deleteCurrentRecord: 'Supprimer l’enregistrement courant ?',
  ),
  grid: FdcGridTranslations(
    filters: 'Filtres',
    showFilters: 'Afficher les filtres',
    hideFilters: 'Masquer les filtres',
    clearFilter: 'Effacer le filtre',
    clearFilters: 'Effacer les filtres',
    clearAllFilters: 'Effacer tous les filtres',
    sorting: 'Tri',
    sortAscending: 'Trier par ordre croissant',
    sortDescending: 'Trier par ordre décroissant',
    addAscendingSort: 'Ajouter un tri croissant',
    addDescendingSort: 'Ajouter un tri décroissant',
    clearSort: 'Effacer le tri',
    clearAllSorts: 'Effacer tous les tris',
    columnPinning: 'Épinglage des colonnes',
    pinLeft: 'Épingler à gauche',
    pinRight: 'Épingler à droite',
    unpin: 'Désépingler',
    unpinAllColumns: 'Désépingler toutes les colonnes',
    resetGridLayout: 'Réinitialiser la disposition de la grille',
    noActionsAvailable: 'Aucune action disponible',
    mainMenu: 'Menu principal',
    export: 'Exporter',
    exportTo: (formatLabel) => 'Exporter en $formatLabel',
    page: 'Page',
    of: 'sur',
    noRangeFilter: 'Aucun filtre de plage',
    rangeFrom: 'De',
    rangeTo: 'À',
    searchHint: 'Rechercher...',
    clearSearch: 'Effacer la recherche',
    caseSensitiveSearchOn: 'Recherche sensible à la casse activée',
    caseSensitiveSearchOff: 'Recherche insensible à la casse',
    searchOptions: 'Options de recherche',
    searchAnyWord: 'N’importe quel mot',
    searchAllWords: 'Tous les mots',
    searchExactPhrase: 'Phrase exacte',
    firstPage: 'Première page',
    previousPage: 'Page précédente',
    nextPage: 'Page suivante',
    lastPage: 'Dernière page',
    selected: (count) => '$count sélectionné(s)',
    valueOf: (value, maximum) => '$value sur $maximum',
    rating: 'Note',
    trendNoData: 'Tendance : aucune donnée',
    trend: (points) => 'Tendance : $points',
    browse: 'Consultation',
    edit: 'Modification',
    insert: 'Insertion',
    closed: 'Fermé',
    loading: 'Chargement',
    applyingUpdates: 'Application des modifications',
    openingDataset: 'Ouverture du dataset',
    loadingDataset: 'Chargement du dataset',
    filteringDataset: 'Filtrage du dataset',
    searchingDataset: 'Recherche dans le dataset',
    sortingDataset: 'Tri du dataset',
    datasetWork: 'Opération sur le dataset',
    aggregateSum: 'Somme',
    aggregateMin: 'Min',
    aggregateMax: 'Max',
    aggregateAvg: 'Moyenne',
    state: 'État',
    filtered: 'Filtré',
    sorted: 'Trié',
    noRecords: '0 enregistrement',
    record: (recordNumber, totalCount) => totalCount == null
        ? 'Enregistrement $recordNumber'
        : 'Enregistrement $recordNumber sur $totalCount',
    showSelectedRows: 'Afficher les lignes sélectionnées',
    showUnselectedRows: 'Afficher les lignes non sélectionnées',
    clearSelectionFilter: 'Effacer le filtre de sélection',
    containsPhrase: 'Contient la phrase',
    startsWith: 'Commence par',
    operatorLabels: const FdcFilterOperatorTranslations(
      contains: 'Contient',
      notContains: 'Ne contient pas',
      equals: 'Égal à',
      notEquals: 'Différent de',
      startsWith: 'Commence par',
      endsWith: 'Se termine par',
      greaterThan: 'Supérieur à',
      greaterThanOrEqual: 'Supérieur ou égal',
      lessThan: 'Inférieur à',
      lessThanOrEqual: 'Inférieur ou égal',
      between: 'Entre',
      inList: 'Dans la liste',
      notInList: 'Pas dans la liste',
      isNull: 'Est null',
      isNotNull: 'N’est pas null',
      isEmpty: 'Est vide',
      isNotEmpty: 'N’est pas vide',
      isNullOrWhitespace: 'Null ou espaces',
      isNotNullOrWhitespace: 'Ni null ni espaces',
      isTrue: 'Oui',
      isFalse: 'Non',
    ),
  ),
  validation: const FdcValidationTranslations(
    validationError: 'Erreur de validation',
    enterValidInteger: 'Saisissez un entier valide',
    enterValidDecimal: 'Saisissez un nombre décimal valide',
    decimalPrecisionExceeded: _frDecimalPrecisionExceeded,
    validationFailed: 'La validation a échoué.',
    lookupFailed: 'La recherche a échoué.',
    dataOperationError: 'Erreur d’opération de données',
    dataSetError: 'Erreur de dataset',
    error: 'Erreur',
    requiredValue: 'Obligatoire',
    invalidValue: 'Valeur non valide',
    requiredField: _frRequiredField,
    invalidNumericField: _frInvalidNumericField,
    minValueField: _frMinValueField,
    maxValueField: _frMaxValueField,
  ),
);

String _frDecimalPrecisionExceeded(int? precision, int? scale) {
  if (precision == null || scale == null) {
    return 'La valeur décimale dépasse la précision autorisée.';
  }
  return 'La valeur décimale dépasse la précision $precision et l’échelle $scale.';
}

String _frRequiredField(String fieldLabel) =>
    'Le champ $fieldLabel est obligatoire.';

String _frInvalidNumericField(String fieldLabel) =>
    'Le champ $fieldLabel contient une valeur numérique non valide.';

String _frMinValueField(String fieldLabel, Object limit) =>
    'Le champ $fieldLabel doit être supérieur ou égal à $limit.';

String _frMaxValueField(String fieldLabel, Object limit) =>
    'Le champ $fieldLabel doit être inférieur ou égal à $limit.';
