import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iris.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT,
        content TEXT,
        media_path TEXT,
        created_at INTEGER
      )
    ''');
  }

  // دالة الحذف التلقائي (24 ساعة للشات و 7 أيام للمكتبة)
  Future<void> deleteExpiredData() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = now - (24 * 60 * 60 * 1000);
    final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);

    // حذف رسايل الشات والملفات الأقدم من 24 ساعة
    await db.delete('chats', where: 'created_at < ? AND media_path IS NOT NULL', whereArgs: [oneDayAgo]);
    // حذف ملفات المكتبة الأقدم من 7 أيام
    // (هتضاف لاحقاً مع استوديو الفيديوهات)
  }
}
