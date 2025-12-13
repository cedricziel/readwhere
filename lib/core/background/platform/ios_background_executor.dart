import 'dart:io';

import 'package:background_fetch/background_fetch.dart' as bf;

import '../background_constraints.dart';
import '../background_executor.dart';
import '../background_task.dart';

/// iOS implementation of [BackgroundExecutor] using BackgroundFetch.
///
/// This implementation supports:
/// - Periodic background fetch (system-managed intervals)
/// - Limited execution time (~30 seconds)
/// - No precise scheduling control
class IosBackgroundExecutor implements BackgroundExecutor {
  final Map<String, BackgroundTaskHandler> _handlers = {};
  bool _initialized = false;
  bool _periodicEnabled = false;

  @override
  Future<void> initialize() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('IosBackgroundExecutor requires iOS');
    }

    // Configure BackgroundFetch
    await bf.BackgroundFetch.configure(
      bf.BackgroundFetchConfig(
        minimumFetchInterval: 15, // minutes
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: bf.NetworkType.ANY,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );

    _initialized = true;
  }

  /// Called when background fetch event fires
  Future<void> _onBackgroundFetch(String taskId) async {
    // Execute all registered handlers
    for (final entry in _handlers.entries) {
      try {
        final task = BackgroundTask(taskId: entry.key, name: entry.key);
        await entry.value(task);
      } catch (e) {
        // Log error but continue with other handlers
        // ignore: avoid_print
        print('Background task ${entry.key} failed: $e');
      }
    }

    // Signal completion
    bf.BackgroundFetch.finish(taskId);
  }

  /// Called when background fetch times out
  void _onBackgroundFetchTimeout(String taskId) {
    // Signal completion on timeout
    bf.BackgroundFetch.finish(taskId);
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

    // iOS doesn't support true one-time tasks via BackgroundFetch
    // Schedule it to run on the next fetch cycle
    final handler = _handlers[task.taskId];
    if (handler != null) {
      // For immediate one-time tasks, execute directly if no delay
      if (initialDelay == null || initialDelay == Duration.zero) {
        await handler(task);
        return task.taskId;
      }
    }

    // Return the task ID as a reference
    return task.taskId;
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

    // iOS BackgroundFetch is already periodic by nature
    // Just ensure the handler is registered
    _periodicEnabled = true;

    // Start background fetch if not already running
    final status = await bf.BackgroundFetch.start();
    if (status != bf.BackgroundFetch.STATUS_AVAILABLE) {
      // Background fetch is disabled or restricted
      _periodicEnabled = false;
      return null;
    }

    return '${task.taskId}_periodic';
  }

  @override
  Future<void> cancelTask(String executionId) async {
    // iOS BackgroundFetch doesn't support canceling individual tasks
    // We can only stop the entire background fetch
    if (executionId.endsWith('_periodic')) {
      await bf.BackgroundFetch.stop();
      _periodicEnabled = false;
    }
  }

  @override
  Future<void> cancelAllTasks() async {
    await bf.BackgroundFetch.stop();
    _periodicEnabled = false;
  }

  @override
  Future<bool> isTaskScheduled(String taskId) async {
    final status = await bf.BackgroundFetch.status;
    return status == bf.BackgroundFetch.STATUS_AVAILABLE &&
        _handlers.containsKey(taskId) &&
        _periodicEnabled;
  }

  @override
  BackgroundCapabilities get capabilities => BackgroundCapabilities.ios;

  @override
  void dispose() {
    cancelAllTasks();
    _handlers.clear();
    _initialized = false;
  }
}
