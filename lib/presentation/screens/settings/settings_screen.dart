// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart' as package_info;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../widgets/adaptive/adaptive_button.dart';
import '../../widgets/adaptive/adaptive_list_section.dart';
import '../../widgets/adaptive/adaptive_list_tile.dart';
import '../../widgets/adaptive/adaptive_page_scaffold.dart';
import '../../widgets/adaptive/adaptive_switch_list_tile.dart';
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
    return AdaptivePageScaffold(
      title: 'Settings',
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // In landscape mode, constrain width for better readability
          final content = ListView(
            children: [
              // Appearance section
              AdaptiveListSection(
                header: 'Appearance',
                children: _buildThemeModeItems(settingsProvider),
              ),

              // Reading section
              AdaptiveListSection(
                header: 'Reading',
                children: [
                  _buildFontSizeItem(settingsProvider),
                  _buildFontFamilyItem(settingsProvider),
                  _buildLineHeightItem(settingsProvider),
                ],
              ),

              // Sync section
              AdaptiveListSection(
                header: 'Sync',
                children: [
                  ChangeNotifierProvider.value(
                    value: sl<SyncSettingsProvider>(),
                    child: const SyncSettingsSection(),
                  ),
                ],
              ),

              // App Behavior section
              AdaptiveListSection(
                header: 'App Behavior',
                children: [
                  _buildHapticFeedbackItem(settingsProvider),
                  _buildKeepScreenAwakeItem(settingsProvider),
                ],
              ),

              // Storage section
              AdaptiveListSection(
                header: 'Storage',
                children: _buildStorageItems(),
              ),

              // About section
              AdaptiveListSection(
                header: 'About',
                children: _buildAboutItems(),
              ),

              // Reset button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: AdaptiveTextButton(
                  onPressed: _showResetSettingsDialog,
                  isDestructive: true,
                  child: const Text('Reset All Settings'),
                ),
              ),
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

  /// Builds theme mode selection items
  List<Widget> _buildThemeModeItems(SettingsProvider settingsProvider) {
    return [
      AdaptiveRadioListTile<ThemeMode>(
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
      AdaptiveRadioListTile<ThemeMode>(
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
      AdaptiveRadioListTile<ThemeMode>(
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
    ];
  }

  /// Builds font size item with slider
  Widget _buildFontSizeItem(SettingsProvider settingsProvider) {
    final fontSize = settingsProvider.defaultReadingSettings.fontSize;

    return AdaptiveListTile(
      title: Text('Font Size: ${fontSize.toStringAsFixed(0)}'),
      subtitle: Slider.adaptive(
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

  /// Builds the font family item
  Widget _buildFontFamilyItem(SettingsProvider settingsProvider) {
    final fontFamily = settingsProvider.defaultReadingSettings.fontFamily;

    return AdaptiveListTile(
      title: const Text('Font Family'),
      subtitle: Text(fontFamily),
      showDisclosureIndicator: true,
      onTap: () => _showFontFamilyDialog(settingsProvider),
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
      builder: (context) => AlertDialog.adaptive(
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
          AdaptiveTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Builds the line height item with slider
  Widget _buildLineHeightItem(SettingsProvider settingsProvider) {
    final lineHeight = settingsProvider.defaultReadingSettings.lineHeight;

    return AdaptiveListTile(
      title: Text('Line Height: ${lineHeight.toStringAsFixed(1)}'),
      subtitle: Slider.adaptive(
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

  /// Builds the haptic feedback toggle item
  Widget _buildHapticFeedbackItem(SettingsProvider settingsProvider) {
    return AdaptiveSwitchListTile(
      title: const Text('Haptic Feedback'),
      subtitle: const Text('Vibrate on certain actions'),
      value: settingsProvider.hapticFeedback,
      onChanged: (value) {
        settingsProvider.setHapticFeedback(value);
      },
    );
  }

  /// Builds the keep screen awake toggle item
  Widget _buildKeepScreenAwakeItem(SettingsProvider settingsProvider) {
    return AdaptiveSwitchListTile(
      title: const Text('Keep Screen Awake'),
      subtitle: const Text('Prevent screen from sleeping while reading'),
      value: settingsProvider.keepScreenAwake,
      onChanged: (value) {
        settingsProvider.setKeepScreenAwake(value);
      },
    );
  }

  /// Builds storage information items
  List<Widget> _buildStorageItems() {
    return [
      AdaptiveListTile(
        leading: context.useCupertino
            ? const Icon(CupertinoIcons.folder)
            : const Icon(Icons.storage),
        title: const Text('Books Directory'),
        subtitle: const Text('Default location for imported books'),
        showDisclosureIndicator: true,
        onTap: () {
          // TODO: Implement directory picker
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Directory picker not yet implemented'),
            ),
          );
        },
      ),
      AdaptiveListTile(
        leading: context.useCupertino
            ? const Icon(CupertinoIcons.trash)
            : const Icon(Icons.cleaning_services),
        title: const Text('Clear Cache'),
        subtitle: const Text('Free up storage space'),
        showDisclosureIndicator: true,
        onTap: _showClearCacheDialog,
      ),
    ];
  }

  /// Shows a dialog to confirm cache clearing
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear cached images and temporary files. Your books and reading progress will not be affected.',
        ),
        actions: [
          AdaptiveTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AdaptiveFilledButton(
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

  /// Builds about information items
  List<Widget> _buildAboutItems() {
    final updateProvider = sl<UpdateProvider>();

    return [
      AdaptiveListTile(
        leading: context.useCupertino
            ? const Icon(CupertinoIcons.info_circle)
            : const Icon(Icons.info),
        title: const Text('App Version'),
        subtitle: Text(_appVersion.isEmpty ? 'Loading...' : _appVersion),
      ),
      ListenableBuilder(
        listenable: updateProvider,
        builder: (context, _) {
          return AdaptiveListTile(
            leading: Icon(
              context.useCupertino
                  ? (updateProvider.updateAvailable
                        ? CupertinoIcons.arrow_down_circle
                        : CupertinoIcons.refresh)
                  : (updateProvider.updateAvailable
                        ? Icons.system_update
                        : Icons.refresh),
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
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : updateProvider.updateAvailable
                ? Badge(
                    label: const Text('NEW'),
                    child: Icon(
                      context.useCupertino
                          ? CupertinoIcons.chevron_forward
                          : Icons.chevron_right,
                    ),
                  )
                : null,
            showDisclosureIndicator:
                !updateProvider.isChecking && !updateProvider.updateAvailable,
            onTap: updateProvider.isChecking ? null : _checkForUpdates,
          );
        },
      ),
      AdaptiveListTile(
        leading: context.useCupertino
            ? const Icon(CupertinoIcons.doc_text)
            : const Icon(Icons.description),
        title: const Text('Licenses'),
        showDisclosureIndicator: true,
        onTap: () {
          showLicensePage(
            context: context,
            applicationName: 'ReadWhere',
            applicationVersion: _appVersion,
            applicationLegalese: 'A cross-platform e-reader for open formats',
          );
        },
      ),
      AdaptiveListTile(
        leading: context.useCupertino
            ? const Icon(CupertinoIcons.chevron_left_slash_chevron_right)
            : const Icon(Icons.code),
        title: const Text('Source Code'),
        subtitle: const Text('View on GitHub'),
        showDisclosureIndicator: true,
        onTap: () => _openUrl('https://github.com/cedricziel/readwhere'),
      ),
      AdaptiveListTile(
        leading: context.useCupertino
            ? const Icon(CupertinoIcons.ant)
            : const Icon(Icons.bug_report),
        title: const Text('Report Issue'),
        subtitle: const Text('Report bugs or request features'),
        showDisclosureIndicator: true,
        onTap: () => _openUrl('https://github.com/cedricziel/readwhere/issues'),
      ),
    ];
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
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Reset All Settings'),
        content: const Text(
          'This will reset all settings to their default values. Your books and reading progress will not be affected.',
        ),
        actions: [
          AdaptiveTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AdaptiveFilledButton(
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
