import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_project/meals/models/meal_entry.dart';

class MealLogDatabaseService {
  MealLogDatabaseService._privateConstructor();
  static final MealLogDatabaseService instance =
      MealLogDatabaseService._privateConstructor();

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
    final path = join(dbPath, 'meal_log.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createMealEntriesTable(db);
        await _createFavoriteRecipesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createFavoriteRecipesTable(db);
        }
      },
    );
  }

  Future<void> _createMealEntriesTable(Database db) async {
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
  }

  Future<void> _createFavoriteRecipesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorite_recipes(
        mealId TEXT PRIMARY KEY
      )
    ''');
  }

  Future<List<MealEntry>> getEntries() async {
    final db = await database;
    final maps = await db.query('meal_entries', orderBy: 'date DESC');
    return maps.map((map) => MealEntry.fromMap(map)).toList();
  }

  Future<int> insertEntry(MealEntry entry) async {
    final db = await database;
    return db.insert('meal_entries', entry.toMap());
  }

  Future<int> updateEntry(MealEntry entry) async {
    if (entry.id == null) return 0;

    final db = await database;
    return db.update(
      'meal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('meal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<Set<String>> getFavoriteRecipeIds() async {
    final db = await database;
    final maps = await db.query('favorite_recipes', orderBy: 'mealId ASC');
    return maps.map((map) => map['mealId'] as String).toSet();
  }

  Future<void> setFavoriteRecipe(String mealId, bool isFavorite) async {
    final db = await database;

    if (isFavorite) {
      await db.insert('favorite_recipes', {
        'mealId': mealId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return;
    }

    await db.delete(
      'favorite_recipes',
      where: 'mealId = ?',
      whereArgs: [mealId],
    );
  }
}
