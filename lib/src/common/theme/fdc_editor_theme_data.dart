// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../widgets/counter/fdc_counter_style.dart';
import 'fdc_editor_styles.dart';

/// Complete visual theme for standalone FDC editors.
///
/// The theme groups text input, control chrome, and combo-popup styles so they
/// can be inherited as one unit and selectively overridden per editor.
class FdcEditorThemeData {
  /// Creates a [FdcEditorThemeData].
  const FdcEditorThemeData({
    this.input = const FdcEditorInputStyle(),
    this.controls = const FdcEditorControlsStyle(),
    this.comboPopup = const FdcEditorComboPopupStyle(),
    this.counter = const FdcCounterStyle(),
  });

  /// Style applied to text-like editor inputs.
  final FdcEditorInputStyle input;

  /// Style applied to boolean controls and combo editor chrome.
  final FdcEditorControlsStyle controls;

  /// Style applied to combo popup, search field, and option rows.
  final FdcEditorComboPopupStyle comboPopup;

  /// Style applied to optional text-length counters.
  final FdcCounterStyle counter;

  /// Creates a copy with selected values replaced.
  FdcEditorThemeData copyWith({
    FdcEditorInputStyle? input,
    FdcEditorControlsStyle? controls,
    FdcEditorComboPopupStyle? comboPopup,
    FdcCounterStyle? counter,
  }) {
    return FdcEditorThemeData(
      input: input ?? this.input,
      controls: controls ?? this.controls,
      comboPopup: comboPopup ?? this.comboPopup,
      counter: counter ?? this.counter,
    );
  }

  /// Merges [override] section-by-section over this theme data.
  FdcEditorThemeData merge(FdcEditorThemeData? override) {
    if (override == null) {
      return this;
    }

    return FdcEditorThemeData(
      input: input.merge(override.input),
      controls: controls.merge(override.controls),
      comboPopup: comboPopup.merge(override.comboPopup),
      counter: counter.merge(override.counter),
    );
  }

  /// Linearly interpolates this theme toward [other] by [t].
  FdcEditorThemeData lerp(FdcEditorThemeData other, double t) {
    return FdcEditorThemeData(
      input: input.lerp(other.input, t),
      controls: controls.lerp(other.controls, t),
      comboPopup: comboPopup.lerp(other.comboPopup, t),
      counter: counter.lerp(other.counter, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcEditorThemeData &&
            input == other.input &&
            controls == other.controls &&
            comboPopup == other.comboPopup &&
            counter == other.counter;
  }

  @override
  int get hashCode => Object.hash(input, controls, comboPopup, counter);
}
