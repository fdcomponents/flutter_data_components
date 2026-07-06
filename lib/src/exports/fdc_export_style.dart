// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_export_format.dart';

/// Base type for format-specific visual export styles.
///
/// Styles are presentation defaults, distinct from writer-specific options,
/// which control writer behavior and format-specific serialization settings.
abstract class FdcExportFormatStyle {
  /// Creates a [FdcExportFormatStyle].
  const FdcExportFormatStyle();
}

/// App- or subtree-level default styles resolved by export writers.
///
/// Explicit per-export styles always take precedence over these defaults.
final class FdcExportStyle {
  /// Creates a [FdcExportStyle].
  const FdcExportStyle({
    this.pdf,
    this.formats = const <FdcExportFormat, FdcExportFormatStyle>{},
  });

  /// Default style for writers whose format id is `pdf`.
  final FdcExportFormatStyle? pdf;

  /// Default styles keyed by custom or additional export formats.
  final Map<FdcExportFormat, FdcExportFormatStyle> formats;

  /// Returns the style registered for [format], when it matches [T].
  T? styleFor<T extends FdcExportFormatStyle>(FdcExportFormat format) {
    final direct = format.id == 'pdf' ? pdf : null;
    if (direct is T) {
      return direct;
    }
    final style = formats[format];
    return style is T ? style : null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! FdcExportStyle ||
        pdf != other.pdf ||
        formats.length != other.formats.length) {
      return false;
    }
    for (final entry in formats.entries) {
      if (other.formats[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    pdf,
    Object.hashAllUnordered(
      formats.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}
