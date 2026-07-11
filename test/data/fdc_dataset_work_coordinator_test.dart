import 'dart:async';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/internal/fdc_dataset_work_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FdcDataSetWorkCoordinator createCoordinator() {
    return FdcDataSetWorkCoordinator(
      captureLifecycleGeneration: () => 0,
      isLifecycleCurrent: (_) => true,
      onStarted: (_) {},
      onCompleted: (_) {},
      onError: (_, _, _) {},
    );
  }

  test('waitUntilIdle completes after active async work completes', () async {
    final coordinator = createCoordinator();
    final release = Completer<void>();
    var idleCompleted = false;

    final workFuture = coordinator.runAsync<void>(
      phase: FdcDataSetWorkPhase.open,
      body: () => release.future,
    );
    final idleFuture = coordinator.waitUntilIdle().then((_) {
      idleCompleted = true;
    });

    await Future<void>.value();
    expect(idleCompleted, isFalse);

    release.complete();
    await workFuture;
    await idleFuture;

    expect(idleCompleted, isTrue);
    expect(coordinator.work.isWorking, isFalse);
  });

  test('waitUntilIdle completes after active work fails', () async {
    final coordinator = createCoordinator();
    final release = Completer<void>();

    final workFuture = coordinator.runAsync<void>(
      phase: FdcDataSetWorkPhase.open,
      body: () async {
        await release.future;
        throw StateError('failed');
      },
    );
    final idleFuture = coordinator.waitUntilIdle();

    release.complete();
    await expectLater(workFuture, throwsStateError);
    await idleFuture;

    expect(coordinator.work.isWorking, isFalse);
  });

  test('waitUntilIdle completes when coordinator is disposed', () async {
    var lifecycleCurrent = true;
    final coordinator = FdcDataSetWorkCoordinator(
      captureLifecycleGeneration: () => 0,
      isLifecycleCurrent: (_) => lifecycleCurrent,
      onStarted: (_) {},
      onCompleted: (_) {},
      onError: (_, _, _) {},
    );
    final release = Completer<void>();
    final workFuture = coordinator.runAsync<void>(
      phase: FdcDataSetWorkPhase.open,
      body: () => release.future,
    );
    final idleFuture = coordinator.waitUntilIdle();

    lifecycleCurrent = false;
    coordinator.dispose();
    await idleFuture;
    release.complete();
    await workFuture;
  });
}
