import 'package:equatable/equatable.dart';

/// Login Flow v2 result (returned after successful authentication)
class LoginFlowResult extends Equatable {
  /// Server URL (normalized)
  final String server;

  /// Login name / username
  final String loginName;

  /// Generated app password
  final String appPassword;

  const LoginFlowResult({
    required this.server,
    required this.loginName,
    required this.appPassword,
  });

  @override
  List<Object?> get props => [server, loginName, appPassword];
}
