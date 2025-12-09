/// Server information from Kavita
class KavitaServerInfo {
  /// The server name or install ID
  final String serverName;

  /// Kavita version
  final String version;

  /// Creates Kavita server info
  KavitaServerInfo({required this.serverName, required this.version});

  /// Creates from JSON response
  factory KavitaServerInfo.fromJson(Map<String, dynamic> json) {
    return KavitaServerInfo(
      serverName: json['installId'] as String? ?? 'Kavita Server',
      version: json['kavitaVersion'] as String? ?? 'Unknown',
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {'installId': serverName, 'kavitaVersion': version};
  }

  @override
  String toString() => 'KavitaServerInfo(name: $serverName, version: $version)';
}
