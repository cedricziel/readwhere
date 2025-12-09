import 'dart:async';

import 'package:flutter/material.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../domain/entities/catalog.dart';
import '../../../providers/catalogs_provider.dart';

/// Dialog for adding a new catalog (server) connection
class AddCatalogDialog extends StatefulWidget {
  const AddCatalogDialog({super.key});

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

  // Explicit FocusNodes help work around macOS keyboard event bugs
  final _urlFocusNode = FocusNode();
  final _apiKeyFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  CatalogType _catalogType = CatalogType.kavita;
  bool _isValidating = false;
  bool _isValidated = false;
  String? _validationError;
  OpdsFeed? _validatedFeed;
  String? _serverVersion;

  // Nextcloud-specific state
  NextcloudServerInfo? _nextcloudServerInfo;
  bool _isOAuthPolling = false;
  Timer? _oAuthPollTimer;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
      } else {
        // Validate OPDS/Kavita connection
        final feed = await provider.validateCatalog(
          _urlController.text.trim(),
          apiKey: _apiKeyController.text.trim().isNotEmpty
              ? _apiKeyController.text.trim()
              : null,
          type: _catalogType,
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
        );
      } else {
        catalog = await provider.addCatalog(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          apiKey: _apiKeyController.text.trim().isNotEmpty
              ? _apiKeyController.text.trim()
              : null,
          type: _catalogType,
          serverVersion: _serverVersion,
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

    return AlertDialog(
      title: const Text('Add Server'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server type selection
              Text('Server Type', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<CatalogType>(
                segments: const [
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
                    value: CatalogType.opds,
                    label: Text('OPDS'),
                    icon: Icon(Icons.public),
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
                    _validationError = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Server URL
              TextFormField(
                controller: _urlController,
                focusNode: _urlFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  hintText: _catalogType == CatalogType.kavita
                      ? 'https://your-kavita-server.com'
                      : _catalogType == CatalogType.nextcloud
                      ? 'https://your-nextcloud.com'
                      : 'https://catalog.example.com/opds',
                  prefixIcon: const Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Server URL is required';
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
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

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
                TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Your Nextcloud username',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
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
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'App Password',
                    hintText: 'Generate in Nextcloud settings',
                    prefixIcon: Icon(Icons.key),
                    helperText: 'Settings > Security > App passwords',
                    helperMaxLines: 2,
                  ),
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
                TextFormField(
                  controller: _apiKeyController,
                  focusNode: _apiKeyFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'OPDS API Key',
                    hintText: 'Your Kavita OPDS API key',
                    prefixIcon: Icon(Icons.key),
                    helperText:
                        'Find this in Kavita: Settings > API Key > OPDS',
                    helperMaxLines: 2,
                  ),
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

              // Server name
              if (_isValidated) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'My Kavita Server',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValidated && !_isValidating ? _save : null,
          child: _isValidating && _isValidated
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Server'),
        ),
      ],
    );
  }
}
