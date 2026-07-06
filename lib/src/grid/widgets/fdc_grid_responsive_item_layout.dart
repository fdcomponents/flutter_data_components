// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'fdc_grid_items.dart';

/// Responsive three-zone layout shared by the grid toolbar and status bar.
///
/// Items are measured at their natural width. When the host becomes too
/// narrow, center items disappear first, followed by end items and finally
/// start items. Items are removed from the edge facing the center so the
/// outer anchors remain stable while the grid is resized.
class FdcGridResponsiveItemLayout extends MultiChildRenderObjectWidget {
  FdcGridResponsiveItemLayout({
    super.key,
    required List<Widget> startItems,
    required List<Widget> centerItems,
    required List<Widget> endItems,
  }) : super(
         children: <Widget>[
           for (var i = 0; i < startItems.length; i++)
             _FdcGridResponsiveItem(
               placement: FdcGridItemPlacement.start,
               order: i,
               child: startItems[i],
             ),
           for (var i = 0; i < centerItems.length; i++)
             _FdcGridResponsiveItem(
               placement: FdcGridItemPlacement.center,
               order: i,
               child: centerItems[i],
             ),
           for (var i = 0; i < endItems.length; i++)
             _FdcGridResponsiveItem(
               placement: FdcGridItemPlacement.end,
               order: i,
               child: endItems[i],
             ),
         ],
       );

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFdcGridResponsiveItemLayout(
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderFdcGridResponsiveItemLayout).textDirection =
        Directionality.of(context);
  }
}

class _FdcGridResponsiveItem
    extends ParentDataWidget<_FdcGridResponsiveItemParentData> {
  const _FdcGridResponsiveItem({
    required this.placement,
    required this.order,
    required super.child,
  });

  final FdcGridItemPlacement placement;
  final int order;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData;
    if (parentData is! _FdcGridResponsiveItemParentData) return;
    var needsLayout = false;
    if (parentData.placement != placement) {
      parentData.placement = placement;
      needsLayout = true;
    }
    if (parentData.order != order) {
      parentData.order = order;
      needsLayout = true;
    }
    if (needsLayout) {
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => FdcGridResponsiveItemLayout;
}

class _FdcGridResponsiveItemParentData
    extends ContainerBoxParentData<RenderBox> {
  FdcGridItemPlacement placement = FdcGridItemPlacement.end;
  int order = 0;
  bool visible = false;
}

class _RenderFdcGridResponsiveItemLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FdcGridResponsiveItemParentData>,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          _FdcGridResponsiveItemParentData
        > {
  _RenderFdcGridResponsiveItemLayout({required TextDirection textDirection})
    : _textDirection = textDirection;

  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FdcGridResponsiveItemParentData) {
      child.parentData = _FdcGridResponsiveItemParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    var width = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      width += child.getMaxIntrinsicWidth(height);
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    var height = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      height = height < child.getMaxIntrinsicHeight(width)
          ? child.getMaxIntrinsicHeight(width)
          : height;
      child = childAfter(child);
    }
    return height;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final childConstraints = BoxConstraints(
      maxHeight: constraints.hasBoundedHeight
          ? constraints.maxHeight
          : double.infinity,
    );
    var naturalWidth = 0.0;
    var naturalHeight = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      final childSize = child.getDryLayout(childConstraints);
      naturalWidth += childSize.width;
      naturalHeight = naturalHeight < childSize.height
          ? childSize.height
          : naturalHeight;
      child = childAfter(child);
    }
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : naturalWidth;
    return constraints.constrain(Size(width, naturalHeight));
  }

  @override
  void performLayout() {
    final boundedWidth = constraints.hasBoundedWidth;
    final childConstraints = BoxConstraints(
      maxHeight: constraints.hasBoundedHeight
          ? constraints.maxHeight
          : double.infinity,
    );

    final start = <RenderBox>[];
    final center = <RenderBox>[];
    final end = <RenderBox>[];
    var naturalHeight = 0.0;

    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      final data = child.parentData! as _FdcGridResponsiveItemParentData;
      data.visible = false;
      naturalHeight = naturalHeight < child.size.height
          ? child.size.height
          : naturalHeight;
      switch (data.placement) {
        case FdcGridItemPlacement.start:
          start.add(child);
          break;
        case FdcGridItemPlacement.center:
          center.add(child);
          break;
        case FdcGridItemPlacement.end:
          end.add(child);
          break;
      }
      child = data.nextSibling;
    }

    int orderOf(RenderBox box) =>
        (box.parentData! as _FdcGridResponsiveItemParentData).order;
    start.sort((a, b) => orderOf(a).compareTo(orderOf(b)));
    center.sort((a, b) => orderOf(a).compareTo(orderOf(b)));
    end.sort((a, b) => orderOf(a).compareTo(orderOf(b)));

    double totalWidth(List<RenderBox> boxes) =>
        boxes.fold<double>(0, (sum, box) => sum + box.size.width);

    final naturalWidth =
        totalWidth(start) + totalWidth(center) + totalWidth(end);
    final maxWidth = boundedWidth ? constraints.maxWidth : naturalWidth;
    final visibleStart = List<RenderBox>.of(start);
    final visibleEnd = List<RenderBox>.of(end);

    while (totalWidth(visibleStart) + totalWidth(visibleEnd) > maxWidth &&
        visibleEnd.isNotEmpty) {
      visibleEnd.removeAt(0);
    }
    while (totalWidth(visibleStart) + totalWidth(visibleEnd) > maxWidth &&
        visibleStart.isNotEmpty) {
      visibleStart.removeLast();
    }

    final startWidth = totalWidth(visibleStart);
    final endWidth = totalWidth(visibleEnd);
    final centerCapacity = maxWidth - startWidth - endWidth;
    final visibleCenter = <RenderBox>[];
    if (centerCapacity > 0) {
      for (final box in center) {
        if (totalWidth(visibleCenter) + box.size.width > centerCapacity) break;
        visibleCenter.add(box);
      }
    }

    size = constraints.constrain(Size(maxWidth, naturalHeight));
    final contentHeight = size.height;

    void markVisible(RenderBox box, double logicalX) {
      final data = box.parentData! as _FdcGridResponsiveItemParentData;
      data.visible = true;
      final physicalX = _textDirection == TextDirection.ltr
          ? logicalX
          : size.width - logicalX - box.size.width;
      data.offset = Offset(physicalX, (contentHeight - box.size.height) / 2);
    }

    var x = 0.0;
    for (final box in visibleStart) {
      markVisible(box, x);
      x += box.size.width;
    }

    x = size.width - endWidth;
    for (final box in visibleEnd) {
      markVisible(box, x);
      x += box.size.width;
    }

    final centerWidth = totalWidth(visibleCenter);
    final centeredX = (size.width - centerWidth) / 2;
    final minimumCenterX = startWidth;
    final maximumCenterX = size.width - endWidth - centerWidth;
    x = centeredX.clamp(minimumCenterX, maximumCenterX).toDouble();
    for (final box in visibleCenter) {
      markVisible(box, x);
      x += box.size.width;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final data = child.parentData! as _FdcGridResponsiveItemParentData;
      if (data.visible) {
        context.paintChild(child, offset + data.offset);
      }
      child = data.nextSibling;
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    RenderBox? child = firstChild;
    while (child != null) {
      final data = child.parentData! as _FdcGridResponsiveItemParentData;
      if (data.visible) visitor(child);
      child = data.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final data = child.parentData! as _FdcGridResponsiveItemParentData;
      if (data.visible) {
        final isHit = result.addWithPaintOffset(
          offset: data.offset,
          position: position,
          hitTest: (result, transformed) =>
              child!.hitTest(result, position: transformed),
        );
        if (isHit) return true;
      }
      child = data.previousSibling;
    }
    return false;
  }
}
