import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database_utils.dart';
import 'widget_flow_utils.dart';

void main() {
  late Directory databaseSandbox;

  setUpAll(() async {
    databaseSandbox = await configureTestDatabases('fit_diary_recipes_test_');
  });

  setUp(resetAppDatabasesForTesting);

  tearDownAll(() async {
    await closeAppDatabasesForTesting();
    if (await databaseSandbox.exists()) {
      try {
        await databaseSandbox.delete(recursive: true);
      } on FileSystemException {
        // The sqflite ffi isolate can briefly keep Windows file handles open.
      }
    }
  });

  testWidgets('searches, filters, favorites, and logs a recipe', (
    WidgetTester tester,
  ) async {
    await pumpFitDiary(tester, viewSize: const Size(390, 1200));

    await tapStartCard(tester, 'Nutrition');
    await pumpUntilFound(tester, find.text('Recipes'));

    expect(find.text('Nutrition'), findsWidgets);

    await tester.tap(find.text('Recipes'));
    await pumpUi(tester);

    expect(find.text('Italian'), findsOneWidget);

    await tester.tap(find.text('Italian'));
    await pumpUntilFound(tester, find.text('3 found'));

    expect(find.text('3 found'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'risotto');
    await pumpUi(tester);
    await scrollUntilTextVisible(tester, 'Mushroom Risotto');

    expect(find.text('Mushroom Risotto'), findsOneWidget);
    expect(find.text('Spaghetti with Tomato Sauce'), findsNothing);
    expect(find.byTooltip('Add to favorites'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Add to favorites'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add to favorites'));
    await pumpUntilFound(tester, find.byTooltip('Remove from favorites'));
    await tester.ensureVisible(find.text('Favorites only'));
    await tester.pump();
    await tester.tap(find.text('Favorites only'));
    await pumpUi(tester);
    await scrollUntilTextVisible(tester, 'Mushroom Risotto');

    expect(find.text('Mushroom Risotto'), findsOneWidget);

    await tester.ensureVisible(find.text('Add to Meal Log'));
    await tester.pump();
    await tester.tap(find.text('Add to Meal Log'));
    await pumpUntilFound(tester, find.text('Meal Log'));
    await pumpUntilFound(tester, find.text('Mushroom Risotto'));

    expect(find.text('Mushroom Risotto'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> scrollUntilTextVisible(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    280,
    scrollable: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  await tester.pump();
}
