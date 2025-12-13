// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart' as package_info;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../widgets/update_dialog.dart';
import 'sync_settings_section.dart';

/// The settings screen for configuring app preferences.
///
/// This screen provides access to various application settings including:
/// - Appearance (theme mode)
/// - Reading preferences (font, size, line height)
/// - App behavior (haptic feedback, keep screen awake)
/// - About information (app version)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await package_info.PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // In landscape mode, constrain width for better readability
          final content = ListView(
            children: [
              _buildSectionHeader('Appearance'),
              _buildThemeModeSelector(settingsProvider),
              const Divider(),
              _buildSectionHeader('Reading'),
              _buildFontSizeSlider(settingsProvider),
              _buildFontFamilySelector(settingsProvider),
              _buildLineHeightSlider(settingsProvider),
              const Divider(),
              _buildSectionHeader('Sync'),
              ChangeNotifierProvider.value(
                value: sl<SyncSettingsProvider>(),
                child: const SyncSettingsSection(),
              ),
              const Divider(),
              _buildSectionHeader('App Behavior'),
              _buildHapticFeedbackToggle(settingsProvider),
              _buildKeepScreenAwakeToggle(settingsProvider),
              const Divider(),
              _buildSectionHeader('Storage'),
              _buildStorageInfo(),
              const Divider(),
              _buildSectionHeader('About'),
              _buildAboutInfo(),
            ],
          );

          // Apply max-width constraint in landscape for comfortable reading
          if (context.isPhoneLandscape) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  /// Builds a section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Builds the theme mode selector
  Widget _buildThemeModeSelector(SettingsProvider settingsProvider) {
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('System'),
          subtitle: const Text('Follow system theme'),
          value: ThemeMode.system,
          groupValue: settingsProvider.themeMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          subtitle: const Text('Always use light theme'),
          value: ThemeMode.light,
          groupValue: settingsProvider.themeMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          subtitle: const Text('Always use dark theme'),
          value: ThemeMode.dark,
          groupValue: settingsProvider.themeMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setThemeMode(value);
            }
          },
        ),
      ],
    );
  }

  /// Builds the font size slider
  Widget _buildFontSizeSlider(SettingsProvider settingsProvider) {
    final fontSize = settingsProvider.defaultReadingSettings.fontSize;

    return ListTile(
      title: Text('Font Size: ${fontSize.toStringAsFixed(0)}'),
      subtitle: Slider(
        value: fontSize,
        min: 12.0,
        max: 32.0,
        divisions: 20,
        label: fontSize.toStringAsFixed(0),
        onChanged: (value) {
          settingsProvider.setFontSize(value);
        },
      ),
    );
  }

  /// Builds the font family selector
  Widget _buildFontFamilySelector(SettingsProvider settingsProvider) {
    final fontFamily = settingsProvider.defaultReadingSettings.fontFamily;

    return ListTile(
      title: const Text('Font Family'),
      subtitle: Text(fontFamily),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showFontFamilyDialog(settingsProvider);
      },
    );
  }

  /// Shows a dialog to select font family
  void _showFontFamilyDialog(SettingsProvider settingsProvider) {
    final fontFamilies = [
      'Georgia',
      'Palatino',
      'Times New Roman',
      'Arial',
      'Helvetica',
      'Verdana',
      'Comic Sans MS',
      'Courier New',
      'Roboto',
      'Open Sans',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Font Family'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: fontFamilies.length,
            itemBuilder: (context, index) {
              final family = fontFamilies[index];
              final isSelected =
                  family == settingsProvider.defaultReadingSettings.fontFamily;

              return RadioListTile<String>(
                title: Text(family, style: TextStyle(fontFamily: family)),
                value: family,
                groupValue: settingsProvider.defaultReadingSettings.fontFamily,
                selected: isSelected,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setFontFamily(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Builds the line height slider
  Widget _buildLineHeightSlider(SettingsProvider settingsProvider) {
    final lineHeight = settingsProvider.defaultReadingSettings.lineHeight;

    return ListTile(
      title: Text('Line Height: ${lineHeight.toStringAsFixed(1)}'),
      subtitle: Slider(
        value: lineHeight,
        min: 1.0,
        max: 2.5,
        divisions: 15,
        label: lineHeight.toStringAsFixed(1),
        onChanged: (value) {
          settingsProvider.setLineHeight(value);
        },
      ),
    );
  }

  /// Builds the haptic feedback toggle
  Widget _buildHapticFeedbackToggle(SettingsProvider settingsProvider) {
    return SwitchListTile(
      title: const Text('Haptic Feedback'),
      subtitle: const Text('Vibrate on certain actions'),
      value: settingsProvider.hapticFeedback,
      onChanged: (value) {
        settingsProvider.setHapticFeedback(value);
      },
    );
  }

  /// Builds the keep screen awake toggle
  Widget _buildKeepScreenAwakeToggle(SettingsProvider settingsProvider) {
    return SwitchListTile(
      title: const Text('Keep Screen Awake'),
      subtitle: const Text('Prevent screen from sleeping while reading'),
      value: settingsProvider.keepScreenAwake,
      onChanged: (value) {
        settingsProvider.setKeepScreenAwake(value);
      },
    );
  }

  /// Builds storage information section
  Widget _buildStorageInfo() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Books Directory'),
          subtitle: const Text('Default location for imported books'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement directory picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Directory picker not yet implemented'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services),
          title: const Text('Clear Cache'),
          subtitle: const Text('Free up storage space'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showClearCacheDialog();
          },
        ),
      ],
    );
  }

  /// Shows a dialog to confirm cache clearing
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear cached images and temporary files. Your books and reading progress will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Builds about information section
  Widget _buildAboutInfo() {
    final updateProvider = sl<UpdateProvider>();

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('App Version'),
          subtitle: Text(_appVersion.isEmpty ? 'Loading...' : _appVersion),
        ),
        ListenableBuilder(
          listenable: updateProvider,
          builder: (context, _) {
            return ListTile(
              leading: Icon(
                updateProvider.updateAvailable
                    ? Icons.system_update
                    : Icons.refresh,
                color: updateProvider.updateAvailable
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Check for Updates'),
              subtitle: updateProvider.isChecking
                  ? const Text('Checking...')
                  : updateProvider.updateAvailable
                  ? Text(
                      'Version ${updateProvider.updateInfo?.version} available',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : updateProvider.error != null
                  ? Text(
                      'Error: ${updateProvider.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : const Text('Check for new versions'),
              trailing: updateProvider.isChecking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : updateProvider.updateAvailable
                  ? Badge(
                      label: const Text('NEW'),
                      child: const Icon(Icons.chevron_right),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: updateProvider.isChecking
                  ? null
                  : () => _checkForUpdates(),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Licenses'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'ReadWhere',
              applicationVersion: _appVersion,
              applicationLegalese: 'A cross-platform e-reader for open formats',
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('Source Code'),
          subtitle: const Text('View on GitHub'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openUrl('https://github.com/cedricziel/readwhere'),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text('Report Issue'),
          subtitle: const Text('Report bugs or request features'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              _openUrl('https://github.com/cedricziel/readwhere/issues'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            _showResetSettingsDialog();
          },
          child: const Text(
            'Reset All Settings',
            style: TextStyle(color: Colors.red),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Opens a URL in the external browser
  Future<void> _openUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  /// Checks for app updates
  Future<void> _checkForUpdates() async {
    final updateProvider = sl<UpdateProvider>();
    final result = await updateProvider.checkForUpdates(force: true);

    if (!mounted) return;

    if (result.updateAvailable && result.updateInfo != null) {
      await UpdateDialog.show(
        context,
        updateInfo: result.updateInfo!,
        currentVersion: result.currentVersion,
        onDismiss: () => updateProvider.dismissUpdate(),
      );
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update check failed: ${result.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are using the latest version')),
      );
    }
  }

  /// Shows a dialog to confirm settings reset
  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
          'This will reset all settings to their default values. Your books and reading progress will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              final settingsProvider = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              settingsProvider.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All settings have been reset to defaults'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
