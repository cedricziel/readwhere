import 'dart:async';

import 'package:flutter/material.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../domain/entities/catalog.dart';
import '../../../providers/catalogs_provider.dart';
import '../../../widgets/adaptive/adaptive_button.dart';
import '../../../widgets/adaptive/adaptive_text_field.dart';
import 'nextcloud_folder_picker_dialog.dart';
import 'synology_folder_picker_dialog.dart';

/// Dialog for adding a new catalog (server) connection
class AddCatalogDialog extends StatefulWidget {
  /// Optional initial catalog type to pre-select
  final CatalogType? initialType;

  /// Whether to show the type selector (set to false when called from FeedsScreen)
  final bool showTypeSelector;

  const AddCatalogDialog({
    super.key,
    this.initialType,
    this.showTypeSelector = true,
  });

  @override
  State<AddCatalogDialog> createState() => _AddCatalogDialogState();
}

class _AddCatalogDialogState extends State<AddCatalogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _booksFolderController = TextEditingController();

  // Explicit FocusNodes help work around macOS keyboard event bugs
  final _urlFocusNode = FocusNode();
  final _apiKeyFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late CatalogType _catalogType;

  @override
  void initState() {
    super.initState();
    _catalogType = widget.initialType ?? CatalogType.kavita;
  }

  bool _isValidating = false;
  bool _isValidated = false;
  String? _validationError;
  OpdsFeed? _validatedFeed;
  String? _serverVersion;

  // Nextcloud-specific state
  NextcloudServerInfo? _nextcloudServerInfo;
  bool _isOAuthPolling = false;
  Timer? _oAuthPollTimer;

  // RSS-specific state
  RssFeed? _validatedRssFeed;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _booksFolderController.dispose();
    _urlFocusNode.dispose();
    _apiKeyFocusNode.dispose();
    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _oAuthPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _validateConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
      _isValidated = false;
      _validatedFeed = null;
      _nextcloudServerInfo = null;
      _validatedRssFeed = null;
    });

    try {
      final provider = sl<CatalogsProvider>();

      if (_catalogType == CatalogType.nextcloud) {
        // Validate Nextcloud connection
        final serverInfo = await provider.validateNextcloud(
          _urlController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() {
          _isValidated = true;
          _nextcloudServerInfo = serverInfo;
          _serverVersion = serverInfo.version;
          // Auto-fill name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = serverInfo.serverName;
          }
        });
      } else if (_catalogType == CatalogType.kavita) {
        // Validate Kavita connection
        final serverInfo = await provider.validateKavitaServer(
          _urlController.text.trim(),
          _apiKeyController.text.trim(),
        );

        setState(() {
          _isValidated = true;
          _serverVersion = serverInfo.version;
          // Auto-fill name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = serverInfo.serverName;
          }
        });
      } else if (_catalogType == CatalogType.rss) {
        // Validate RSS feed
        final feed = await provider.validateRssFeed(_urlController.text.trim());

        setState(() {
          _isValidated = true;
          _validatedRssFeed = feed;
          // Auto-fill name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = feed.title;
          }
        });
      } else if (_catalogType == CatalogType.fanfiction) {
        // Validate fanfiction.de using unified plugin system
        final tempCatalog = Catalog(
          id: 'temp',
          name: 'temp',
          url: 'https://www.fanfiktion.de',
          addedAt: DateTime.now(),
          type: CatalogType.fanfiction,
        );
        final result = await provider.validateCatalogUnified(tempCatalog);
        if (!result.isValid) {
          throw Exception(result.error ?? 'Validation failed');
        }
        setState(() {
          _isValidated = true;
          // Auto-fill name
          if (_nameController.text.isEmpty) {
            _nameController.text = 'Fanfiction.de';
          }
        });
      } else if (_catalogType == CatalogType.synology) {
        // Validate Synology connection
        await provider.validateSynology(
          _urlController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() {
          _isValidated = true;
          // Auto-fill name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = 'Synology NAS';
          }
        });
      } else {
        // Validate OPDS connection
        final feed = await provider.validateOpdsCatalog(
          _urlController.text.trim(),
        );

        setState(() {
          _isValidated = true;
          _validatedFeed = feed;
          // Auto-fill name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = feed.title;
          }
        });
      }
    } catch (e) {
      setState(() {
        _validationError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  /// Start OAuth2 Login Flow v2 for Nextcloud
  Future<void> _startOAuthFlow() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _validationError = 'Please enter server URL first';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      final provider = sl<CatalogsProvider>();
      await provider.startNextcloudOAuth(url);

      final loginUrl = provider.oAuthLoginUrl;
      if (loginUrl != null) {
        // Launch browser for login
        final uri = Uri.parse(loginUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        setState(() {
          _isOAuthPolling = true;
          _isValidating = false;
        });

        // Start polling for completion
        _startOAuthPolling();
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startOAuthPolling() {
    _oAuthPollTimer?.cancel();
    _oAuthPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _pollOAuth();
    });
  }

  Future<void> _pollOAuth() async {
    try {
      final provider = sl<CatalogsProvider>();
      final result = await provider.pollNextcloudOAuth();

      if (result != null) {
        _oAuthPollTimer?.cancel();
        setState(() {
          _isOAuthPolling = false;
          _isValidated = true;
          // Populate fields from OAuth result
          _usernameController.text = result.loginName;
          _passwordController.text = result.appPassword;
          // Update URL if server returned different URL
          if (result.server != _urlController.text.trim()) {
            _urlController.text = result.server;
          }
        });

        // Now validate to get server info
        await _validateConnection();
      }
    } catch (e) {
      _oAuthPollTimer?.cancel();
      setState(() {
        _isOAuthPolling = false;
        _validationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _cancelOAuth() {
    _oAuthPollTimer?.cancel();
    final provider = sl<CatalogsProvider>();
    provider.cancelNextcloudOAuth();
    setState(() {
      _isOAuthPolling = false;
    });
  }

  /// Open folder picker dialog for Nextcloud
  Future<void> _openFolderPicker() async {
    if (_nextcloudServerInfo == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => NextcloudFolderPickerDialog(
        serverUrl: _urlController.text.trim(),
        userId: _nextcloudServerInfo!.userId,
        username: _usernameController.text.trim(),
        appPassword: _passwordController.text.trim(),
        initialPath: _booksFolderController.text.isEmpty
            ? '/'
            : _booksFolderController.text,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _booksFolderController.text = result == '/' ? '' : result;
      });
    }
  }

  /// Open folder picker dialog for Synology
  Future<void> _openSynologyFolderPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SynologyFolderPickerDialog(
        serverUrl: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        initialPath: _booksFolderController.text.isEmpty
            ? '/mydrive'
            : _booksFolderController.text,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _booksFolderController.text = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    final provider = sl<CatalogsProvider>();
    Catalog? catalog;

    try {
      if (_catalogType == CatalogType.nextcloud) {
        catalog = await provider.addNextcloudCatalog(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          username: _usernameController.text.trim(),
          appPassword: _passwordController.text.trim(),
          userId: _nextcloudServerInfo?.userId,
          serverVersion: _serverVersion,
          booksFolder: _booksFolderController.text.trim().isEmpty
              ? null
              : _booksFolderController.text.trim(),
        );
      } else if (_catalogType == CatalogType.kavita) {
        catalog = await provider.addKavitaCatalog(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          apiKey: _apiKeyController.text.trim(),
          serverVersion: _serverVersion,
        );
      } else if (_catalogType == CatalogType.rss) {
        catalog = await provider.addRssCatalog(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          iconUrl: _validatedRssFeed?.imageUrl,
        );
      } else if (_catalogType == CatalogType.fanfiction) {
        catalog = await provider.addFanfictionCatalog(
          name: _nameController.text.trim(),
        );
      } else if (_catalogType == CatalogType.synology) {
        catalog = await provider.addSynologyCatalog(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          booksFolder: _booksFolderController.text.trim().isEmpty
              ? '/mydrive'
              : _booksFolderController.text.trim(),
        );
      } else {
        catalog = await provider.addOpdsCatalog(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
        );
      }

      if (mounted) {
        if (catalog != null) {
          Navigator.of(context).pop(catalog);
        } else {
          setState(() {
            _validationError = provider.error ?? 'Failed to add server';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine dialog title based on context
    final dialogTitle = widget.showTypeSelector
        ? 'Add Server'
        : _catalogType == CatalogType.rss
        ? 'Subscribe to Feed'
        : 'Add Server';

    return AlertDialog.adaptive(
      title: Text(dialogTitle),
      content: Material(
        // Material wrapper for SegmentedButton and other Material widgets
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Server type selection (hidden when called from FeedsScreen)
                if (widget.showTypeSelector) ...[
                  Text('Server Type', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<CatalogType>(
                    segments: const [
                      ButtonSegment(
                        value: CatalogType.rss,
                        label: Text('RSS'),
                        icon: Icon(Icons.rss_feed),
                      ),
                      ButtonSegment(
                        value: CatalogType.kavita,
                        label: Text('Kavita'),
                        icon: Icon(Icons.menu_book),
                      ),
                      ButtonSegment(
                        value: CatalogType.nextcloud,
                        label: Text('Nextcloud'),
                        icon: Icon(Icons.cloud),
                      ),
                      ButtonSegment(
                        value: CatalogType.synology,
                        label: Text('Synology'),
                        icon: Icon(Icons.storage),
                      ),
                      ButtonSegment(
                        value: CatalogType.opds,
                        label: Text('OPDS'),
                        icon: Icon(Icons.public),
                      ),
                      ButtonSegment(
                        value: CatalogType.fanfiction,
                        label: Text('Fanfiction'),
                        icon: Icon(Icons.auto_stories),
                      ),
                    ],
                    selected: {_catalogType},
                    onSelectionChanged: (selected) {
                      _cancelOAuth();
                      setState(() {
                        _catalogType = selected.first;
                        _isValidated = false;
                        _validatedFeed = null;
                        _nextcloudServerInfo = null;
                        _validatedRssFeed = null;
                        _validationError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Server URL (not shown for fanfiction.de which has a fixed URL)
                if (_catalogType != CatalogType.fanfiction) ...[
                  AdaptiveTextField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    autofocus: true,
                    label: _catalogType == CatalogType.rss
                        ? 'Feed URL'
                        : 'Server URL',
                    placeholder: _catalogType == CatalogType.rss
                        ? 'https://example.com/feed.xml'
                        : _catalogType == CatalogType.kavita
                        ? 'https://your-kavita-server.com'
                        : _catalogType == CatalogType.nextcloud
                        ? 'https://your-nextcloud.com'
                        : _catalogType == CatalogType.synology
                        ? 'https://your-synology-nas:5001'
                        : 'https://catalog.example.com/opds',
                    prefixIcon: Icons.link,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _catalogType == CatalogType.rss
                            ? 'Feed URL is required'
                            : 'Server URL is required';
                      }
                      if (!value.startsWith('http://') &&
                          !value.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_isValidated) {
                        setState(() {
                          _isValidated = false;
                          _validatedFeed = null;
                          _nextcloudServerInfo = null;
                          _validatedRssFeed = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Synology credentials
                if (_catalogType == CatalogType.synology) ...[
                  AdaptiveTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    label: 'Username',
                    placeholder: 'Your Synology username',
                    prefixIcon: Icons.person,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    validator: (value) {
                      if (_catalogType == CatalogType.synology &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Username is required';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_isValidated) {
                        setState(() {
                          _isValidated = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  AdaptiveTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    label: 'Password',
                    placeholder: 'Your Synology password',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    validator: (value) {
                      if (_catalogType == CatalogType.synology &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_isValidated) {
                        setState(() {
                          _isValidated = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Nextcloud credentials
                if (_catalogType == CatalogType.nextcloud) ...[
                  // OAuth login button
                  if (!_isOAuthPolling && !_isValidated) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isValidating ? null : _startOAuthFlow,
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Login with Browser'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'or enter credentials manually',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // OAuth polling indicator
                  if (_isOAuthPolling) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Waiting for browser login...',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: _cancelOAuth,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Username field
                  AdaptiveTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    label: 'Username',
                    placeholder: 'Your Nextcloud username',
                    prefixIcon: Icons.person,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    enabled: !_isOAuthPolling,
                    validator: (value) {
                      if (_catalogType == CatalogType.nextcloud &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Username is required';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_isValidated) {
                        setState(() {
                          _isValidated = false;
                          _nextcloudServerInfo = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // App password field
                  AdaptiveTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    label: 'App Password',
                    placeholder: 'Generate in Nextcloud settings',
                    prefixIcon: Icons.key,
                    helperText: 'Settings > Security > App passwords',
                    obscureText: true,
                    enabled: !_isOAuthPolling,
                    validator: (value) {
                      if (_catalogType == CatalogType.nextcloud &&
                          (value == null || value.trim().isEmpty)) {
                        return 'App password is required';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_isValidated) {
                        setState(() {
                          _isValidated = false;
                          _nextcloudServerInfo = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // API Key (for Kavita)
                if (_catalogType == CatalogType.kavita) ...[
                  AdaptiveTextField(
                    controller: _apiKeyController,
                    focusNode: _apiKeyFocusNode,
                    label: 'OPDS API Key',
                    placeholder: 'Your Kavita OPDS API key',
                    prefixIcon: Icons.key,
                    helperText:
                        'Find this in Kavita: Settings > API Key > OPDS',
                    obscureText: true,
                    validator: (value) {
                      if (_catalogType == CatalogType.kavita &&
                          (value == null || value.trim().isEmpty)) {
                        return 'API key is required for Kavita';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_isValidated) {
                        setState(() {
                          _isValidated = false;
                          _validatedFeed = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Validation button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isValidating ? null : _validateConnection,
                    icon: _isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isValidated ? Icons.check_circle : Icons.wifi_find,
                          ),
                    label: Text(
                      _isValidating
                          ? 'Connecting...'
                          : _isValidated
                          ? 'Connection Verified'
                          : 'Test Connection',
                    ),
                  ),
                ),

                // Validation result
                if (_validationError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // OPDS/Kavita validation success
                if (_isValidated && _validatedFeed != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Connected to: ${_validatedFeed!.title}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_validatedFeed!.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _validatedFeed!.subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Nextcloud validation success
                if (_isValidated && _nextcloudServerInfo != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Connected to: ${_nextcloudServerInfo!.serverName}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'User: ${_nextcloudServerInfo!.displayName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Version: ${_nextcloudServerInfo!.version}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Books folder field for Nextcloud (shown after validation)
                if (_isValidated && _catalogType == CatalogType.nextcloud) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AdaptiveTextField(
                          controller: _booksFolderController,
                          readOnly: true,
                          label: 'Starting Folder',
                          placeholder: '/',
                          prefixIcon: Icons.folder,
                          helperText: 'Browse to select a folder',
                          suffix: _booksFolderController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _booksFolderController.clear();
                                    });
                                  },
                                  tooltip: 'Reset to root',
                                )
                              : null,
                          onTap: _openFolderPicker,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IconButton.filled(
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Browse folders',
                          onPressed: _openFolderPicker,
                        ),
                      ),
                    ],
                  ),
                ],

                // RSS validation success
                if (_isValidated && _validatedRssFeed != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Connected to: ${_validatedRssFeed!.title}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_validatedRssFeed!.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _validatedRssFeed!.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${_validatedRssFeed!.items.length} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Fanfiction validation success
                if (_isValidated && _catalogType == CatalogType.fanfiction) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connected to Fanfiction.de',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Synology validation success
                if (_isValidated && _catalogType == CatalogType.synology) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connected to Synology Drive',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Folder picker for Synology
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AdaptiveTextField(
                          controller: _booksFolderController,
                          readOnly: true,
                          label: 'Starting Folder',
                          placeholder: '/mydrive',
                          prefixIcon: Icons.folder,
                          helperText: 'Browse to select a folder',
                          suffix:
                              _booksFolderController.text.isNotEmpty &&
                                  _booksFolderController.text != '/mydrive'
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _booksFolderController.clear();
                                    });
                                  },
                                  tooltip: 'Reset to My Drive',
                                )
                              : null,
                          onTap: _openSynologyFolderPicker,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IconButton.filled(
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Browse folders',
                          onPressed: _openSynologyFolderPicker,
                        ),
                      ),
                    ],
                  ),
                ],

                // Server name
                if (_isValidated) ...[
                  const SizedBox(height: 16),
                  AdaptiveTextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    label: 'Display Name',
                    placeholder: 'My Kavita Server',
                    prefixIcon: Icons.label_outline,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Display name is required';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        AdaptiveTextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AdaptiveFilledButton(
          onPressed: _isValidated && !_isValidating ? _save : null,
          child: _isValidating && _isValidated
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : Text(
                  _catalogType == CatalogType.rss ? 'Subscribe' : 'Add Server',
                ),
        ),
      ],
    );
  }
}
