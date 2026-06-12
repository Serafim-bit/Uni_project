import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database_utils.dart';
import 'widget_flow_utils.dart';

void main() {
  late Directory databaseSandbox;

  setUpAll(() async {
    databaseSandbox = await configureTestDatabases('fit_diary_notes_test_');
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

  testWidgets('adds, edits, and deletes a note', (WidgetTester tester) async {
    await pumpFitDiary(tester);

    await tapStartCard(tester, 'Notes');
    await pumpUntilFound(tester, find.text('No notes yet'));

    await tester.tap(find.text('Add Note'));
    await pumpUntilFound(tester, find.text('Title'));

    var fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Buy groceries');
    await tester.enterText(fields.at(1), 'Eggs, oats, berries');
    await tapSaveNote(tester);
    await pumpUntilFound(
      tester,
      find.widgetWithText(ListTile, 'Buy groceries'),
    );

    expect(
      find.widgetWithText(ListTile, 'Eggs, oats, berries'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ListTile, 'Buy groceries'));
    await pumpUntilFound(tester, find.text('Edit Note'));

    fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Meal prep');
    await tester.enterText(fields.at(1), 'Chicken, rice, vegetables');
    await tapSaveNote(tester);
    await pumpUntilFound(tester, find.widgetWithText(ListTile, 'Meal prep'));

    expect(find.widgetWithText(ListTile, 'Buy groceries'), findsNothing);
    expect(
      find.widgetWithText(ListTile, 'Chicken, rice, vegetables'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.delete));
    await pumpUntilFound(tester, find.text('No notes yet'));

    expect(find.widgetWithText(ListTile, 'Meal prep'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> tapSaveNote(WidgetTester tester) async {
  await tester.tap(
    find
        .ancestor(
          of: find.text('Save').last,
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton,
          ),
        )
        .last,
  );
}
