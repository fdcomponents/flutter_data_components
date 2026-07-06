// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

/// Internal field-name normalization helpers.
///
/// FDC field identities are case-insensitive, matching the database-style
/// schema model. The original field name casing is still preserved on
/// `FdcFieldDef.name` and in exported row maps.
class FdcFieldName {
  const FdcFieldName._();

  static String normalize(String fieldName) => fieldName.toLowerCase();

  static Object? valueFromRow(
    Map<String, Object?> row,
    String fieldName, {
    required Object? defaultValue,
  }) {
    final expectedFieldName = normalize(fieldName);
    var found = false;
    Object? value;
    String? firstKey;

    for (final entry in row.entries) {
      if (normalize(entry.key) != expectedFieldName) {
        continue;
      }
      if (found) {
        throw ArgumentError.value(
          entry.key,
          'row',
          'Duplicate row field name differing only by case: "$firstKey" and "${entry.key}".',
        );
      }
      found = true;
      firstKey = entry.key;
      value = entry.value;
    }

    return found ? value : defaultValue;
  }
}
