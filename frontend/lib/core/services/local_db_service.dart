import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createClassesTable(db);
        await _createMessagesTable(db);
        await _createUsersTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createMessagesTable(db);
          await _createUsersTable(db);
        }
      },
    );
  }

  Future<void> _createClassesTable(Database db) async {
    await db.execute('''
      CREATE TABLE classes (
        class_id TEXT PRIMARY KEY,
        class_name TEXT,
        teacher_name TEXT,
        data TEXT
      )
    ''');
  }

  Future<void> _createMessagesTable(Database db) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id TEXT,
        sender_id TEXT,
        content TEXT,
        timestamp INTEGER,
        is_synced INTEGER DEFAULT 1,
        data TEXT
      )
    ''');
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        full_name TEXT,
        role TEXT,
        data TEXT
      )
    ''');
  }

  // --- Classes ---

  Future<void> cacheClasses(List<dynamic> classes) async {
    final db = await database;
    final batch = db.batch();
    for (var classData in classes) {
      batch.insert(
        'classes',
        {
          'class_id': classData['class_id'],
          'class_name': classData['class_name'],
          'teacher_name': classData['teacher']?['full_name'] ?? 'N/A',
          'data': json.encode(classData),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<dynamic>> getCachedClasses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('classes');
    if (maps.isNotEmpty) {
      return maps.map((map) => json.decode(map['data'] as String)).toList();
    }
    return [];
  }

  // --- Messages ---

  Future<void> cacheMessages(String classId, List<dynamic> messages) async {
    final db = await database;
    final batch = db.batch();
    for (var msg in messages) {
      batch.insert(
        'messages',
        {
          'class_id': classId,
          'sender_id': msg['user']?['user_id'] ?? 'system',
          'content': msg['message'],
          'timestamp': DateTime.now().millisecondsSinceEpoch, // Ideally use server timestamp
          'data': json.encode(msg),
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<dynamic>> getCachedMessages(String classId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'timestamp ASC',
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => json.decode(map['data'] as String)).toList();
    }
    return [];
  }

  // --- Users ---

  Future<void> cacheUser(Map<String, dynamic> userData) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'user_id': userData['user_id'],
        'full_name': userData['full_name'],
        'role': userData['role'],
        'data': json.encode(userData),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return json.decode(maps.first['data'] as String);
    }
    return null;
  }
}
