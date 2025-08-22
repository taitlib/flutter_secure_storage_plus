import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage_plus_example/main.dart';

void main() {
  testWidgets('Write, read, and delete value in example app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Enter key and value
    await tester.enterText(find.byType(TextField).at(0), 'integration_key');
    await tester.enterText(find.byType(TextField).at(1), 'integration_value');

    // Tap Write
    await tester.tap(find.widgetWithText(ElevatedButton, 'Write'));
    await tester.pumpAndSettle();
    expect(find.text('Value written!'), findsOneWidget);

    // Tap Read
    await tester.tap(find.widgetWithText(ElevatedButton, 'Read'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Value read: integration_value'),
      findsOneWidget,
    );
    expect(find.text('Stored value: integration_value'), findsOneWidget);

    // Tap Delete
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Value deleted!'), findsOneWidget);
    expect(find.text('Stored value: integration_value'), findsNothing);
  });
}
