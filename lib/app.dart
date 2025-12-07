import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/themes/app_theme.dart';

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
