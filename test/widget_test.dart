import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'test_database_utils.dart';
import 'widget_flow_utils.dart';

void main() {
  late Directory databaseSandbox;

  setUpAll(() async {
    databaseSandbox = await configureTestDatabases('fit_diary_widget_test_');
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

  testWidgets('shows the Fit Diary start screen', (WidgetTester tester) async {
    await pumpFitDiary(tester);

    expect(find.text('Fit Diary'), findsOneWidget);
    expect(find.text('Exercise Guide'), findsOneWidget);
    expect(find.text('Workout Log'), findsOneWidget);
    expect(find.text('Nutrition'), findsWidgets);
    expect(find.text('Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
