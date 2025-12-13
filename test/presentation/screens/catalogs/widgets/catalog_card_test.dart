import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/catalog.dart';
import 'package:readwhere/presentation/screens/catalogs/widgets/catalog_card.dart';

import '../../../../helpers/catalog_test_helpers.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CatalogCard', () {
    group('rendering', () {
      testWidgets('displays catalog name', (tester) async {
        final catalog = createTestCatalog(name: 'My Server');

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        expect(find.text('My Server'), findsOneWidget);
      });

      testWidgets('displays formatted URL without protocol', (tester) async {
        final catalog = createTestCatalog(url: 'https://example.com/catalog');

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        expect(find.text('example.com/catalog'), findsOneWidget);
      });

      testWidgets('displays Kavita badge for Kavita servers', (tester) async {
        final catalog = createTestKavitaServer();

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        expect(find.text('Kavita'), findsOneWidget);
      });

      testWidgets('does not display Kavita badge for OPDS catalogs', (
        tester,
      ) async {
        final catalog = createTestCatalog(type: CatalogType.opds);

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        expect(find.text('Kavita'), findsNothing);
      });

      testWidgets('has more options menu button', (tester) async {
        final catalog = createTestCatalog();

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('calls onTap when card is tapped', (tester) async {
        var tapped = false;
        final catalog = createTestCatalog();

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(
              catalog: catalog,
              onTap: () => tapped = true,
              onDelete: () {},
            ),
          ),
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('shows Remove menu item when menu opened', (tester) async {
        final catalog = createTestCatalog();

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Remove'), findsOneWidget);
      });

      testWidgets('calls onDelete when Remove is selected', (tester) async {
        var deleted = false;
        final catalog = createTestCatalog();

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(
              catalog: catalog,
              onTap: () {},
              onDelete: () => deleted = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        expect(deleted, isTrue);
      });
    });

    group('change folder menu', () {
      testWidgets('shows Change Starting Folder for Nextcloud with callback', (
        tester,
      ) async {
        final catalog = createTestNextcloudServer();

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(
              catalog: catalog,
              onTap: () {},
              onDelete: () {},
              onChangeFolder: () {},
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Change Starting Folder'), findsOneWidget);
        expect(find.byIcon(Icons.folder_open), findsOneWidget);
      });

      testWidgets('does not show Change Starting Folder for non-Nextcloud', (
        tester,
      ) async {
        final catalog = createTestKavitaServer();

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(
              catalog: catalog,
              onTap: () {},
              onDelete: () {},
              onChangeFolder: () {},
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Change Starting Folder'), findsNothing);
      });

      testWidgets(
        'does not show Change Starting Folder when callback is null',
        (tester) async {
          final catalog = createTestNextcloudServer();

          await tester.pumpWidget(
            buildTestWidget(
              CatalogCard(
                catalog: catalog,
                onTap: () {},
                onDelete: () {},
                // onChangeFolder is null
              ),
            ),
          );

          await tester.tap(find.byIcon(Icons.more_vert));
          await tester.pumpAndSettle();

          expect(find.text('Change Starting Folder'), findsNothing);
        },
      );

      testWidgets(
        'calls onChangeFolder when Change Starting Folder is selected',
        (tester) async {
          var changeFolderCalled = false;
          final catalog = createTestNextcloudServer();

          await tester.pumpWidget(
            buildTestWidget(
              CatalogCard(
                catalog: catalog,
                onTap: () {},
                onDelete: () {},
                onChangeFolder: () => changeFolderCalled = true,
              ),
            ),
          );

          await tester.tap(find.byIcon(Icons.more_vert));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Change Starting Folder'));
          await tester.pumpAndSettle();

          expect(changeFolderCalled, isTrue);
        },
      );

      testWidgets(
        'OPDS catalog does not show change folder even with callback',
        (tester) async {
          final catalog = createTestCatalog(type: CatalogType.opds);

          await tester.pumpWidget(
            buildTestWidget(
              CatalogCard(
                catalog: catalog,
                onTap: () {},
                onDelete: () {},
                onChangeFolder: () {},
              ),
            ),
          );

          await tester.tap(find.byIcon(Icons.more_vert));
          await tester.pumpAndSettle();

          expect(find.text('Change Starting Folder'), findsNothing);
        },
      );
    });

    group('URL formatting', () {
      testWidgets('removes https:// from URL', (tester) async {
        final catalog = createTestCatalog(url: 'https://example.com/path');

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        expect(find.text('example.com/path'), findsOneWidget);
      });

      testWidgets('removes http:// from URL', (tester) async {
        final catalog = createTestCatalog(url: 'http://example.com/path');

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        expect(find.text('example.com/path'), findsOneWidget);
      });

      testWidgets('removes trailing slash from URL', (tester) async {
        final catalog = createTestCatalog(url: 'https://example.com/path/');

        await tester.pumpWidget(
          buildTestWidget(
            CatalogCard(catalog: catalog, onTap: () {}, onDelete: () {}),
          ),
        );

        expect(find.text('example.com/path'), findsOneWidget);
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light mode', (tester) async {
        final catalog = createTestCatalog();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: CatalogCard(
                catalog: catalog,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byType(CatalogCard), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        final catalog = createTestCatalog();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: CatalogCard(
                catalog: catalog,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byType(CatalogCard), findsOneWidget);
      });
    });
  });
}
