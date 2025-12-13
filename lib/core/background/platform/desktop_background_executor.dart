import 'dart:async';

import '../background_constraints.dart';
import '../background_executor.dart';
import '../background_task.dart';

/// Desktop implementation of [BackgroundExecutor] using Dart timers.
///
/// This implementation works on macOS, Windows, and Linux.
/// Tasks only run while the app is running.
class DesktopBackgroundExecutor implements BackgroundExecutor {
  final Map<String, BackgroundTaskHandler> _handlers = {};
  final Map<String, Timer> _oneTimeTimers = {};
  final Map<String, Timer> _periodicTimers = {};
  final Map<String, BackgroundTask> _scheduledTasks = {};

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  void registerTask(String taskId, BackgroundTaskHandler handler) {
    _handlers[taskId] = handler;
  }

  @override
  void unregisterTask(String taskId) {
    _handlers.remove(taskId);
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

    final handler = _handlers[task.taskId];
    if (handler == null) {
      throw ArgumentError('No handler registered for task: ${task.taskId}');
    }

    final executionId =
        '${task.taskId}_${DateTime.now().millisecondsSinceEpoch}';
    final delay = initialDelay ?? Duration.zero;

    _scheduledTasks[executionId] = task;
    _oneTimeTimers[executionId] = Timer(delay, () async {
      try {
        await handler(task);
      } finally {
        _oneTimeTimers.remove(executionId);
        _scheduledTasks.remove(executionId);
      }
    });

    return executionId;
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

    final handler = _handlers[task.taskId];
    if (handler == null) {
      throw ArgumentError('No handler registered for task: ${task.taskId}');
    }

    // Enforce minimum interval
    final effectiveFrequency = frequency < capabilities.minPeriodicInterval
        ? capabilities.minPeriodicInterval
        : frequency;

    final executionId = '${task.taskId}_periodic';

    // Cancel existing periodic task with same ID if any
    await cancelTask(executionId);

    _scheduledTasks[executionId] = task;
    _periodicTimers[executionId] = Timer.periodic(effectiveFrequency, (
      _,
    ) async {
      try {
        await handler(task);
      } catch (e) {
        // Log error but don't stop periodic timer
        // ignore: avoid_print
        print('Background task ${task.taskId} failed: $e');
      }
    });

    return executionId;
  }

  @override
  Future<void> cancelTask(String executionId) async {
    _oneTimeTimers[executionId]?.cancel();
    _oneTimeTimers.remove(executionId);

    _periodicTimers[executionId]?.cancel();
    _periodicTimers.remove(executionId);

    _scheduledTasks.remove(executionId);
  }

  @override
  Future<void> cancelAllTasks() async {
    for (final timer in _oneTimeTimers.values) {
      timer.cancel();
    }
    _oneTimeTimers.clear();

    for (final timer in _periodicTimers.values) {
      timer.cancel();
    }
    _periodicTimers.clear();

    _scheduledTasks.clear();
  }

  @override
  Future<bool> isTaskScheduled(String taskId) async {
    return _scheduledTasks.values.any((task) => task.taskId == taskId);
  }

  @override
  BackgroundCapabilities get capabilities => BackgroundCapabilities.desktop;

  @override
  void dispose() {
    cancelAllTasks();
    _handlers.clear();
    _initialized = false;
  }
}
