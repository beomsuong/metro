import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'subway_search.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE searches(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subwayName TEXT,
            searchTime TEXT
          )
        ''');
      },
    );
  }

  ///검색 기록 추가
  Future<int> insertSearch(String subwayName) async {
    final db = await database;
    return await db.insert(
      'searches',
      {
        'subwayName': subwayName,
        'searchTime': DateFormat('HH:mm').format(DateTime.now())
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  ///목록 가져오기
  Future<List<Map<String, dynamic>>> getSearches() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT *, 
      ABS((strftime('%H:%M', 'now') - strftime('%H:%M', searchTime))) as time_diff 
      FROM searches 
      ORDER BY time_diff ASC
    ''');
  }

  ///가장 최신꺼 역 이름만 가져오기
  Future<String?> getClosestSearch() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT subwayName
        FROM searches 
      ORDER BY ABS((strftime('%H', 'now') * 60 + strftime('%M', 'now')) - (strftime('%H', searchTime) * 60 + strftime('%M', searchTime)))  ASC
      LIMIT 1
    ''');

    if (result.isNotEmpty) {
      return result.first['subwayName'].toString();
    } else {
      return null;
    }
  }

  Future<int> updateSearch(int id, String newSubwayName) async {
    final db = await database;
    return await db.update(
      'searches',
      {
        'subwayName': newSubwayName,
        'searchTime': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSearch() async {
    final db = await database;
    return await db.delete(
      'searches',
    );
  }
}
