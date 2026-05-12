import 'dart:io';

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

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'training_reports.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE training_reports(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            imagePath TEXT NOT NULL,
            duration TEXT NOT NULL,
            exercises TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<TrainingReport>> getReports() async {
    final db = await database;
    final maps = await db.query('training_reports', orderBy: 'date DESC');
    return maps.map((map) => TrainingReport.fromMap(map)).toList();
  }

  Future<int> insertReport(TrainingReport report) async {
    final db = await database;
    return await db.insert('training_reports', report.toMap());
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
      final imagePath = maps.first['imagePath'] as String;
      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }

    return deletedRows;
  }
}
