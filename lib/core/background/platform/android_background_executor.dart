import 'dart:io';

import 'package:workmanager/workmanager.dart' as wm;

import '../background_constraints.dart';
import '../background_executor.dart';
import '../background_task.dart';

/// Android implementation of [BackgroundExecutor] using WorkManager.
///
/// This implementation supports:
/// - Periodic tasks (minimum 15 minutes)
/// - One-time tasks
/// - Execution constraints (network, battery)
/// - Tasks running when app is terminated
class AndroidBackgroundExecutor implements BackgroundExecutor {
  final Map<String, BackgroundTaskHandler> _handlers = {};
  bool _initialized = false;

  /// Static registry for task handlers (needed for isolate-based execution)
  static final Map<String, BackgroundTaskHandler> _staticHandlers = {};

  /// The callback dispatcher for WorkManager
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    wm.Workmanager().executeTask((taskName, inputData) async {
      final handler = _staticHandlers[taskName];
      if (handler == null) {
        return Future.value(false);
      }

      try {
        final task = BackgroundTask(
          taskId: taskName,
          name: taskName,
          inputData: inputData,
        );
        final result = await handler(task);
        return result.success;
      } catch (e) {
        return false;
      }
    });
  }

  @override
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AndroidBackgroundExecutor requires Android');
    }

    await wm.Workmanager().initialize(callbackDispatcher);

    _initialized = true;
  }

  @override
  void registerTask(String taskId, BackgroundTaskHandler handler) {
    _handlers[taskId] = handler;
    _staticHandlers[taskId] = handler;
  }

  @override
  void unregisterTask(String taskId) {
    _handlers.remove(taskId);
    _staticHandlers.remove(taskId);
  }

  @override
  Future<String?> scheduleOneTime(
    BackgroundTask task, {
    BackgroundConstraints? constraints,
    Duration? initialDelay,
  }) async {
    if (!_initialized) {
      throw StateError('BackgroundExecutor not initialized');
    }

    final uniqueName =
        '${task.taskId}_${DateTime.now().millisecondsSinceEpoch}';

    await wm.Workmanager().registerOneOffTask(
      uniqueName,
      task.taskId,
      inputData: task.inputData,
      initialDelay: initialDelay ?? Duration.zero,
      constraints: _convertConstraints(constraints),
      existingWorkPolicy: wm.ExistingWorkPolicy.replace,
    );

    return uniqueName;
  }

  @override
  Future<String?> schedulePeriodic(
    BackgroundTask task, {
    required Duration frequency,
    BackgroundConstraints? constraints,
  }) async {
    if (!_initialized) {
      throw StateError('BackgroundExecutor not initialized');
    }

    // Enforce minimum interval
    var effectiveFrequency = frequency;
    if (frequency < capabilities.minPeriodicInterval) {
      effectiveFrequency = capabilities.minPeriodicInterval;
    }

    final uniqueName = '${task.taskId}_periodic';

    await wm.Workmanager().registerPeriodicTask(
      uniqueName,
      task.taskId,
      inputData: task.inputData,
      frequency: effectiveFrequency,
      constraints: _convertConstraints(constraints),
      existingWorkPolicy: wm.ExistingPeriodicWorkPolicy.replace,
    );

    return uniqueName;
  }

  @override
  Future<void> cancelTask(String executionId) async {
    await wm.Workmanager().cancelByUniqueName(executionId);
  }

  @override
  Future<void> cancelAllTasks() async {
    await wm.Workmanager().cancelAll();
  }

  @override
  Future<bool> isTaskScheduled(String taskId) async {
    // WorkManager doesn't provide a direct API to check scheduled tasks
    // This would need platform channel implementation for full support
    return false;
  }

  @override
  BackgroundCapabilities get capabilities => BackgroundCapabilities.android;

  @override
  void dispose() {
    _handlers.clear();
    _initialized = false;
  }

  /// Convert our constraints to WorkManager constraints
  wm.Constraints? _convertConstraints(BackgroundConstraints? constraints) {
    if (constraints == null) return null;

    return wm.Constraints(
      networkType: _convertNetworkType(constraints.networkType),
      requiresBatteryNotLow:
          constraints.batteryConstraint == BatteryConstraint.notLow,
      requiresCharging:
          constraints.batteryConstraint == BatteryConstraint.charging,
      requiresDeviceIdle: constraints.requiresDeviceIdle,
      requiresStorageNotLow: constraints.requiresStorageNotLow,
    );
  }

  /// Convert our network type to WorkManager network type
  wm.NetworkType _convertNetworkType(NetworkType type) {
    switch (type) {
      case NetworkType.none:
        return wm.NetworkType.notRequired;
      case NetworkType.connected:
        return wm.NetworkType.connected;
      case NetworkType.unmetered:
        return wm.NetworkType.unmetered;
      case NetworkType.notRoaming:
        return wm.NetworkType.notRoaming;
    }
  }
}
