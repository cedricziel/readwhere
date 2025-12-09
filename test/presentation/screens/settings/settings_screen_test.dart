import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readwhere/domain/entities/reading_settings.dart';
import 'package:readwhere/presentation/providers/settings_provider.dart';
import 'package:readwhere/presentation/providers/update_provider.dart';
import 'package:readwhere/presentation/screens/settings/settings_screen.dart';

import '../../../mocks/mock_repositories.mocks.dart';

void main() {
  late MockSettingsProvider mockSettingsProvider;
  late MockUpdateProvider mockUpdateProvider;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockUpdateProvider = MockUpdateProvider();

    // Register mock in service locator
    final sl = GetIt.instance;
    if (sl.isRegistered<UpdateProvider>()) {
      sl.unregister<UpdateProvider>();
    }
    sl.registerSingleton<UpdateProvider>(mockUpdateProvider);

    // Stub UpdateProvider
    when(mockUpdateProvider.isChecking).thenReturn(false);
    when(mockUpdateProvider.updateAvailable).thenReturn(false);
    when(mockUpdateProvider.updateInfo).thenReturn(null);
    when(mockUpdateProvider.error).thenReturn(null);

    // Default stubs for SettingsProvider
    when(mockSettingsProvider.themeMode).thenReturn(ThemeMode.system);
    when(mockSettingsProvider.hapticFeedback).thenReturn(true);
    when(mockSettingsProvider.keepScreenAwake).thenReturn(false);
    when(
      mockSettingsProvider.defaultReadingSettings,
    ).thenReturn(ReadingSettings.defaults());
  });

  tearDown(() {
    final sl = GetIt.instance;
    if (sl.isRegistered<UpdateProvider>()) {
      sl.unregister<UpdateProvider>();
    }
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<SettingsProvider>.value(
        value: mockSettingsProvider,
        child: const SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen', () {
    group('app bar', () {
      testWidgets('displays Settings title', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('Settings'), findsOneWidget);
      });
    });

    group('appearance section (visible initially)', () {
      testWidgets('displays Appearance section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('Appearance'), findsOneWidget);
      });

      testWidgets('displays System theme option', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('System'), findsOneWidget);
        expect(find.text('Follow system theme'), findsOneWidget);
      });

      testWidgets('displays Light theme option', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Always use light theme'), findsOneWidget);
      });

      testWidgets('displays Dark theme option', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('Dark'), findsOneWidget);
        expect(find.text('Always use dark theme'), findsOneWidget);
      });

      testWidgets('calls setThemeMode when Light is selected', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        await tester.tap(find.text('Light'));
        await tester.pump();

        verify(mockSettingsProvider.setThemeMode(ThemeMode.light)).called(1);
      });

      testWidgets('calls setThemeMode when Dark is selected', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        await tester.tap(find.text('Dark'));
        await tester.pump();

        verify(mockSettingsProvider.setThemeMode(ThemeMode.dark)).called(1);
      });

      testWidgets('shows correct theme selected', (tester) async {
        when(mockSettingsProvider.themeMode).thenReturn(ThemeMode.dark);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Radio buttons should be displayed
        expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(3));
      });
    });

    group('reading section', () {
      testWidgets('displays Reading section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('Reading'), findsOneWidget);
      });

      testWidgets('displays font size slider', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.textContaining('Font Size:'), findsOneWidget);
        expect(find.byType(Slider), findsAtLeast(1));
      });

      testWidgets('displays font family selector', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('Font Family'), findsOneWidget);
        expect(find.text('Georgia'), findsOneWidget);
      });

      testWidgets('opens font family dialog when tapped', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        await tester.tap(find.text('Font Family'));
        await tester.pumpAndSettle();

        expect(find.text('Select Font Family'), findsOneWidget);
        expect(find.text('Arial'), findsOneWidget);
        expect(find.text('Helvetica'), findsOneWidget);
      });
    });

    group('app behavior section (scrolling needed)', () {
      testWidgets('displays haptic feedback toggle when scrolled', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Scroll to find the toggle
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('Haptic Feedback'), findsOneWidget);
      });

      testWidgets('displays keep screen awake toggle when scrolled', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Scroll to find the toggle
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('Keep Screen Awake'), findsOneWidget);
      });

      testWidgets('calls setHapticFeedback when toggled', (tester) async {
        when(mockSettingsProvider.hapticFeedback).thenReturn(true);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Scroll to find the toggle
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        // Find and tap the haptic feedback switch
        await tester.tap(find.text('Haptic Feedback'));
        await tester.pump();

        verify(mockSettingsProvider.setHapticFeedback(false)).called(1);
      });
    });

    group('storage section', () {
      testWidgets('displays storage section when scrolled', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Scroll down
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Storage'), findsOneWidget);
      });

      testWidgets('displays Clear Cache option when scrolled', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Scroll down
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Clear Cache'), findsOneWidget);
      });

      testWidgets('shows clear cache confirmation dialog', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Scroll down multiple times to make Clear Cache fully visible and tappable
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        // Tap Clear Cache
        await tester.tap(find.text('Clear Cache'));
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('clear cached images'), findsOneWidget);
      });
    });

    group('about section', () {
      testWidgets('displays about section when scrolled far enough', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Scroll down multiple times to reach the About section
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('About'), findsOneWidget);
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider,
              child: const SettingsScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider,
              child: const SettingsScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });
  });
}
