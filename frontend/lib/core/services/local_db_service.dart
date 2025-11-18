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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE classes (
            class_id TEXT PRIMARY KEY,
            class_name TEXT,
            teacher_name TEXT,
            data TEXT
          )
        ''');
      },
    );
  }

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
      return maps.map((map) => json.decode(map['data'])).toList();
    }
    return [];
  }
}
