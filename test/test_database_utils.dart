// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uni_project/meals/database/meal_log_database_service.dart';
import 'package:uni_project/notes/database/database_service.dart';
import 'package:uni_project/trainings/database/training_database_service.dart';

const appDatabaseNames = ['tasks.db', 'meal_log.db', 'training_reports.db'];

Future<Directory> configureTestDatabases(String prefix) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final directory = await Directory.systemTemp.createTemp(prefix);
  await databaseFactory.setDatabasesPath(directory.path);
  await resetAppDatabasesForTesting();

  return directory;
}

Future<void> resetAppDatabasesForTesting() async {
  await closeAppDatabasesForTesting();
  await Future<void>.delayed(const Duration(milliseconds: 50));

  final dbPath = await getDatabasesPath();
  for (final databaseName in appDatabaseNames) {
    await deleteDatabase(p.join(dbPath, databaseName));
  }

  final trainingImages = Directory(p.join(dbPath, 'training_report_images'));
  if (await trainingImages.exists()) {
    await trainingImages.delete(recursive: true);
  }

  await Future<void>.delayed(const Duration(milliseconds: 50));
}

Future<void> closeAppDatabasesForTesting() async {
  await DatabaseService.instance.closeForTesting();
  await MealLogDatabaseService.instance.closeForTesting();
  await TrainingDatabaseService.instance.closeForTesting();
}
