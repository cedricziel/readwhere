import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/presentation/widgets/common/loading_indicator.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LoadingIndicator', () {
    group('rendering', () {
      testWidgets('displays CircularProgressIndicator', (tester) async {
        await tester.pumpMaterialApp(const LoadingIndicator());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('displays message when provided', (tester) async {
        await tester.pumpMaterialApp(
          const LoadingIndicator(message: 'Loading books...'),
        );

        expect(find.text('Loading books...'), findsOneWidget);
      });

      testWidgets('hides message when null', (tester) async {
        await tester.pumpMaterialApp(const LoadingIndicator());

        // Should only have the CircularProgressIndicator, no Text
        expect(find.byType(Text), findsNothing);
      });

      testWidgets('applies custom size when provided', (tester) async {
        await tester.pumpMaterialApp(const LoadingIndicator(size: 48));

        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(SizedBox).first,
          ),
        );
        expect(sizedBox.width, 48);
        expect(sizedBox.height, 48);
      });

      testWidgets('applies custom color when provided', (tester) async {
        await tester.pumpMaterialApp(const LoadingIndicator(color: Colors.red));

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(
          indicator.valueColor,
          isA<AlwaysStoppedAnimation<Color>>().having(
            (a) => a.value,
            'color',
            Colors.red,
          ),
        );
      });

      testWidgets('uses default color when not provided', (tester) async {
        await tester.pumpMaterialApp(const LoadingIndicator());

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.valueColor, isNull);
      });

      testWidgets('adjusts stroke width based on size', (tester) async {
        await tester.pumpMaterialApp(const LoadingIndicator(size: 80));

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        // strokeWidth = size / 8 = 80 / 8 = 10
        expect(indicator.strokeWidth, 10);
      });

      testWidgets('uses default stroke width when size not provided', (
        tester,
      ) async {
        await tester.pumpMaterialApp(const LoadingIndicator());

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.strokeWidth, 4.0);
      });
    });

    group('layout', () {
      testWidgets('is centered in parent', (tester) async {
        await tester.pumpMaterialApp(const LoadingIndicator());

        expect(
          find.descendant(
            of: find.byType(Center),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
      });

      testWidgets('message is centered below indicator', (tester) async {
        await tester.pumpMaterialApp(
          const LoadingIndicator(message: 'Loading...'),
        );

        expect(find.byType(Column), findsOneWidget);
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisAlignment, MainAxisAlignment.center);
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light mode', (tester) async {
        await tester.pumpMaterialApp(
          const LoadingIndicator(message: 'Loading...'),
          theme: ThemeData.light(),
        );

        expect(find.byType(LoadingIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('renders correctly in dark mode', (tester) async {
        await tester.pumpDarkTheme(
          const LoadingIndicator(message: 'Loading...'),
        );

        expect(find.byType(LoadingIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });

  group('CompactLoadingIndicator', () {
    group('rendering', () {
      testWidgets('displays CircularProgressIndicator', (tester) async {
        await tester.pumpMaterialApp(const CompactLoadingIndicator());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('defaults to size 16', (tester) async {
        await tester.pumpMaterialApp(const CompactLoadingIndicator());

        final sizedBox = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(CircularProgressIndicator),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.width, 16);
        expect(sizedBox.height, 16);
      });

      testWidgets('applies custom size when provided', (tester) async {
        await tester.pumpMaterialApp(const CompactLoadingIndicator(size: 24));

        final sizedBox = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(CircularProgressIndicator),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.width, 24);
        expect(sizedBox.height, 24);
      });

      testWidgets('applies custom color when provided', (tester) async {
        await tester.pumpMaterialApp(
          const CompactLoadingIndicator(color: Colors.blue),
        );

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(
          indicator.valueColor,
          isA<AlwaysStoppedAnimation<Color>>().having(
            (a) => a.value,
            'color',
            Colors.blue,
          ),
        );
      });

      testWidgets('uses default color when not provided', (tester) async {
        await tester.pumpMaterialApp(const CompactLoadingIndicator());

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.valueColor, isNull);
      });

      testWidgets('stroke width is proportional to size', (tester) async {
        await tester.pumpMaterialApp(const CompactLoadingIndicator(size: 32));

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        // strokeWidth = size / 8 = 32 / 8 = 4
        expect(indicator.strokeWidth, 4);
      });

      testWidgets('default stroke width for default size', (tester) async {
        await tester.pumpMaterialApp(const CompactLoadingIndicator());

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        // strokeWidth = 16 / 8 = 2
        expect(indicator.strokeWidth, 2);
      });
    });

    group('layout', () {
      testWidgets('is not centered (inline)', (tester) async {
        await tester.pumpMaterialApp(const CompactLoadingIndicator());

        // CompactLoadingIndicator doesn't wrap itself in Center
        final sizedBoxFinder = find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        );
        expect(sizedBoxFinder, findsOneWidget);

        // The MaterialApp adds a Center, but it's not part of CompactLoadingIndicator
        // Just verify the SizedBox directly contains the indicator
      });
    });
  });
}
