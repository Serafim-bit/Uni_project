import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'test_database_utils.dart';
import 'widget_flow_utils.dart';

void main() {
  late Directory databaseSandbox;

  setUpAll(() async {
    databaseSandbox = await configureTestDatabases('fit_diary_guide_test_');
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

  testWidgets('opens a training area, muscle group, and exercise details', (
    WidgetTester tester,
  ) async {
    await pumpFitDiary(tester);

    await tapStartCard(tester, 'Exercise Guide');
    await pumpUntilFound(tester, find.text('Upper Body'));

    await tester.tap(find.text('Upper Body'));
    await pumpUntilFound(tester, find.text('Back'));

    await tester.tap(find.text('Back'));
    await pumpUntilFound(tester, find.text('Wide-Grip Pull-Ups'));

    await tester.tap(find.text('Wide-Grip Pull-Ups'));
    await pumpUntilFound(tester, find.text('Wide-Grip Pull-Ups'));
    await pumpUntilFound(tester, find.text('Technique'));

    expect(tester.takeException(), isNull);
  });
}
