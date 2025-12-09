import 'package:equatable/equatable.dart';

/// Login Flow v2 initialization response
///
/// Contains URLs and tokens needed to complete browser-based authentication.
/// See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/
class LoginFlowInit extends Equatable {
  /// URL to open in browser for user authentication
  final String loginUrl;

  /// Endpoint to poll for authentication completion
  final String pollEndpoint;

  /// Token to use when polling
  final String pollToken;

  const LoginFlowInit({
    required this.loginUrl,
    required this.pollEndpoint,
    required this.pollToken,
  });

  @override
  List<Object?> get props => [loginUrl, pollEndpoint, pollToken];
}
