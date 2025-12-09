import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/presentation/router/routes.dart';
import 'package:readwhere/presentation/widgets/adaptive/adaptive_scaffold.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  // Test destinations
  const testDestinations = [
    AppNavigationDestination(
      label: 'Library',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
      route: '/library',
    ),
    AppNavigationDestination(
      label: 'Catalogs',
      icon: Icons.cloud_outlined,
      selectedIcon: Icons.cloud,
      route: '/catalogs',
    ),
    AppNavigationDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: '/settings',
    ),
  ];

  Widget buildScaffold({
    required Size screenSize,
    int selectedIndex = 0,
    ValueChanged<int>? onDestinationSelected,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: AdaptiveScaffold(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected ?? (_) {},
          destinations: testDestinations,
          child: const Center(child: Text('Content')),
        ),
      ),
    );
  }

  group('AdaptiveScaffold', () {
    group('mobile layout (< 600px)', () {
      testWidgets('displays NavigationBar at bottom', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.mobile);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.mobile),
        );

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      });

      testWidgets('hides NavigationRail', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.mobile);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.mobile),
        );

        expect(find.byType(NavigationRail), findsNothing);
      });

      testWidgets('shows correct number of destinations', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.mobile);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.mobile),
        );

        expect(find.byType(NavigationDestination), findsNWidgets(3));
      });

      testWidgets('displays destination labels', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.mobile);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.mobile),
        );

        expect(find.text('Library'), findsOneWidget);
        expect(find.text('Catalogs'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('calls onDestinationSelected when destination tapped', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.mobile);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int? selectedIndex;
        await tester.pumpWidget(
          buildScaffold(
            screenSize: TestScreenSizes.mobile,
            onDestinationSelected: (index) => selectedIndex = index,
          ),
        );

        // Tap on Catalogs (index 1)
        await tester.tap(find.text('Catalogs'));
        await tester.pump();

        expect(selectedIndex, 1);
      });

      testWidgets('displays content', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.mobile);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.mobile),
        );

        expect(find.text('Content'), findsOneWidget);
      });
    });

    group('tablet layout (600-1200px)', () {
      testWidgets('displays collapsed NavigationRail', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.tablet);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.tablet),
        );

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.extended, isFalse);
      });

      testWidgets('hides NavigationBar', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.tablet);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.tablet),
        );

        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('shows labels on rail', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.tablet);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.tablet),
        );

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.labelType, NavigationRailLabelType.all);
      });

      testWidgets('has vertical divider after rail', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.tablet);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.tablet),
        );

        expect(find.byType(VerticalDivider), findsOneWidget);
      });

      testWidgets('calls onDestinationSelected when rail destination tapped', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.tablet);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int? selectedIndex;
        await tester.pumpWidget(
          buildScaffold(
            screenSize: TestScreenSizes.tablet,
            onDestinationSelected: (index) => selectedIndex = index,
          ),
        );

        // Tap on Settings icon (third destination)
        // NavigationRailDestination isn't tappable directly - tap the icon
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pump();

        expect(selectedIndex, 2);
      });
    });

    group('desktop layout (>= 1200px)', () {
      testWidgets('displays extended NavigationRail', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.desktop);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.desktop),
        );

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.extended, isTrue);
      });

      testWidgets('hides NavigationBar', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.desktop);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.desktop),
        );

        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('hides labels when extended (shows in rail itself)', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.desktop);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.desktop),
        );

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        // When extended, labelType should be none (labels shown in extended rail)
        expect(rail.labelType, NavigationRailLabelType.none);
      });
    });

    group('breakpoint transitions', () {
      testWidgets('switches from mobile to tablet at 600px', (tester) async {
        // Just below tablet threshold
        await tester.binding.setSurfaceSize(TestScreenSizes.belowTablet);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.belowTablet),
        );

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);

        // At tablet threshold
        await tester.binding.setSurfaceSize(TestScreenSizes.atTablet);

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.atTablet),
        );

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('switches from tablet to desktop at 1200px', (tester) async {
        // Just below desktop threshold
        await tester.binding.setSurfaceSize(TestScreenSizes.belowDesktop);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.belowDesktop),
        );

        final collapsedRail = tester.widget<NavigationRail>(
          find.byType(NavigationRail),
        );
        expect(collapsedRail.extended, isFalse);

        // At desktop threshold
        await tester.binding.setSurfaceSize(TestScreenSizes.atDesktop);

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.atDesktop),
        );

        final extendedRail = tester.widget<NavigationRail>(
          find.byType(NavigationRail),
        );
        expect(extendedRail.extended, isTrue);
      });
    });

    group('selected index', () {
      testWidgets('highlights selected destination on mobile', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.mobile);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.mobile, selectedIndex: 1),
        );

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 1);
      });

      testWidgets('highlights selected destination on tablet', (tester) async {
        await tester.binding.setSurfaceSize(TestScreenSizes.tablet);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildScaffold(screenSize: TestScreenSizes.tablet, selectedIndex: 2),
        );

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, 2);
      });
    });
  });
}
