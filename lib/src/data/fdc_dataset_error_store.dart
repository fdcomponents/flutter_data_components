// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:collection';

import 'fdc_data_errors.dart';
import 'fdc_data_validation.dart';
import 'fdc_field_name.dart';

/// Internal storage and transformation helper for dataset errors.
class FdcDataSetErrorStore {
  FdcDataSetErrorStore() : this._(<FdcDataSetError>[]);

  FdcDataSetErrorStore._(List<FdcDataSetError> items)
    : _items = items,
      _unmodifiableItems = UnmodifiableListView<FdcDataSetError>(items);

  final List<FdcDataSetError> _items;
  final List<FdcDataSetError> _unmodifiableItems;
  Map<String, _FdcFieldErrorMessages> _fieldMessages =
      const <String, _FdcFieldErrorMessages>{};

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  List<FdcDataSetError> get items => _items;
  List<FdcDataSetError> get unmodifiable => _unmodifiableItems;

  String get message => _items.map((error) => error.message).join('\n');

  String? messageForField(String fieldName, {required int recordId}) {
    final messages = _fieldMessages[FdcFieldName.normalize(fieldName)];
    return messages?.forRecord(recordId);
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }
    _items.clear();
    _rebuildFieldMessageIndex();
  }

  void replace(
    List<FdcDataSetError> errors, {
    String? fallbackMessage,
    Object? cause,
  }) {
    _items
      ..clear()
      ..addAll(errors);

    if (_items.isEmpty &&
        fallbackMessage != null &&
        fallbackMessage.isNotEmpty) {
      _items.add(fdcDataSetError(message: fallbackMessage, cause: cause));
    }
    _rebuildFieldMessageIndex();
  }

  void addValidationErrors(List<FdcValidationError> validationErrors) {
    if (validationErrors.isEmpty) {
      return;
    }
    _items.addAll(<FdcDataSetError>[
      for (final error in validationErrors)
        fdcDataSetError(
          message: error.message,
          fieldName: error.fieldName,
          recordId: error.recordId,
          code: error.code,
        ),
    ]);
    _rebuildFieldMessageIndex();
  }

  bool clearForField(String fieldName, {int? recordId}) {
    final normalizedFieldName = FdcFieldName.normalize(fieldName);
    final before = _items.length;
    _items.removeWhere((error) {
      final errorFieldName = error.fieldName;
      if (errorFieldName == null ||
          FdcFieldName.normalize(errorFieldName) != normalizedFieldName) {
        return false;
      }
      if (recordId != null && error.recordId != recordId) {
        return false;
      }
      return true;
    });
    final changed = _items.length != before;
    if (changed) {
      _rebuildFieldMessageIndex();
    }
    return changed;
  }

  void _rebuildFieldMessageIndex() {
    if (_items.isEmpty) {
      _fieldMessages = const <String, _FdcFieldErrorMessages>{};
      return;
    }

    final builders = <String, _FdcFieldErrorMessagesBuilder>{};
    var order = 0;
    for (final error in _items) {
      final fieldName = error.fieldName;
      if (fieldName == null || error.message.isEmpty) {
        continue;
      }
      builders
          .putIfAbsent(
            FdcFieldName.normalize(fieldName),
            _FdcFieldErrorMessagesBuilder.new,
          )
          .add(error, order: order);
      order += 1;
    }

    _fieldMessages = <String, _FdcFieldErrorMessages>{
      for (final entry in builders.entries) entry.key: entry.value.build(),
    };
  }
}

final class _FdcFieldErrorMessagesBuilder {
  final List<_FdcOrderedErrorMessage> _globalMessages =
      <_FdcOrderedErrorMessage>[];
  final Map<int, List<_FdcOrderedErrorMessage>> _recordMessages =
      <int, List<_FdcOrderedErrorMessage>>{};

  void add(FdcDataSetError error, {required int order}) {
    final entry = _FdcOrderedErrorMessage(order, error.message);
    final recordId = error.recordId;
    if (recordId == null) {
      _globalMessages.add(entry);
      return;
    }
    _recordMessages
        .putIfAbsent(recordId, () => <_FdcOrderedErrorMessage>[])
        .add(entry);
  }

  _FdcFieldErrorMessages build() {
    if (_globalMessages.isEmpty) {
      return _FdcFieldErrorMessages(
        globalMessage: null,
        recordMessages: <int, String>{
          for (final entry in _recordMessages.entries)
            entry.key: entry.value.map((item) => item.message).join('\n'),
        },
      );
    }

    return _FdcFieldErrorMessages(
      globalMessage: _globalMessages.map((item) => item.message).join('\n'),
      recordMessages: const <int, String>{},
      orderedGlobalMessages: List<_FdcOrderedErrorMessage>.unmodifiable(
        _globalMessages,
      ),
      orderedRecordMessages: <int, List<_FdcOrderedErrorMessage>>{
        for (final entry in _recordMessages.entries)
          entry.key: List<_FdcOrderedErrorMessage>.unmodifiable(entry.value),
      },
    );
  }
}

final class _FdcOrderedErrorMessage {
  const _FdcOrderedErrorMessage(this.order, this.message);

  final int order;
  final String message;
}

final class _FdcFieldErrorMessages {
  _FdcFieldErrorMessages({
    required this.globalMessage,
    required this.recordMessages,
    this.orderedGlobalMessages = const <_FdcOrderedErrorMessage>[],
    this.orderedRecordMessages = const <int, List<_FdcOrderedErrorMessage>>{},
  });

  final String? globalMessage;
  final Map<int, String> recordMessages;
  final List<_FdcOrderedErrorMessage> orderedGlobalMessages;
  final Map<int, List<_FdcOrderedErrorMessage>> orderedRecordMessages;
  final Map<int, String> _mergedRecordMessageCache = <int, String>{};

  String? forRecord(int recordId) {
    final direct = recordMessages[recordId];
    if (direct != null) {
      return direct;
    }
    final recordEntries = orderedRecordMessages[recordId];
    if (recordEntries == null || recordEntries.isEmpty) {
      return globalMessage;
    }
    return _mergedRecordMessageCache.putIfAbsent(
      recordId,
      () => _mergeOrderedMessages(orderedGlobalMessages, recordEntries),
    );
  }

  static String _mergeOrderedMessages(
    List<_FdcOrderedErrorMessage> globalEntries,
    List<_FdcOrderedErrorMessage> recordEntries,
  ) {
    final messages = <String>[];
    var globalIndex = 0;
    var recordIndex = 0;
    while (globalIndex < globalEntries.length ||
        recordIndex < recordEntries.length) {
      final takeGlobal =
          recordIndex >= recordEntries.length ||
          (globalIndex < globalEntries.length &&
              globalEntries[globalIndex].order <
                  recordEntries[recordIndex].order);
      if (takeGlobal) {
        messages.add(globalEntries[globalIndex].message);
        globalIndex += 1;
      } else {
        messages.add(recordEntries[recordIndex].message);
        recordIndex += 1;
      }
    }
    return messages.join('\n');
  }
}
