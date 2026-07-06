// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_control_theme.dart';
import 'fdc_grid_header_metrics.dart';

class FdcGridRowIndicatorCell extends StatelessWidget {
  const FdcGridRowIndicatorCell({
    super.key,
    required this.model,
    required this.onTap,
    required this.onSelectedChanged,
  });

  final FdcGridRowIndicatorCellModel model;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    final options = model.options;
    final indicatorColor = FdcGridControlTheme.iconColor(
      context,
      model.controlsStyle,
      active: true,
    );
    final baseRowNumberStyle =
        model.textStyle ?? DefaultTextStyle.of(context).style;
    final rowNumberStyle = baseRowNumberStyle.copyWith(
      color: indicatorColor,
      fontSize: baseRowNumberStyle.fontSize == null
          ? null
          : baseRowNumberStyle.fontSize! - 2,
    );
    final statusWidth = FdcGridHeaderMetrics.rowIndicatorStatusSlotWidth(
      showRecordStatus: options.showRecordStatus,
      showRowSelect: options.showRowSelect,
      showRowNumbers: options.showRowNumbers,
    );
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : FdcGridHeaderMetrics.rowIndicatorCheckboxSize;
          final rowChildren = <Widget>[
            if (options.showRecordStatus)
              _statusIndicatorTapTarget(
                context,
                width: statusWidth,
                height: slotHeight,
              ),
            if (options.showRowSelect)
              SizedBox(
                width: FdcGridHeaderMetrics.rowIndicatorSelectWidth,
                height: FdcGridHeaderMetrics.rowIndicatorCheckboxSize,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: SizedBox(
                      width: FdcGridHeaderMetrics.rowIndicatorCheckboxSize,
                      height: FdcGridHeaderMetrics.rowIndicatorCheckboxSize,
                      child: Checkbox(
                        key: model.recordId == null
                            ? null
                            : ValueKey<int>(model.recordId!),
                        value: model.selected,
                        fillColor: FdcGridControlTheme.checkboxFillColor(
                          model.controlsStyle,
                        ),
                        checkColor: FdcGridControlTheme.checkboxCheckColor(
                          context,
                          model.controlsStyle,
                          enabled: model.selectionEnabled,
                        ),
                        side: FdcGridControlTheme.checkboxSide(
                          context,
                          model.controlsStyle,
                          enabled: model.selectionEnabled,
                        ),
                        onChanged: model.selectionEnabled
                            ? (value) => onSelectedChanged(value == true)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
          ];

          if (options.showRowNumbers) {
            rowChildren.add(
              Expanded(
                child: _indicatorTapTarget(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${model.rowNumber}',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: rowNumberStyle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          if (rowChildren.isEmpty) {
            rowChildren.add(
              Expanded(
                child: _indicatorTapTarget(child: const SizedBox.expand()),
              ),
            );
          }

          final row = Row(
            mainAxisSize: options.showRowNumbers
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: rowChildren,
          );

          return options.showRowNumbers
              ? row
              : Align(alignment: Alignment.centerLeft, child: row);
        },
      ),
    );
  }

  Widget _indicatorTapTarget({double? width, required Widget child}) {
    final content = SizedBox(
      width: width,
      height: FdcGridHeaderMetrics.rowIndicatorCheckboxSize,
      child: child,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }

  Widget _statusIndicatorTapTarget(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        key: const ValueKey<String>('fdc-grid-row-indicator-status-slot'),
        width: width,
        height: height,
        child: Center(
          child: SizedBox.square(
            key: const ValueKey<String>(
              'fdc-grid-row-indicator-status-icon-box',
            ),
            dimension: FdcGridHeaderMetrics.rowIndicatorStatusIconSize,
            child: Transform.translate(
              offset: Offset(_statusIconHorizontalOffset(), 0),
              child: Center(child: _statusIcon(context)),
            ),
          ),
        ),
      ),
    );
  }

  double _statusIconHorizontalOffset() {
    final options = model.options;
    if (!options.showRecordStatus) {
      return 0.0;
    }

    return options.showRowSelect || options.showRowNumbers
        ? FdcGridHeaderMetrics.rowIndicatorCompositeStatusIconOffset
        : 0.0;
  }

  Widget _statusIcon(BuildContext context) {
    final status = model.status;
    if (status == null) {
      return const SizedBox.shrink();
    }

    final visualStatus = status == FdcGridRowIndicatorStatus.modified
        ? FdcGridRowIndicatorStatus.edit
        : status;

    final icon = switch (visualStatus) {
      FdcGridRowIndicatorStatus.browse => Icons.arrow_right,
      FdcGridRowIndicatorStatus.edit => Icons.edit_outlined,
      FdcGridRowIndicatorStatus.modified => Icons.edit_outlined,
      FdcGridRowIndicatorStatus.insert => Icons.add,
    };

    final color = switch (visualStatus) {
      FdcGridRowIndicatorStatus.browse => FdcGridControlTheme.iconColor(
        context,
        model.controlsStyle,
        active: true,
      ),
      FdcGridRowIndicatorStatus.edit => FdcGridControlTheme.iconColor(
        context,
        model.controlsStyle,
        active: true,
      ),
      FdcGridRowIndicatorStatus.modified => FdcGridControlTheme.iconColor(
        context,
        model.controlsStyle,
        active: true,
      ),
      FdcGridRowIndicatorStatus.insert => FdcGridControlTheme.iconColor(
        context,
        model.controlsStyle,
        active: true,
      ),
    };

    final translations = FdcApp.translationsOf(context).grid;
    final tooltip = switch (visualStatus) {
      FdcGridRowIndicatorStatus.browse => translations.browse,
      FdcGridRowIndicatorStatus.edit => translations.edit,
      FdcGridRowIndicatorStatus.modified => translations.edit,
      FdcGridRowIndicatorStatus.insert => translations.insert,
    };

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: Icon(
        icon,
        size: FdcGridHeaderMetrics.rowIndicatorStatusIconSize,
        color: color,
      ),
    );
  }
}
