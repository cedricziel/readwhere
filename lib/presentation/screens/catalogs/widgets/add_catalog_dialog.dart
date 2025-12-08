import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../domain/entities/catalog.dart';
import '../../../../domain/entities/opds_feed.dart';
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

  CatalogType _catalogType = CatalogType.kavita;
  bool _isValidating = false;
  bool _isValidated = false;
  String? _validationError;
  OpdsFeed? _validatedFeed;
  String? _serverVersion;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
      _isValidated = false;
      _validatedFeed = null;
    });

    try {
      final provider = sl<CatalogsProvider>();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = sl<CatalogsProvider>();
    final catalog = await provider.addCatalog(
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isNotEmpty
          ? _apiKeyController.text.trim()
          : null,
      type: _catalogType,
      serverVersion: _serverVersion,
    );

    if (mounted && catalog != null) {
      Navigator.of(context).pop(catalog);
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
                    value: CatalogType.opds,
                    label: Text('OPDS'),
                    icon: Icon(Icons.public),
                  ),
                ],
                selected: {_catalogType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _catalogType = selected.first;
                    _isValidated = false;
                    _validatedFeed = null;
                    _validationError = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Server URL
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  hintText: _catalogType == CatalogType.kavita
                      ? 'https://your-kavita-server.com'
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
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // API Key (for Kavita)
              if (_catalogType == CatalogType.kavita) ...[
                TextFormField(
                  controller: _apiKeyController,
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

              // Server name
              if (_isValidated) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
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
          onPressed: _isValidated ? _save : null,
          child: const Text('Add Server'),
        ),
      ],
    );
  }
}
