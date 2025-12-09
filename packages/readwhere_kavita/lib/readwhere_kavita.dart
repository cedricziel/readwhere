/// Kavita server provider for ReadWhere.
///
/// This package provides Kavita server integration for the ReadWhere app,
/// including:
/// - REST API client for authentication and progress sync
/// - OPDS-based catalog browsing and downloading
/// - Account provider implementation
library;

// API Client
export 'src/api/kavita_api_client.dart';
export 'src/api/kavita_exception.dart';

// Models
export 'src/models/kavita_server_info.dart';
export 'src/models/kavita_progress.dart';

// Providers
export 'src/provider/kavita_account_provider.dart';
export 'src/provider/kavita_provider.dart';
