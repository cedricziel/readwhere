import 'package:flutter_test/flutter_test.dart';

import 'package:readwhere_widgetbook/main.dart';

void main() {
  testWidgets('Widgetbook app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const WidgetbookApp());
    await tester.pumpAndSettle();

    // Verify the Widgetbook loads without crashing
    expect(find.byType(WidgetbookApp), findsOneWidget);
  });
}
