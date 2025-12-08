import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application.
///
/// Failures represent errors that have been handled and converted
/// into a domain-friendly format. They are used in the clean architecture
/// pattern to separate error handling from exceptions.
///
/// All failure classes extend Equatable for easy comparison.
abstract class Failure extends Equatable {
  final String message;
  final String? details;

  const Failure(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];

  @override
  String toString() {
    if (details != null) {
      return '$runtimeType: $message\nDetails: $details';
    }
    return '$runtimeType: $message';
  }
}

/// Failure that occurs during database operations.
///
/// This includes reads, writes, updates, deletes, and queries.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.details});
}

/// Failure that occurs during file system operations.
///
/// This includes file reading, writing, copying, moving, and deleting.
class FileFailure extends Failure {
  const FileFailure(super.message, {super.details});
}

/// Failure that occurs when parsing book content or metadata.
///
/// This includes parsing EPUB, PDF, or other book format metadata.
class ParsingFailure extends Failure {
  final String? format;

  const ParsingFailure(super.message, {this.format, super.details});

  @override
  List<Object?> get props => [message, details, format];

  @override
  String toString() {
    if (format != null) {
      return '$runtimeType: $message (Format: $format)';
    }
    return super.toString();
  }
}

/// Failure that occurs when an unsupported book format is encountered.
///
/// This is returned when the file extension is not in the supported formats list.
class UnsupportedFormatFailure extends Failure {
  final String fileExtension;

  const UnsupportedFormatFailure(
    super.message,
    this.fileExtension, {
    super.details,
  });

  @override
  List<Object?> get props => [message, details, fileExtension];

  @override
  String toString() {
    return '$runtimeType: $message (Format: .$fileExtension)';
  }
}

/// Failure that occurs during network operations.
///
/// This includes API calls, downloads, and uploads (for future sync features).
class NetworkFailure extends Failure {
  final int? statusCode;

  const NetworkFailure(super.message, {this.statusCode, super.details});

  @override
  List<Object?> get props => [message, details, statusCode];

  @override
  String toString() {
    if (statusCode != null) {
      return '$runtimeType: $message (Status code: $statusCode)';
    }
    return super.toString();
  }
}

/// Failure that occurs when validation fails.
///
/// This includes input validation, data validation, etc.
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(super.message, {this.fieldErrors, super.details});

  @override
  List<Object?> get props => [message, details, fieldErrors];

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return '$runtimeType: $message\nField Errors: $fieldErrors';
    }
    return super.toString();
  }
}

/// Failure that occurs when a requested resource is not found.
///
/// This includes books, reading progress, or other database entities.
class NotFoundFailure extends Failure {
  final String resourceType;
  final dynamic resourceId;

  const NotFoundFailure(
    super.message,
    this.resourceType,
    this.resourceId, {
    super.details,
  });

  @override
  List<Object?> get props => [message, details, resourceType, resourceId];

  @override
  String toString() {
    return '$runtimeType: $message ($resourceType with ID: $resourceId not found)';
  }
}

/// Failure that occurs during cache operations.
///
/// This includes cache reads, writes, and invalidations.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.details});
}

/// Failure that occurs when permission-related operations fail.
///
/// This includes storage permissions, file access permissions, etc.
class PermissionFailure extends Failure {
  final String permission;

  const PermissionFailure(super.message, this.permission, {super.details});

  @override
  List<Object?> get props => [message, details, permission];

  @override
  String toString() {
    return '$runtimeType: $message (Permission: $permission)';
  }
}

/// Generic server failure for unhandled errors.
///
/// This is a catch-all for unexpected errors that don't fit other categories.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.details});
}
