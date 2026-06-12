import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uni_project/meals/database/meal_log_database_service.dart';
import 'package:uni_project/meals/models/meal_entry.dart';
import 'package:uni_project/notes/database/database_service.dart';
import 'package:uni_project/notes/model/task.dart';
import 'package:uni_project/trainings/database/training_database_service.dart';
import 'package:uni_project/trainings/model/training_report.dart';

import 'test_database_utils.dart';

void main() {
  late Directory databaseSandbox;

  setUpAll(() async {
    databaseSandbox = await configureTestDatabases('fit_diary_db_test_');
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

  test('notes database creates, updates, and deletes tasks', () async {
    final service = DatabaseService.instance;

    final id = await service.insertTask(
      Task(title: 'Buy oats', description: 'Breakfast prep'),
    );

    var tasks = await service.getTasks();
    expect(tasks, hasLength(1));
    expect(tasks.single.id, id);
    expect(tasks.single.title, 'Buy oats');

    await service.updateTask(
      Task(id: id, title: 'Buy oats and berries', description: 'Meal prep'),
    );

    tasks = await service.getTasks();
    expect(tasks.single.title, 'Buy oats and berries');
    expect(tasks.single.description, 'Meal prep');

    expect(await service.deleteTask(id), 1);
    expect(await service.getTasks(), isEmpty);
  });

  test(
    'meal log database orders entries newest first and supports CRUD',
    () async {
      final service = MealLogDatabaseService.instance;

      final olderId = await service.insertEntry(
        MealEntry(
          date: DateTime(2026, 5, 20, 9),
          type: 'Breakfast',
          title: 'Oat bowl',
          calories: 480,
          protein: 28,
          notes: 'Before class',
        ),
      );
      final newerId = await service.insertEntry(
        MealEntry(
          date: DateTime(2026, 5, 21, 19),
          type: 'Dinner',
          title: 'Salmon rice bowl',
          calories: 720,
          protein: 46,
          notes: 'Post workout',
        ),
      );

      var entries = await service.getEntries();
      expect(entries.map((entry) => entry.id), [newerId, olderId]);
      expect(entries.first.title, 'Salmon rice bowl');

      await service.updateEntry(
        entries.first.copyWith(title: 'Teriyaki salmon bowl', protein: 50),
      );

      entries = await service.getEntries();
      expect(entries.first.title, 'Teriyaki salmon bowl');
      expect(entries.first.proteinLabel, '50g protein');

      expect(await service.deleteEntry(newerId), 1);
      entries = await service.getEntries();
      expect(entries, hasLength(1));
      expect(entries.single.id, olderId);

      expect(await service.getFavoriteRecipeIds(), isEmpty);

      await service.setFavoriteRecipe('m1', true);
      await service.setFavoriteRecipe('m3', true);
      expect(await service.getFavoriteRecipeIds(), {'m1', 'm3'});

      await service.setFavoriteRecipe('m1', false);
      expect(await service.getFavoriteRecipeIds(), {'m3'});
    },
  );

  test('meal log database migrates favorite recipes table', () async {
    await MealLogDatabaseService.instance.closeForTesting();

    final dbPath = await getDatabasesPath();
    final legacyPath = p.join(dbPath, 'meal_log.db');
    final legacyDb = await openDatabase(
      legacyPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE meal_entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            calories INTEGER,
            protein INTEGER,
            notes TEXT NOT NULL
          )
        ''');
      },
    );
    await legacyDb.close();

    await MealLogDatabaseService.instance.setFavoriteRecipe('m12', true);

    expect(await MealLogDatabaseService.instance.getFavoriteRecipeIds(), {
      'm12',
    });
  });

  test(
    'training database orders reports, updates rows, and deletes photos',
    () async {
      final service = TrainingDatabaseService.instance;
      final photo = File(p.join(databaseSandbox.path, 'workout-photo.jpg'));
      await photo.writeAsString('fake image bytes');

      final olderId = await service.insertReport(
        TrainingReport(
          date: DateTime(2026, 5, 19, 18),
          imagePath: null,
          durationMinutes: 35,
          focus: 'Legs',
          exercises: 'Squats\nLeg press',
        ),
      );
      final newerId = await service.insertReport(
        TrainingReport(
          date: DateTime(2026, 5, 22, 20),
          imagePath: photo.path,
          durationMinutes: 45,
          focus: 'Back',
          exercises: 'Rows\nPull-ups',
        ),
      );

      var reports = await service.getReports();
      expect(reports.map((report) => report.id), [newerId, olderId]);
      expect(reports.first.hasImage, isTrue);

      await service.updateReport(
        reports.first.copyWith(durationMinutes: 50, exercises: 'Rows\nCurls'),
      );

      reports = await service.getReports();
      expect(reports.first.durationLabel, '50 min');
      expect(reports.first.exercises, 'Rows\nCurls');

      expect(await service.deleteReport(newerId), 1);
      expect(photo.existsSync(), isFalse);

      reports = await service.getReports();
      expect(reports, hasLength(1));
      expect(reports.single.id, olderId);
    },
  );

  test('training database migrates legacy duration and focus fields', () async {
    await TrainingDatabaseService.instance.closeForTesting();

    final dbPath = await getDatabasesPath();
    final legacyPath = p.join(dbPath, 'training_reports.db');
    final legacyDb = await openDatabase(
      legacyPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE training_reports(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            imagePath TEXT NOT NULL DEFAULT '',
            duration TEXT NOT NULL DEFAULT '',
            exercises TEXT NOT NULL
          )
        ''');
      },
    );

    await legacyDb.insert('training_reports', {
      'date': DateTime(2026, 5, 24).toIso8601String(),
      'imagePath': '',
      'duration': '55 minutes',
      'exercises': 'Chest, triceps\nBench press',
    });
    await legacyDb.close();

    final reports = await TrainingDatabaseService.instance.getReports();

    expect(reports, hasLength(1));
    expect(reports.single.durationMinutes, 55);
    expect(reports.single.focus, 'Chest');
  });
}
