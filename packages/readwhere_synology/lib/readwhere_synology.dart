/// Synology Drive integration for Flutter.
///
/// This library provides:
/// - Authentication with Synology NAS
/// - File browsing and search
/// - File downloads with progress tracking
/// - Session management with auto-refresh
library;

// API
export 'src/api/models/list_result.dart';
export 'src/api/models/login_result.dart';
export 'src/api/models/search_result.dart';
export 'src/api/models/synology_file.dart';
export 'src/api/synology_api_service.dart';
export 'src/api/synology_client.dart';

// Auth
export 'src/auth/synology_session.dart';

// Storage
export 'src/storage/secure_session_storage.dart';
export 'src/storage/session_storage.dart';

// Provider
export 'src/provider/synology_provider.dart';

// Widgets
export 'src/widgets/synology_browser.dart';
export 'src/widgets/synology_file_tile.dart';

// Exceptions
export 'src/exceptions/synology_exception.dart';
