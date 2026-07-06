// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/widgets/counter/fdc_counter_style.dart';

/// Built-in editor kinds supported by the standalone editor descriptor model.
enum FdcEditorKind {
  /// Single-line text editor.
  text,

  /// Integer number editor.
  integer,

  /// Decimal number editor.
  decimal,

  /// Date-only editor.
  date,

  /// Combined date and time editor.
  dateTime,

  /// Time-only editor.
  time,

  /// Multi-line text editor.
  memo,
}

/// Base descriptor for standalone editors and data-aware editor bindings.
abstract class FdcEditorDescriptor<T> {
  /// Creates a base editor descriptor.
  const FdcEditorDescriptor({
    this.fieldName = '',
    this.label,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.focusOrder,
    this.tabStop = true,
  });

  /// Dataset field name associated with the editor.
  final String fieldName;

  /// Optional user-facing label.
  final String? label;

  /// Optional user-facing input hint.
  final String? hint;

  /// Whether the editor is enabled.
  final bool enabled;

  /// Whether the editor prevents user edits.
  final bool readOnly;

  /// Whether the editor requires a non-empty value.
  final bool required;

  /// Optional traversal order used by focus traversal.
  final int? focusOrder;

  /// Whether the editor participates in keyboard tab traversal.
  final bool tabStop;

  /// Concrete editor kind used by the renderer and value codec.
  FdcEditorKind get editType;
}

/// Descriptor for a single-line text editor.
class FdcTextEditorDescriptor<T> extends FdcEditorDescriptor<T> {
  /// Creates a [FdcTextEditorDescriptor].
  const FdcTextEditorDescriptor({
    super.fieldName,
    super.label,
    super.hint,
    super.enabled,
    super.readOnly,
    super.required,
    super.focusOrder,
    super.tabStop,
    this.maxLength,
    this.showCounter = false,
    this.counterStyle = const FdcCounterStyle(),
  });

  /// Maximum number of characters accepted by the editor.
  final int? maxLength;

  /// Whether to show the character counter.
  final bool showCounter;

  /// Visual style used by the character counter.
  final FdcCounterStyle counterStyle;

  @override
  FdcEditorKind get editType => FdcEditorKind.text;
}

/// Descriptor for a multi-line memo editor.
class FdcMemoEditorDescriptor<T> extends FdcTextEditorDescriptor<T> {
  /// Creates a [FdcMemoEditorDescriptor].
  const FdcMemoEditorDescriptor({
    super.fieldName,
    super.label,
    super.hint,
    super.enabled,
    super.readOnly,
    super.required,
    super.focusOrder,
    super.tabStop,
    super.maxLength,
    super.showCounter,
    super.counterStyle,
  });

  @override
  FdcEditorKind get editType => FdcEditorKind.memo;
}

/// Descriptor for an integer editor.
class FdcIntegerEditorDescriptor<T> extends FdcEditorDescriptor<T> {
  /// Creates a [FdcIntegerEditorDescriptor].
  const FdcIntegerEditorDescriptor({
    super.fieldName,
    super.label,
    super.hint,
    super.enabled,
    super.readOnly,
    super.required,
    super.focusOrder,
    super.tabStop,
    this.allowNegative = true,
  });

  /// Whether negative values are accepted.
  final bool allowNegative;

  @override
  FdcEditorKind get editType => FdcEditorKind.integer;
}

/// Descriptor for a decimal number editor.
class FdcDecimalEditorDescriptor<T> extends FdcEditorDescriptor<T> {
  /// Creates a [FdcDecimalEditorDescriptor].
  const FdcDecimalEditorDescriptor({
    super.fieldName,
    super.label,
    super.hint,
    super.enabled,
    super.readOnly,
    super.required,
    super.focusOrder,
    super.tabStop,
    this.allowNegative = true,
    this.precision,
    this.scale,
  });

  /// Whether negative values are accepted.
  final bool allowNegative;

  /// Maximum total number of digits accepted by the editor.
  final int? precision;

  /// Maximum number of fractional digits accepted by the editor.
  final int? scale;

  @override
  FdcEditorKind get editType => FdcEditorKind.decimal;
}

/// Descriptor for a date-only editor.
class FdcDateEditorDescriptor<T> extends FdcEditorDescriptor<T> {
  /// Creates a [FdcDateEditorDescriptor].
  const FdcDateEditorDescriptor({
    super.fieldName,
    super.label,
    super.hint,
    super.enabled,
    super.readOnly,
    super.required,
    super.focusOrder,
    super.tabStop,
    this.showPicker = true,
  });

  /// Whether to show a picker button next to the editor.
  final bool showPicker;

  @override
  FdcEditorKind get editType => FdcEditorKind.date;
}

/// Descriptor for a combined date and time editor.
class FdcDateTimeEditorDescriptor<T> extends FdcEditorDescriptor<T> {
  /// Creates a [FdcDateTimeEditorDescriptor].
  const FdcDateTimeEditorDescriptor({
    super.fieldName,
    super.label,
    super.hint,
    super.enabled,
    super.readOnly,
    super.required,
    super.focusOrder,
    super.tabStop,
    this.showPicker = true,
  });

  /// Whether to show a picker button next to the editor.
  final bool showPicker;

  @override
  FdcEditorKind get editType => FdcEditorKind.dateTime;
}

/// Descriptor for a time-only editor.
class FdcTimeEditorDescriptor<T> extends FdcEditorDescriptor<T> {
  /// Creates a [FdcTimeEditorDescriptor].
  const FdcTimeEditorDescriptor({
    super.fieldName,
    super.label,
    super.hint,
    super.enabled,
    super.readOnly,
    super.required,
    super.focusOrder,
    super.tabStop,
    this.showPicker = false,
  });

  /// Whether to show a picker button next to the editor.
  final bool showPicker;

  @override
  FdcEditorKind get editType => FdcEditorKind.time;
}

/// Convenience accessors shared by editor descriptors.
extension FdcEditorDescriptorDetails<T> on FdcEditorDescriptor<T> {
  /// Maximum text length for text-like descriptors, otherwise null.
  int? get maxLength => switch (this) {
    final FdcTextEditorDescriptor<T> descriptor => descriptor.maxLength,
    _ => null,
  };

  /// Whether a text-like descriptor displays a character counter.
  bool get showCounter => switch (this) {
    final FdcTextEditorDescriptor<T> descriptor => descriptor.showCounter,
    _ => false,
  };

  /// Character counter style for text-like descriptors.
  FdcCounterStyle get counterStyle => switch (this) {
    final FdcTextEditorDescriptor<T> descriptor => descriptor.counterStyle,
    _ => const FdcCounterStyle(),
  };

  /// Whether the descriptor accepts negative numeric values.
  bool get allowNegative => switch (this) {
    final FdcIntegerEditorDescriptor<T> field => field.allowNegative,
    final FdcDecimalEditorDescriptor<T> field => field.allowNegative,
    _ => true,
  };

  /// Decimal precision for decimal descriptors, otherwise null.
  int? get precision => switch (this) {
    final FdcDecimalEditorDescriptor<T> descriptor => descriptor.precision,
    _ => null,
  };

  /// Decimal scale for decimal descriptors, otherwise null.
  int? get scale => switch (this) {
    final FdcDecimalEditorDescriptor<T> descriptor => descriptor.scale,
    _ => null,
  };

  /// Whether a picker button should be shown for picker-capable descriptors.
  bool get showPicker => switch (this) {
    final FdcDateEditorDescriptor<T> field => field.showPicker,
    final FdcDateTimeEditorDescriptor<T> field => field.showPicker,
    final FdcTimeEditorDescriptor<T> field => field.showPicker,
    _ => true,
  };
}
