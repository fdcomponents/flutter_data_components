// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../core/fdc_grid_runtime_constants.dart';
import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_header_cell.dart';

class FdcGridHeaderShell extends StatelessWidget {
  const FdcGridHeaderShell({
    super.key,
    required this.model,
    required this.callbacks,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final contentWidth = model.contentWidth;

    return Container(
      width: contentWidth,
      height: model.height,
      decoration: BoxDecoration(color: model.headerBackgroundColor),
      child: SizedBox(
        width: contentWidth,
        height: model.height,
        child: Stack(
          children: [
            if (model.hasColumnGroups)
              for (final groupCell in model.columnGroupCells)
                Positioned(
                  key: ValueKey<String>(
                    'fdc-grid-column-group-${groupCell.startLocalColumnIndex}-${groupCell.columnSpan}',
                  ),
                  left: groupCell.left,
                  top: 0,
                  width: groupCell.width,
                  height: model.groupHeaderHeight,
                  child: FdcGridHeaderResizeHandle(
                    model: model,
                    callbacks: callbacks,
                    localColumnIndex: groupCell.trailingLocalColumnIndex,
                    separatorHeight: model.groupHeaderHeight,
                    separatorColor:
                        groupCell.style.verticalSeparatorColor ??
                        model.groupHeaderVerticalSeparatorColor,
                    separatorTopInset:
                        groupCell.style.verticalSeparatorInset ??
                        model.groupHeaderSeparatorTopInset,
                    separatorBottomInset:
                        groupCell.style.verticalSeparatorInset ??
                        model.groupHeaderSeparatorBottomInset,
                    allowResizeHandle:
                        !model.suppressTrailingSeparatorAt(
                          groupCell.trailingLocalColumnIndex,
                        ) &&
                        groupCell.trailingLocalColumnIndex ==
                            groupCell.resizeStartLocalColumnIndex +
                                groupCell.resizeColumnSpan -
                                1,
                    groupResizeColumnIndexes: model.sourceColumnIndexesInRange(
                      groupCell.resizeStartLocalColumnIndex,
                      groupCell.resizeColumnSpan,
                    ),
                    groupResizeRuntimeColumnIds: model.runtimeColumnIdsInRange(
                      groupCell.resizeStartLocalColumnIndex,
                      groupCell.resizeColumnSpan,
                    ),
                    child: FdcGridColumnGroupHeaderCell(
                      model: model,
                      groupCell: groupCell,
                    ),
                  ),
                ),
            for (final geometry in model.geometries)
              AnimatedPositioned(
                key: ValueKey<Object?>(
                  'fdc-grid-header-cell-${geometry.runtimeColumnId}',
                ),
                duration: model.draggingColumnIndex == null
                    ? Duration.zero
                    : fdcGridColumnReorderAnimationDuration,
                curve: Curves.easeOutCubic,
                left: geometry.offset,
                top: model.hasColumnGroups ? model.groupHeaderHeight : 0.0,
                width: geometry.width,
                height: model.leafHeaderHeight,
                child: ColoredBox(
                  key: ValueKey<String>(
                    'fdc-grid-header-field-${geometry.column.fieldName}',
                  ),
                  color: model.headerBackgroundColor,
                  child: FdcGridHeaderCell(
                    model: model,
                    callbacks: callbacks,
                    column: geometry.column,
                    localColumnIndex: geometry.localColumnIndex,
                    columnIndex: geometry.sourceColumnIndex,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FdcGridColumnGroupHeaderCell extends StatelessWidget {
  const FdcGridColumnGroupHeaderCell({
    super.key,
    required this.model,
    required this.groupCell,
  });

  final FdcGridHeaderModel model;
  final FdcGridColumnGroupCell groupCell;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            groupCell.style.backgroundColor ?? model.groupHeaderBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color:
                groupCell.style.bottomSeparatorColor ??
                model.groupHeaderBottomSeparatorColor,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: groupCell.labelLeftOffset,
            top: 0,
            bottom: 0,
            width: groupCell.labelWidth,
            child: Align(
              alignment:
                  groupCell.style.alignment ?? model.groupHeaderAlignment,
              child: Padding(
                padding: groupCell.style.padding ?? model.groupHeaderPadding,
                child: Text(
                  groupCell.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style:
                      groupCell.style.textStyle ?? model.groupHeaderTextStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
