/// Represents a background task to be executed.
class BackgroundTask {
  /// Unique identifier for the task type
  final String taskId;

  /// Task name for display purposes
  final String name;

  /// Additional data to pass to the task handler
  final Map<String, dynamic>? inputData;

  const BackgroundTask({
    required this.taskId,
    required this.name,
    this.inputData,
  });

  /// Create a copy with modified fields
  BackgroundTask copyWith({
    String? taskId,
    String? name,
    Map<String, dynamic>? inputData,
  }) {
    return BackgroundTask(
      taskId: taskId ?? this.taskId,
      name: name ?? this.name,
      inputData: inputData ?? this.inputData,
    );
  }

  @override
  String toString() => 'BackgroundTask(taskId: $taskId, name: $name)';
}

/// Result of a background task execution.
class BackgroundTaskResult {
  /// Whether the task succeeded
  final bool success;

  /// Error message if the task failed
  final String? error;

  /// Output data from the task
  final Map<String, dynamic>? outputData;

  const BackgroundTaskResult({
    required this.success,
    this.error,
    this.outputData,
  });

  /// Create a successful result
  const BackgroundTaskResult.success([this.outputData])
    : success = true,
      error = null;

  /// Create a failed result
  const BackgroundTaskResult.failure(this.error)
    : success = false,
      outputData = null;

  @override
  String toString() => 'BackgroundTaskResult(success: $success, error: $error)';
}

/// Handler function for background tasks.
typedef BackgroundTaskHandler =
    Future<BackgroundTaskResult> Function(BackgroundTask task);
