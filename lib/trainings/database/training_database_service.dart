import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_project/trainings/model/training_report.dart';

class TrainingDatabaseService {
  TrainingDatabaseService._privateConstructor();
  static final TrainingDatabaseService instance =
      TrainingDatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  @visibleForTesting
  Future<void> closeForTesting() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'training_reports.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createReportsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToVersion2(db);
        }
      },
    );
  }

  Future<void> _createReportsTable(Database db) async {
    await db.execute('''
      CREATE TABLE training_reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        imagePath TEXT NOT NULL DEFAULT '',
        duration TEXT NOT NULL DEFAULT '',
        durationMinutes INTEGER NOT NULL DEFAULT 0,
        focus TEXT NOT NULL DEFAULT '',
        exercises TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateToVersion2(Database db) async {
    await db.execute(
      "ALTER TABLE training_reports ADD COLUMN durationMinutes INTEGER NOT NULL DEFAULT 0",
    );
    await db.execute(
      "ALTER TABLE training_reports ADD COLUMN focus TEXT NOT NULL DEFAULT ''",
    );

    final oldRows = await db.query(
      'training_reports',
      columns: ['id', 'duration', 'exercises'],
    );

    for (final row in oldRows) {
      final id = row['id'] as int;
      final duration = row['duration']?.toString() ?? '';
      final exercises = row['exercises']?.toString() ?? '';

      await db.update(
        'training_reports',
        {
          'durationMinutes': _parseDurationMinutes(duration),
          'focus': _deriveFocus(exercises),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<TrainingReport>> getReports() async {
    final db = await database;
    final maps = await db.query('training_reports', orderBy: 'date DESC');
    return maps.map((map) => TrainingReport.fromMap(map)).toList();
  }

  Future<int> insertReport(TrainingReport report) async {
    final db = await database;
    return db.insert('training_reports', report.toMap());
  }

  Future<int> updateReport(TrainingReport report) async {
    if (report.id == null) return 0;

    final db = await database;
    return db.update(
      'training_reports',
      report.toMap(),
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }

  Future<String> saveReportImage(File imageFile) async {
    final dbPath = await getDatabasesPath();
    final imageDirectory = Directory(join(dbPath, 'training_report_images'));

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final savedImage = await imageFile.copy(
      join(
        imageDirectory.path,
        '${DateTime.now().millisecondsSinceEpoch}_${basename(imageFile.path)}',
      ),
    );

    return savedImage.path;
  }

  Future<void> deleteReportImage(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) return;

    final imageFile = File(imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

  Future<int> deleteReport(int id) async {
    final db = await database;
    final maps = await db.query(
      'training_reports',
      columns: ['imagePath'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final deletedRows = await db.delete(
      'training_reports',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedRows > 0 && maps.isNotEmpty) {
      await deleteReportImage(maps.first['imagePath'] as String?);
    }

    return deletedRows;
  }

  int _parseDurationMinutes(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return 0;
    return int.tryParse(match.group(0)!) ?? 0;
  }

  String _deriveFocus(String exercises) {
    final trimmed = exercises.trim();
    if (trimmed.isEmpty) return '';

    final firstLine = trimmed.split('\n').first.trim();
    final firstPart = firstLine.split(',').first.trim();
    return firstPart.length <= 32 ? firstPart : firstPart.substring(0, 32);
  }
}
