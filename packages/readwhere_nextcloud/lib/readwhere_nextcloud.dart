// Re-export WebDAV types for convenience
export 'package:readwhere_webdav/readwhere_webdav.dart'
    show WebDavFile, WebDavException, WebDavClient, WebDavConfig;

// Re-export plugin types for convenience
export 'package:readwhere_plugin/readwhere_plugin.dart'
    show
        AccountInfo,
        AccountProvider,
        AuthCredentials,
        AuthType,
        BasicAuthCredentials,
        BrowseResult,
        CatalogCapability,
        CatalogEntry,
        CatalogEntryType,
        CatalogFile,
        CatalogInfo,
        CatalogLink,
        CatalogProvider,
        CredentialStorage,
        CredentialType,
        DefaultCatalogEntry,
        OAuth2Credentials,
        OAuthFlowInit,
        OAuthFlowResult,
        ProgressCallback,
        ValidationResult;

// Client
export 'src/api/nextcloud_client.dart';
export 'src/api/ocs_api_service.dart';
export 'src/api/models/server_info.dart';

// Auth
export 'src/auth/models/login_flow_init.dart';
export 'src/auth/models/login_flow_result.dart';
export 'src/auth/models/nextcloud_account_info.dart';

// Storage
// Note: Use NextcloudCredentialStorage for Nextcloud-specific operations,
// or CredentialStorage from readwhere_plugin for generic plugin operations.
export 'src/storage/credential_storage.dart' show NextcloudCredentialStorage;
export 'src/storage/secure_credential_storage.dart';

// WebDAV
export 'src/webdav/nextcloud_webdav.dart';
export 'src/webdav/nextcloud_file.dart';
export 'src/webdav/nextcloud_file_adapter.dart';

// Widgets
export 'src/widgets/nextcloud_browser.dart';
export 'src/widgets/nextcloud_file_tile.dart';

// Provider (State Management)
export 'src/provider/nextcloud_provider.dart';

// Plugin Providers
export 'src/provider/nextcloud_account_provider.dart';
export 'src/provider/nextcloud_catalog_provider.dart';

// Exceptions
export 'src/exceptions/nextcloud_exception.dart';
