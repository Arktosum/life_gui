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
      version: 4, // FIX: Bumped to Version 4 for Daily Journals!
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color_val INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Time Blocks Table
    await db.execute('''
      CREATE TABLE time_blocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        remarks TEXT,
        status TEXT NOT NULL DEFAULT 'completed',
        intensities TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // 3. Mood Presets Table
    await _createMoodTable(db);

    // Seed Default Categories for new users
    final defaultCategories = [
      {'name': 'Sleep', 'color_val': 0xFF3F51B5},
      {'name': 'Work', 'color_val': 0xFFF44336},
      {'name': 'Leisure', 'color_val': 0xFF4CAF50},
      {'name': 'Chores', 'color_val': 0xFFFF9800},
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }

    // NEW: Daily Journals Table
    await db.execute('''
      CREATE TABLE daily_journals (
        date_id TEXT PRIMARY KEY,
        content TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2)
      await db.execute(
        "ALTER TABLE time_blocks ADD COLUMN status TEXT NOT NULL DEFAULT 'completed'",
      );
    if (oldVersion < 3) await _createMoodTable(db);
    if (oldVersion < 4) {
      // Version 4 Upgrade: Add the Diary!
      await db.execute('''
        CREATE TABLE daily_journals (
          date_id TEXT PRIMARY KEY,
          content TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createMoodTable(Database db) async {
    await db.execute('''
      CREATE TABLE mood_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        emoji TEXT NOT NULL,
        joy REAL NOT NULL DEFAULT 0.0,
        trust REAL NOT NULL DEFAULT 0.0,
        fear REAL NOT NULL DEFAULT 0.0,
        surprise REAL NOT NULL DEFAULT 0.0,
        sadness REAL NOT NULL DEFAULT 0.0,
        disgust REAL NOT NULL DEFAULT 0.0,
        anger REAL NOT NULL DEFAULT 0.0,
        anticipation REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // The Starter Pack Vectors
    final starterPacks = [
      {
        'name': 'Neutral',
        'emoji': '😶',
        'joy': 0.0,
        'trust': 0.0,
        'fear': 0.0,
        'surprise': 0.0,
        'sadness': 0.0,
        'disgust': 0.0,
        'anger': 0.0,
        'anticipation': 0.0,
      },
      {
        'name': 'Flow State',
        'emoji': '⚡',
        'joy': 0.8,
        'trust': 0.6,
        'fear': 0.0,
        'surprise': 0.0,
        'sadness': 0.0,
        'disgust': 0.0,
        'anger': 0.0,
        'anticipation': 0.9,
      },
      {
        'name': 'Tired / Burnout',
        'emoji': '😴',
        'joy': 0.0,
        'trust': 0.0,
        'fear': 0.0,
        'surprise': 0.0,
        'sadness': 0.6,
        'disgust': 0.4,
        'anger': 0.2,
        'anticipation': 0.1,
      },
      {
        'name': 'Anxious',
        'emoji': '😬',
        'joy': 0.0,
        'trust': 0.0,
        'fear': 0.8,
        'surprise': 0.4,
        'sadness': 0.0,
        'disgust': 0.0,
        'anger': 0.0,
        'anticipation': 0.7,
      },
    ];

    for (var pack in starterPacks) {
      // Use ignore to prevent crashing if the user somehow already has these names
      await db.insert(
        'mood_presets',
        pack,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // --- CATEGORY OPERATIONS ---

  Future<int> insertCategory(ActivityCategory category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<ActivityCategory>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => ActivityCategory.fromMap(json)).toList();
  }

  Future<List<ActivityCategory>> getActiveCategories() async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return result.map((json) => ActivityCategory.fromMap(json)).toList();
  }

  Future<List<ActivityCategory>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
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

  Future<ActivityCategory> getOrCreateCategory(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
    );

    if (result.isNotEmpty) {
      return ActivityCategory.fromMap(result.first);
    } else {
      final newCategory = ActivityCategory(name: name, colorVal: 0xFF9E9E9E);
      final id = await db.insert('categories', newCategory.toMap());
      return newCategory.copyWith(id: id);
    }
  }

  // --- TIME BLOCK OPERATIONS ---

  Future<int> insertTimeBlock(TimeBlock block) async {
    final db = await instance.database;
    return await db.insert('time_blocks', block.toMap());
  }

  Future<List<TimeBlock>> getTimeBlocksForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'time_blocks',
      where: 'start_time < ? AND end_time > ?',
      whereArgs: [end.toIso8601String(), start.toIso8601String()],
      orderBy: 'start_time ASC',
    );
    return result.map((json) => TimeBlock.fromMap(json)).toList();
  }

  Future<int> deleteTimeBlock(int id) async {
    final db = await instance.database;
    return await db.delete('time_blocks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteOverlappingBlocks(DateTime start, DateTime end) async {
    final db = await instance.database;
    final overlappingBlocks = await db.query(
      'time_blocks',
      where: 'start_time < ? AND end_time > ?',
      whereArgs: [end.toIso8601String(), start.toIso8601String()],
    );

    for (var blockMap in overlappingBlocks) {
      final block = TimeBlock.fromMap(blockMap);

      if (block.startTime.isBefore(start) && block.endTime.isAfter(end)) {
        await db.update(
          'time_blocks',
          {'end_time': start.toIso8601String()},
          where: 'id = ?',
          whereArgs: [block.id],
        );
        final splitBlock = TimeBlock(
          startTime: end,
          endTime: block.endTime,
          categoryId: block.categoryId,
          remarks: block.remarks,
          status: block.status,
          intensities: block.intensities,
        );
        await insertTimeBlock(splitBlock);
      } else if (block.startTime.isBefore(start) &&
          block.endTime.isAfter(start)) {
        await db.update(
          'time_blocks',
          {'end_time': start.toIso8601String()},
          where: 'id = ?',
          whereArgs: [block.id],
        );
      } else if (block.endTime.isAfter(end) && block.startTime.isBefore(end)) {
        await db.update(
          'time_blocks',
          {'start_time': end.toIso8601String()},
          where: 'id = ?',
          whereArgs: [block.id],
        );
      } else {
        await deleteTimeBlock(block.id!);
      }
    }
  }

  // --- MOOD PRESET OPERATIONS ---

  Future<List<Map<String, dynamic>>> getAllMoodPresets() async {
    final db = await instance.database;
    return await db.query('mood_presets', orderBy: 'name ASC');
  }

  Future<int> insertMoodPreset(Map<String, dynamic> preset) async {
    final db = await instance.database;
    return await db.insert(
      'mood_presets',
      preset,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteMoodPreset(int id) async {
    final db = await instance.database;
    return await db.delete('mood_presets', where: 'id = ?', whereArgs: [id]);
  }

  // --- DAILY JOURNAL OPERATIONS ---

  Future<String?> getJournalContent(String dateId) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_journals',
      where: 'date_id = ?',
      whereArgs: [dateId],
    );
    if (result.isNotEmpty) {
      return result.first['content'] as String;
    }
    return null;
  }

  Future<int> saveJournalContent(String dateId, String content) async {
    final db = await instance.database;
    return await db.insert(
      'daily_journals',
      {'date_id': dateId, 'content': content},
      conflictAlgorithm: ConflictAlgorithm.replace, // Overwrites if it exists!
    );
  }
}
