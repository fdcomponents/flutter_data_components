// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: avoid_redundant_argument_values

part of '../fdc_translations.dart';

/// Returns the built-in Spanish (Spain) FDC translations.
FdcTranslations _fdcTranslationsEsEs() => FdcTranslations(
  common: const FdcCommonTranslations(
    ok: 'Aceptar',
    yes: 'Sí',
    no: 'No',
    cancel: 'Cancelar',
    apply: 'Aplicar',
    clear: 'Limpiar',
    search: 'Buscar',
    all: 'Todos',
    delete: 'Eliminar',
    close: 'Cerrar',
    pickDate: 'Elegir fecha',
    lookup: 'Búsqueda',
    noResults: 'Sin resultados',
  ),
  dialogs: const FdcDialogTranslations(
    confirmDelete: 'Confirmar eliminación',
    deleteCurrentRecord: '¿Eliminar el registro actual?',
  ),
  grid: FdcGridTranslations(
    filters: 'Filtros',
    showFilters: 'Mostrar filtros',
    hideFilters: 'Ocultar filtros',
    clearFilter: 'Limpiar filtro',
    clearFilters: 'Limpiar filtros',
    clearAllFilters: 'Limpiar todos los filtros',
    sorting: 'Ordenación',
    sortAscending: 'Orden ascendente',
    sortDescending: 'Orden descendente',
    addAscendingSort: 'Agregar orden ascendente',
    addDescendingSort: 'Agregar orden descendente',
    clearSort: 'Limpiar ordenación',
    clearAllSorts: 'Limpiar todas las ordenaciones',
    columnPinning: 'Fijación de columnas',
    pinLeft: 'Fijar a la izquierda',
    pinRight: 'Fijar a la derecha',
    unpin: 'Desfijar',
    unpinAllColumns: 'Desfijar todas las columnas',
    resetGridLayout: 'Restablecer diseño de la grilla',
    noActionsAvailable: 'No hay acciones disponibles',
    mainMenu: 'Menú principal',
    export: 'Exportar',
    exportTo: (formatLabel) => 'Exportar a $formatLabel',
    page: 'Página',
    of: 'de',
    noRangeFilter: 'Sin filtro de rango',
    rangeFrom: 'Desde',
    rangeTo: 'Hasta',
    searchHint: 'Buscar...',
    clearSearch: 'Limpiar búsqueda',
    caseSensitiveSearchOn: 'Búsqueda con distinción de mayúsculas activada',
    caseSensitiveSearchOff: 'Búsqueda sin distinción de mayúsculas',
    searchOptions: 'Opciones de búsqueda',
    searchAnyWord: 'Cualquier palabra',
    searchAllWords: 'Todas las palabras',
    searchExactPhrase: 'Frase exacta',
    firstPage: 'Primera página',
    previousPage: 'Página anterior',
    nextPage: 'Página siguiente',
    lastPage: 'Última página',
    selected: (count) => '$count seleccionados',
    valueOf: (value, maximum) => '$value de $maximum',
    rating: 'Valoración',
    trendNoData: 'Tendencia: sin datos',
    trend: (points) => 'Tendencia: $points',
    browse: 'Vista',
    edit: 'Edición',
    insert: 'Inserción',
    closed: 'Cerrado',
    loading: 'Cargando',
    applyingUpdates: 'Aplicando cambios',
    openingDataset: 'Abriendo dataset',
    loadingDataset: 'Cargando dataset',
    filteringDataset: 'Filtrando dataset',
    searchingDataset: 'Buscando en dataset',
    sortingDataset: 'Ordenando dataset',
    datasetWork: 'Operación de dataset',
    aggregateSum: 'Suma',
    aggregateMin: 'Mín',
    aggregateMax: 'Máx',
    aggregateAvg: 'Promedio',
    state: 'Estado',
    filtered: 'Filtrado',
    sorted: 'Ordenado',
    noRecords: '0 registros',
    record: (recordNumber, totalCount) => totalCount == null
        ? 'Registro $recordNumber'
        : 'Registro $recordNumber de $totalCount',
    showSelectedRows: 'Mostrar filas seleccionadas',
    showUnselectedRows: 'Mostrar filas no seleccionadas',
    clearSelectionFilter: 'Limpiar filtro de selección',
    containsPhrase: 'Contiene frase',
    startsWith: 'Empieza con',
    operatorLabels: const FdcFilterOperatorTranslations(
      contains: 'Contiene',
      notContains: 'No contiene',
      equals: 'Igual a',
      notEquals: 'Distinto de',
      startsWith: 'Empieza con',
      endsWith: 'Termina con',
      greaterThan: 'Mayor que',
      greaterThanOrEqual: 'Mayor o igual',
      lessThan: 'Menor que',
      lessThanOrEqual: 'Menor o igual',
      between: 'Entre',
      inList: 'En la lista',
      notInList: 'No está en la lista',
      isNull: 'Es null',
      isNotNull: 'No es null',
      isEmpty: 'Está vacío',
      isNotEmpty: 'No está vacío',
      isNullOrWhitespace: 'Null o espacios',
      isNotNullOrWhitespace: 'No null ni espacios',
      isTrue: 'Sí',
      isFalse: 'No',
    ),
  ),
  validation: const FdcValidationTranslations(
    validationError: 'Error de validación',
    enterValidInteger: 'Introduzca un entero válido',
    enterValidDecimal: 'Introduzca un número decimal válido',
    decimalPrecisionExceeded: _esDecimalPrecisionExceeded,
    validationFailed: 'La validación falló.',
    lookupFailed: 'La búsqueda falló.',
    dataOperationError: 'Error de operación de datos',
    dataSetError: 'Error de dataset',
    error: 'Error',
    requiredValue: 'Obligatorio',
    invalidValue: 'Valor no válido',
    requiredField: _esRequiredField,
    invalidNumericField: _esInvalidNumericField,
    minValueField: _esMinValueField,
    maxValueField: _esMaxValueField,
  ),
);

String _esDecimalPrecisionExceeded(int? precision, int? scale) {
  if (precision == null || scale == null) {
    return 'El valor decimal supera la precisión permitida.';
  }
  return 'El valor decimal supera la precisión $precision y la escala $scale.';
}

String _esRequiredField(String fieldLabel) =>
    'El campo $fieldLabel es obligatorio.';

String _esInvalidNumericField(String fieldLabel) =>
    'El campo $fieldLabel contiene un valor numérico no válido.';

String _esMinValueField(String fieldLabel, Object limit) =>
    'El campo $fieldLabel debe ser mayor o igual que $limit.';

String _esMaxValueField(String fieldLabel, Object limit) =>
    'El campo $fieldLabel debe ser menor o igual que $limit.';
