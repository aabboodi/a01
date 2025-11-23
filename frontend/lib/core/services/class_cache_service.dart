import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ClassCacheService {
  static const _databaseName = "app_cache.db";
  static const _databaseVersion = 1;
  static const table = 'classes';

  // Make this a singleton class
  ClassCacheService._privateConstructor();
  static final ClassCacheService instance = ClassCacheService._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            class_id TEXT PRIMARY KEY,
            class_name TEXT NOT NULL
          )
          ''');
  }

  /// Clears the cache and inserts a new list of classes.
  Future<void> cacheClasses(List<dynamic> classes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(table); // Clear old data
      for (var classData in classes) {
        await txn.insert(table,
          {
            'class_id': classData['class_id'],
            'class_name': classData['class_name'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace
        );
      }
    });
  }

  /// Retrieves all classes from the cache.
  Future<List<Map<String, dynamic>>> getCachedClasses() async {
    final db = await database;
    return await db.query(table);
  }
}
