import 'background_constraints.dart';
import 'background_task.dart';

/// Capabilities that a background executor may support.
class BackgroundCapabilities {
  /// Whether periodic tasks are supported
  final bool supportsPeriodic;

  /// Whether one-time tasks are supported
  final bool supportsOneTime;

  /// Whether tasks can run when the app is terminated
  final bool supportsTerminated;

  /// Minimum interval for periodic tasks
  final Duration minPeriodicInterval;

  /// Maximum execution time for tasks (soft limit)
  final Duration maxExecutionTime;

  /// Whether constraints (network, battery) are supported
  final bool supportsConstraints;

  const BackgroundCapabilities({
    required this.supportsPeriodic,
    required this.supportsOneTime,
    required this.supportsTerminated,
    required this.minPeriodicInterval,
    required this.maxExecutionTime,
    required this.supportsConstraints,
  });

  /// Default capabilities for desktop platforms (timer-based)
  static const desktop = BackgroundCapabilities(
    supportsPeriodic: true,
    supportsOneTime: true,
    supportsTerminated: false,
    minPeriodicInterval: Duration(minutes: 1),
    maxExecutionTime: Duration(minutes: 30),
    supportsConstraints: false,
  );

  /// Capabilities for Android (WorkManager)
  static const android = BackgroundCapabilities(
    supportsPeriodic: true,
    supportsOneTime: true,
    supportsTerminated: true,
    minPeriodicInterval: Duration(minutes: 15),
    maxExecutionTime: Duration(minutes: 10),
    supportsConstraints: true,
  );

  /// Capabilities for iOS (Background Fetch)
  static const ios = BackgroundCapabilities(
    supportsPeriodic: true,
    supportsOneTime: true,
    supportsTerminated: true,
    minPeriodicInterval: Duration(minutes: 15),
    maxExecutionTime: Duration(seconds: 30),
    supportsConstraints: false,
  );
}

/// Abstract interface for platform-specific background task execution.
///
/// Implementations handle scheduling and running background tasks
/// using platform-appropriate mechanisms:
/// - Android: WorkManager
/// - iOS: BackgroundFetch
/// - Desktop: Dart timers
abstract class BackgroundExecutor {
  /// Initialize the background executor.
  ///
  /// Must be called before registering or scheduling tasks.
  Future<void> initialize();

  /// Register a task handler for a task type.
  ///
  /// [taskId] Unique identifier for the task type.
  /// [handler] Function to call when the task runs.
  void registerTask(String taskId, BackgroundTaskHandler handler);

  /// Unregister a task handler.
  void unregisterTask(String taskId);

  /// Schedule a one-time task.
  ///
  /// [task] The task to schedule.
  /// [constraints] Optional execution constraints.
  /// [initialDelay] Optional delay before first execution.
  ///
  /// Returns an execution ID that can be used to cancel the task.
  Future<String?> scheduleOneTime(
    BackgroundTask task, {
    BackgroundConstraints? constraints,
    Duration? initialDelay,
  });

  /// Schedule a periodic task.
  ///
  /// [task] The task to schedule.
  /// [frequency] How often the task should run.
  /// [constraints] Optional execution constraints.
  ///
  /// Returns an execution ID that can be used to cancel the task.
  Future<String?> schedulePeriodic(
    BackgroundTask task, {
    required Duration frequency,
    BackgroundConstraints? constraints,
  });

  /// Cancel a scheduled task.
  ///
  /// [executionId] The ID returned when scheduling the task.
  Future<void> cancelTask(String executionId);

  /// Cancel all scheduled tasks.
  Future<void> cancelAllTasks();

  /// Check if a task is currently scheduled.
  Future<bool> isTaskScheduled(String taskId);

  /// Get the capabilities of this executor.
  BackgroundCapabilities get capabilities;

  /// Dispose of resources.
  void dispose();
}
