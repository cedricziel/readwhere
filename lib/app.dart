import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/update_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/widgets/update_dialog.dart';

final _log = Logger('ReadWhereApp');

/// The root widget of the ReadWhere application.
///
/// This widget sets up:
/// - The app router using go_router
/// - The app theme with Material Design 3
/// - Theme mode from SettingsProvider
/// - Global configuration like title and debug banner
class ReadWhereApp extends StatefulWidget {
  const ReadWhereApp({super.key});

  @override
  State<ReadWhereApp> createState() => _ReadWhereAppState();
}

class _ReadWhereAppState extends State<ReadWhereApp> {
  late final _router = createAppRouter();
  bool _updateCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleUpdateCheck();
  }

  /// Schedules an update check after the first frame.
  void _scheduleUpdateCheck() {
    if (_updateCheckScheduled) return;
    _updateCheckScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesOnStartup();
    });
  }

  /// Checks for updates on app startup and shows dialog if available.
  ///
  /// This runs silently - network errors are logged but not shown to the user.
  /// The user can manually check for updates in Settings if they want to see errors.
  Future<void> _checkForUpdatesOnStartup() async {
    final updateProvider = sl<UpdateProvider>();

    try {
      await updateProvider.checkOnStartup();
    } catch (e) {
      // Log but don't show error to user on startup
      _log.warning('Failed to check for updates on startup: $e');
      return;
    }

    if (!mounted) return;

    // Log the result
    if (updateProvider.error != null) {
      _log.info('Update check failed: ${updateProvider.error}');
    } else if (updateProvider.updateAvailable) {
      _log.info('Update available: ${updateProvider.updateInfo?.version}');
    } else {
      _log.fine('No updates available');
    }

    // Show update dialog if an update is available
    if (updateProvider.updateAvailable && updateProvider.updateInfo != null) {
      // Get the navigator context from the router
      final context = _router.routerDelegate.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        await UpdateDialog.show(
          context,
          updateInfo: updateProvider.updateInfo!,
          currentVersion: updateProvider.currentVersion ?? 'unknown',
          onDismiss: () => updateProvider.dismissUpdate(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp.router(
          title: 'ReadWhere',
          debugShowCheckedModeBanner: false,

          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsProvider.themeMode,

          // Router configuration
          routerConfig: _router,
        );
      },
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
