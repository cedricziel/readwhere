import 'package:equatable/equatable.dart';

/// Result of a Synology Drive login operation.
class LoginResult extends Equatable {
  /// Creates a new [LoginResult].
  const LoginResult({
    required this.success,
    this.deviceId,
    this.sessionId,
    this.errorCode,
  });

  /// Creates a [LoginResult] from a JSON response.
  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final data = json['data'] as Map<String, dynamic>?;
    final error = json['error'] as Map<String, dynamic>?;

    return LoginResult(
      success: success,
      deviceId: data?['did'] as String?,
      sessionId: data?['sid'] as String?,
      errorCode: error?['code'] as int?,
    );
  }

  /// Whether the login was successful.
  final bool success;

  /// Device ID returned by the server.
  final String? deviceId;

  /// Session ID required for subsequent API calls.
  final String? sessionId;

  /// Error code if the login failed.
  final int? errorCode;

  /// Returns a human-readable error message for the error code.
  String? get errorMessage {
    if (success) return null;

    switch (errorCode) {
      case 400:
        return 'Invalid username or password';
      case 401:
        return 'Account disabled';
      case 402:
        return 'Permission denied';
      case 403:
        return 'Two-factor authentication required';
      case 404:
        return 'Authentication failed';
      case 405:
        return 'App portal authentication required';
      case 406:
        return 'OTP authentication required';
      case 407:
        return 'Blocked IP address';
      default:
        return 'Login failed (code: $errorCode)';
    }
  }

  @override
  List<Object?> get props => [success, deviceId, sessionId, errorCode];

  @override
  String toString() {
    if (success) {
      return 'LoginResult(success: true, sessionId: ${sessionId?.substring(0, 8)}...)';
    }
    return 'LoginResult(success: false, error: $errorCode)';
  }
}
