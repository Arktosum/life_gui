import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/time_block.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('life_gui.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color_val INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE time_blocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        remarks TEXT,
        intensities TEXT NOT NULL,
        calculated_color INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');

    await _seedInitialCategories(db);
  }

  Future _seedInitialCategories(Database db) async {
    final defaultCategories = [
      ActivityCategory(name: 'Deep Work', colorVal: 0xFF3F51B5),
      ActivityCategory(name: 'Maintenance', colorVal: 0xFFFFC107),
      ActivityCategory(name: 'Leisure', colorVal: 0xFF009688),
      ActivityCategory(name: 'Sleep', colorVal: 0xFF607D8B),
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  Future<int> insertCategory(ActivityCategory category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<ActivityCategory>> getActiveCategories() async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'is_active = ?',
      orderBy: 'name ASC',
    );
    return result.map((json) => ActivityCategory.fromMap(json)).toList();
  }

  Future<int> updateCategory(ActivityCategory category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> insertTimeBlock(TimeBlock block) async {
    final db = await instance.database;
    return await db.insert('time_blocks', block.toMap());
  }

  Future<List<TimeBlock>> getTimeBlocksForDateRange(DateTime start, DateTime end) async {
    final db = await instance.database;
    final result = await db.query(
      'time_blocks',
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'start_time ASC',
    );
    return result.map((json) => TimeBlock.fromMap(json)).toList();
  }

  Future<int> updateTimeBlock(TimeBlock block) async {
    final db = await instance.database;
    return await db.update(
      'time_blocks',
      block.toMap(),
      where: 'id = ?',
      whereArgs: [block.id],
    );
  }

  Future<int> deleteTimeBlock(int id) async {
    final db = await instance.database;
    return await db.delete(
      'time_blocks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteOverlappingBlocks(DateTime start, DateTime end) async {
    final db = await instance.database;
    await db.delete(
      'time_blocks',
      where: '(start_time < ?) AND (end_time > ?)',
      whereArgs: [end.toIso8601String(), start.toIso8601String()],
    );
  }
}