import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database_utils.dart';
import 'widget_flow_utils.dart';

void main() {
  late Directory databaseSandbox;

  setUpAll(() async {
    databaseSandbox = await configureTestDatabases('fit_diary_workout_test_');
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

  Future<void> openWorkoutLog(
    WidgetTester tester, {
    Size viewSize = const Size(390, 844),
  }) async {
    await pumpFitDiary(tester, viewSize: viewSize);

    await tapStartCard(tester, 'Workout Log');
    await pumpUntilFound(tester, find.text('New Workout'));
  }

  Future<void> addWorkout(
    WidgetTester tester, {
    String focus = 'Back and biceps',
    String duration = '45',
    String exercises = 'Rows, pull-ups, curls',
  }) async {
    await tester.tap(find.text('New Workout'));
    await pumpUi(tester);
    await pumpUntilFound(tester, find.text('Save Workout'));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), focus);
    await tester.enterText(fields.at(1), duration);
    await tester.enterText(fields.at(2), exercises);

    await dragBottomSheetToActions(tester);
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.pump();
    await tester.tap(find.text('Save Workout'));
    await pumpUntilGone(tester, find.text('Save Workout'));
    await pumpUntilFound(tester, find.text('Progress overview'));
  }

  testWidgets('adds a workout without a photo and shows it in the log', (
    WidgetTester tester,
  ) async {
    await openWorkoutLog(tester);
    await addWorkout(tester);

    expect(find.text('Progress overview'), findsOneWidget);
    expect(find.text('Back and biceps'), findsWidgets);
    expect(find.text('45 min'), findsWidgets);
    expect(find.byIcon(Icons.fitness_center), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens edit form and deletes a saved workout from the log', (
    WidgetTester tester,
  ) async {
    await openWorkoutLog(tester);
    await addWorkout(tester);

    await tester.tap(find.byTooltip('Edit workout').first);
    await pumpUntilFound(tester, find.text('Edit Workout'));

    expect(find.text('Back and biceps'), findsWidgets);
    expect(find.text('45'), findsWidgets);
    expect(find.text('Rows, pull-ups, curls'), findsWidgets);

    await tester.tapAt(const Offset(10, 10));
    await pumpUntilGone(tester, find.text('Edit Workout'));

    await tester.tap(find.byTooltip('Delete workout').first);
    await pumpUntilFound(tester, find.text('Delete workout?'));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await pumpUntilFound(tester, find.text('No workouts yet'));

    expect(find.text('No workouts yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
