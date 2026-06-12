import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database_utils.dart';
import 'widget_flow_utils.dart';

void main() {
  late Directory databaseSandbox;

  setUpAll(() async {
    databaseSandbox = await configureTestDatabases('fit_diary_nutrition_test_');
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

  testWidgets('adds a meal entry and updates the nutrition summary', (
    WidgetTester tester,
  ) async {
    await pumpFitDiary(tester);

    await tapStartCard(tester, 'Nutrition');
    await pumpUntilFound(tester, find.text('Add Meal'));

    await tester.tap(find.text('Add Meal'));
    await pumpUi(tester);
    await pumpUntilFound(tester, find.text('Save Meal'));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Oat bowl');
    await tester.enterText(fields.at(1), '520');
    await tester.enterText(fields.at(2), '34');
    await tester.enterText(fields.at(3), 'Good breakfast');

    await dragBottomSheetToActions(tester);
    await tester.ensureVisible(find.text('Save Meal'));
    await tester.pump();
    await tester.tap(find.text('Save Meal'));
    await pumpUntilGone(tester, find.text('Save Meal'));
    await pumpUntilFound(tester, find.text('Oat bowl'));

    expect(find.text('Oat bowl'), findsWidgets);
    expect(find.text('520'), findsWidgets);
    expect(find.text('34'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
