/// Base exception class for the application.
///
/// All custom exceptions should extend this class.
abstract class AppException implements Exception {
  final String message;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    if (originalException != null) {
      return '$runtimeType: $message (Original: $originalException)';
    }
    return '$runtimeType: $message';
  }
}

/// Exception thrown when database operations fail.
///
/// This includes operations like reads, writes, updates, and deletes.
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when file system operations fail.
///
/// This includes file reading, writing, copying, moving, and deleting.
class FileException extends AppException {
  const FileException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when parsing book content or metadata fails.
///
/// This includes parsing EPUB, PDF, or other book format metadata.
class ParsingException extends AppException {
  const ParsingException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when attempting to open an unsupported book format.
///
/// This is thrown when the file extension is not in the supported formats list.
class UnsupportedFormatException extends AppException {
  final String fileExtension;

  const UnsupportedFormatException(
    super.message,
    this.fileExtension, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() {
    return '$runtimeType: $message (Format: .$fileExtension)';
  }
}

/// Exception thrown when network operations fail.
///
/// This includes API calls, downloads, and uploads (for future sync features).
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return '$runtimeType: $message (Status code: $statusCode)';
    }
    return super.toString();
  }
}

/// Exception thrown when validation fails.
///
/// This includes input validation, data validation, etc.
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return '$runtimeType: $message (Errors: $fieldErrors)';
    }
    return super.toString();
  }
}

/// Exception thrown when a requested resource is not found.
///
/// This includes books, reading progress, or other database entities.
class NotFoundException extends AppException {
  final String resourceType;
  final dynamic resourceId;

  const NotFoundException(
    super.message,
    this.resourceType,
    this.resourceId, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() {
    return '$runtimeType: $message ($resourceType with ID: $resourceId not found)';
  }
}

/// Exception thrown when cache operations fail.
///
/// This includes cache reads, writes, and invalidations.
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when permission-related operations fail.
///
/// This includes storage permissions, file access permissions, etc.
class PermissionException extends AppException {
  final String permission;

  const PermissionException(
    super.message,
    this.permission, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() {
    return '$runtimeType: $message (Permission: $permission)';
  }
}
