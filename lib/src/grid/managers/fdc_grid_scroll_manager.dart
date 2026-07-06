// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/widgets.dart';

enum _FdcVerticalScrollOrigin { none, pointerWheel, drag }

class FdcGridScrollManager {
  Timer? _verticalSnapTimer;
  Timer? _horizontalSnapTimer;
  Timer? _verticalScrollOriginTimer;
  bool _snappingRows = false;
  bool _snappingColumns = false;
  _FdcVerticalScrollOrigin _verticalScrollOrigin =
      _FdcVerticalScrollOrigin.none;

  bool get snappingRows => _snappingRows;

  bool get snappingColumns => _snappingColumns;

  bool get verticalPointerWheelActive =>
      _verticalScrollOrigin == _FdcVerticalScrollOrigin.pointerWheel;

  bool get verticalDragActive =>
      _verticalScrollOrigin == _FdcVerticalScrollOrigin.drag;

  void markVerticalPointerWheel() {
    _setVerticalScrollOrigin(_FdcVerticalScrollOrigin.pointerWheel);
    _scheduleVerticalOriginReset();
  }

  void markVerticalDrag() {
    if (verticalPointerWheelActive) {
      return;
    }
    _setVerticalScrollOrigin(_FdcVerticalScrollOrigin.drag);
    _verticalScrollOriginTimer?.cancel();
    _verticalScrollOriginTimer = null;
  }

  void clearVerticalScrollOrigin() {
    _verticalScrollOriginTimer?.cancel();
    _verticalScrollOriginTimer = null;
    _setVerticalScrollOrigin(_FdcVerticalScrollOrigin.none);
  }

  void _setVerticalScrollOrigin(_FdcVerticalScrollOrigin origin) {
    _verticalScrollOrigin = origin;
  }

  void _scheduleVerticalOriginReset() {
    _verticalScrollOriginTimer?.cancel();
    _verticalScrollOriginTimer = Timer(const Duration(milliseconds: 180), () {
      _setVerticalScrollOrigin(_FdcVerticalScrollOrigin.none);
    });
  }

  void scheduleVerticalSnap(VoidCallback callback) {
    _verticalSnapTimer?.cancel();
    _verticalSnapTimer = Timer(const Duration(milliseconds: 120), callback);
  }

  void cancelVerticalSnap() {
    _verticalSnapTimer?.cancel();
    _verticalSnapTimer = null;
  }

  void scheduleHorizontalSnap(VoidCallback callback) {
    _horizontalSnapTimer?.cancel();
    _horizontalSnapTimer = Timer(const Duration(milliseconds: 120), callback);
  }

  void cancelHorizontalSnap() {
    _horizontalSnapTimer?.cancel();
    _horizontalSnapTimer = null;
  }

  void runRowSnap(VoidCallback callback) {
    _snappingRows = true;
    try {
      callback();
    } finally {
      _snappingRows = false;
    }
  }

  void runColumnSnap(VoidCallback callback) {
    _snappingColumns = true;
    try {
      callback();
    } finally {
      _snappingColumns = false;
    }
  }

  void dispose() {
    _verticalSnapTimer?.cancel();
    _horizontalSnapTimer?.cancel();
    _verticalScrollOriginTimer?.cancel();
  }
}
