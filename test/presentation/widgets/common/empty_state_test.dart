import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/presentation/widgets/common/empty_state.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('EmptyState', () {
    group('rendering', () {
      testWidgets('displays icon with correct icon data', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(icon: Icons.book, title: 'Test Title'),
        );

        expect(find.byIcon(Icons.book), findsOneWidget);
      });

      testWidgets('displays title text', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(icon: Icons.book, title: 'No Books Found'),
        );

        expect(find.text('No Books Found'), findsOneWidget);
      });

      testWidgets('displays subtitle when provided', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(
            icon: Icons.book,
            title: 'Test Title',
            subtitle: 'This is a helpful subtitle',
          ),
        );

        expect(find.text('This is a helpful subtitle'), findsOneWidget);
      });

      testWidgets('hides subtitle when null', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(
            icon: Icons.book,
            title: 'Test Title',
            subtitle: null,
          ),
        );

        // Should only find title, not a second Text widget for subtitle
        expect(find.byType(Text), findsOneWidget);
      });

      testWidgets(
        'displays action button when actionLabel and onAction provided',
        (tester) async {
          await tester.pumpMaterialApp(
            EmptyState(
              icon: Icons.book,
              title: 'Test Title',
              actionLabel: 'Add Book',
              onAction: () {},
            ),
          );

          // FilledButton.icon creates a private _FilledButtonWithIcon
          // Check that the button text and icon are present
          expect(find.text('Add Book'), findsOneWidget);
          expect(find.byIcon(Icons.add), findsOneWidget);
        },
      );

      testWidgets('hides action button when actionLabel is null', (
        tester,
      ) async {
        await tester.pumpMaterialApp(
          const EmptyState(icon: Icons.book, title: 'Test Title'),
        );

        expect(find.byType(FilledButton), findsNothing);
      });

      testWidgets('applies custom icon size when provided', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(
            icon: Icons.book,
            title: 'Test Title',
            iconSize: 100,
          ),
        );

        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.book));
        expect(iconWidget.size, 100);
      });

      testWidgets('uses default icon size of 64 when not provided', (
        tester,
      ) async {
        await tester.pumpMaterialApp(
          const EmptyState(icon: Icons.book, title: 'Test Title'),
        );

        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.book));
        expect(iconWidget.size, 64);
      });

      testWidgets('applies custom icon color when provided', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(
            icon: Icons.book,
            title: 'Test Title',
            iconColor: Colors.red,
          ),
        );

        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.book));
        expect(iconWidget.color, Colors.red);
      });

      testWidgets('action button has add icon', (tester) async {
        await tester.pumpMaterialApp(
          EmptyState(
            icon: Icons.book,
            title: 'Test Title',
            actionLabel: 'Add Book',
            onAction: () {},
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('calls onAction when action button tapped', (tester) async {
        var tapped = false;

        await tester.pumpMaterialApp(
          EmptyState(
            icon: Icons.book,
            title: 'Test Title',
            actionLabel: 'Add Book',
            onAction: () => tapped = true,
          ),
        );

        // Tap on the button text to trigger the action
        await tester.tap(find.text('Add Book'));
        await tester.pump();

        expect(tapped, isTrue);
      });
    });

    group('layout', () {
      testWidgets('is centered in parent', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(icon: Icons.book, title: 'Test Title'),
        );

        // EmptyState uses Center widget - there may be multiple Center widgets
        // from MaterialApp, so check that EmptyState's content is descendant of a Center
        expect(
          find.descendant(
            of: find.byType(Center),
            matching: find.byIcon(Icons.book),
          ),
          findsOneWidget,
        );
      });

      testWidgets('has correct padding', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(icon: Icons.book, title: 'Test Title'),
        );

        final paddingWidget = tester.widget<Padding>(
          find.descendant(
            of: find.byType(Center),
            matching: find.byType(Padding).first,
          ),
        );
        expect(paddingWidget.padding, const EdgeInsets.all(32.0));
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light mode', (tester) async {
        await tester.pumpMaterialApp(
          const EmptyState(icon: Icons.book, title: 'Test Title'),
          theme: ThemeData.light(),
        );

        // Widget should render without errors
        expect(find.byType(EmptyState), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        await tester.pumpDarkTheme(
          const EmptyState(icon: Icons.book, title: 'Test Title'),
        );

        // Widget should render without errors
        expect(find.byType(EmptyState), findsOneWidget);
      });
    });

    group('assertions', () {
      testWidgets('throws assertion if actionLabel without onAction', (
        tester,
      ) async {
        expect(
          () => EmptyState(
            icon: Icons.book,
            title: 'Test',
            actionLabel: 'Test',
            // Missing onAction
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      testWidgets('throws assertion if onAction without actionLabel', (
        tester,
      ) async {
        expect(
          () => EmptyState(
            icon: Icons.book,
            title: 'Test',
            onAction: () {},
            // Missing actionLabel
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}
