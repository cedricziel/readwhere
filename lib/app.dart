import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'presentation/providers/library_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/update_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/themes/cupertino_theme.dart';
import 'presentation/widgets/macos/file_drop_target_wrapper.dart';
import 'presentation/widgets/macos/platform_menu_bar_wrapper.dart';
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
        // macOS: Use MacosApp for full macos_ui integration
        if (!kIsWeb && Platform.isMacOS) {
          return _buildMacosApp(settingsProvider);
        }

        // iOS, Android, Web: Use MaterialApp with adaptive widgets
        return _buildMaterialApp(settingsProvider);
      },
    );
  }

  /// Builds the macOS-specific app with native sidebar, menu bar, and drag-drop.
  Widget _buildMacosApp(SettingsProvider settingsProvider) {
    // Determine macOS theme based on settings
    final brightness = _effectiveBrightness(settingsProvider.themeMode);
    final macosTheme = brightness == Brightness.dark
        ? MacosThemeData.dark()
        : MacosThemeData.light();

    Widget app = MacosApp.router(
      title: 'ReadWhere',
      debugShowCheckedModeBanner: false,
      theme: macosTheme,
      darkTheme: MacosThemeData.dark(),
      themeMode: settingsProvider.themeMode,
      routerConfig: _router,
    );

    // Wrap with file drop target for drag-and-drop import
    app = FileDropTargetWrapper(
      onFilesDropped: _handleDroppedFiles,
      child: app,
    );

    // Wrap with platform menu bar
    app = PlatformMenuBarWrapper(
      router: _router,
      onOpenBook: _handleOpenBook,
      onSearch: _handleSearch,
      child: app,
    );

    return app;
  }

  /// Builds the standard MaterialApp for iOS, Android, and Web.
  Widget _buildMaterialApp(SettingsProvider settingsProvider) {
    // Determine effective brightness for Cupertino theme
    final brightness = _effectiveBrightness(settingsProvider.themeMode);

    Widget app = CupertinoTheme(
      data: AppCupertinoTheme.fromBrightness(brightness),
      child: MaterialApp.router(
        title: 'ReadWhere',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settingsProvider.themeMode,

        // Router configuration
        routerConfig: _router,
      ),
    );

    // Add file drop target for Windows and Linux
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      app = FileDropTargetWrapper(
        onFilesDropped: _handleDroppedFiles,
        child: app,
      );
    }

    return app;
  }

  /// Handles files dropped via drag-and-drop.
  void _handleDroppedFiles(List<String> filePaths) {
    _log.info('Files dropped: $filePaths');

    // Get the library provider and import the files
    if (sl.isRegistered<LibraryProvider>()) {
      final libraryProvider = sl<LibraryProvider>();
      for (final path in filePaths) {
        libraryProvider.importBook(path);
      }
    }
  }

  /// Handles the "Open Book" menu action.
  void _handleOpenBook() {
    _log.info('Open book menu action');
    // This could trigger a file picker dialog
    // For now, just navigate to library
    _router.go('/library');
  }

  /// Handles the "Search" menu action.
  void _handleSearch() {
    _log.info('Search menu action');
    // Navigate to library and focus search
    _router.go('/library');
    // TODO: Need a way to communicate to LibraryScreen to focus search
  }

  /// Returns the effective brightness based on theme mode.
  Brightness _effectiveBrightness(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
