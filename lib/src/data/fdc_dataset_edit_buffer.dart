// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_dataset_state.dart';
import 'fdc_record.dart';

/// Internal holder for the active edit/insert buffer state.
///
/// The dataset owns lifecycle orchestration, while this object keeps the
/// mutable buffer bookkeeping in one place so edit/insert/delete code does not
/// have to manually maintain several parallel fields.
class FdcDataSetEditBuffer {
  int? editRecordId;
  List<Object?>? buffer;
  List<Object?>? startValues;
  FdcRecordState? startRecordState;
  int? insertRecordId;
  bool modifiedByUser = false;
  bool suppressUserTracking = false;

  bool get isActive => editRecordId != null && buffer != null;

  bool isEditingRecord(FdcRecord record) =>
      editRecordId == record.id && buffer != null;

  bool get isActiveInsertBufferUnmodified =>
      insertRecordId != null &&
      editRecordId == insertRecordId &&
      !modifiedByUser;

  void begin(FdcRecord record, {required bool insertRecord}) {
    final snapshot = record.valuesSnapshot();
    editRecordId = record.id;
    buffer = List<Object?>.of(snapshot);
    startValues = List<Object?>.of(snapshot);
    startRecordState = record.state;
    insertRecordId = insertRecord ? record.id : null;
    modifiedByUser = false;
    suppressUserTracking = false;
  }

  void clear() {
    editRecordId = null;
    buffer = null;
    startValues = null;
    startRecordState = null;
    insertRecordId = null;
    modifiedByUser = false;
    suppressUserTracking = false;
  }
}
