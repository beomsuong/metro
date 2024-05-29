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
            subwayName TEXT UNIQUE,
            searchTime TEXT
          )
        ''');
      },
    );
  }

  /// 검색 기록 추가 또는 갱신
  Future<int> insertSearch(String subwayName) async {
    final db = await database;
    // 먼저 subwayName이 존재하는지 확인
    final result = await db.query(
      'searches',
      where: 'subwayName = ?',
      whereArgs: [subwayName],
    );

    if (result.isNotEmpty) {
      // 존재하면 searchTime을 갱신
      return await db.update(
        'searches',
        {
          'searchTime': DateFormat('HH:mm').format(DateTime.now()),
        },
        where: 'subwayName = ?',
        whereArgs: [subwayName],
      );
    } else {
      // 존재하지 않으면 새 기록 추가
      return await db.insert(
        'searches',
        {
          'subwayName': subwayName,
          'searchTime': DateFormat('HH:mm').format(DateTime.now()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// 목록 가져오기
  Future<List<String>> getSearches() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT subwayName 
      FROM searches 
      ORDER BY ABS((strftime('%H', 'now') * 60 + strftime('%M', 'now')) - (strftime('%H', searchTime) * 60 + strftime('%M', searchTime))) ASC
    ''');

    return result.map((row) => row['subwayName'] as String).toList();
  }

  /// 가장 최신꺼 역 이름만 가져오기
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

  Future<int> updateSearch(String newSubwayName) async {
    final db = await database;
    return await db.update(
      'searches',
      {
        'subwayName': newSubwayName,
        'searchTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      },
      where: 'subwayName = ?',
      whereArgs: [newSubwayName],
    );
  }

  Future deleteSearch(String subwayName) async {
    final db = await database;
    return await db.delete(
      'searches',
      where: 'subwayName = ?',
      whereArgs: [subwayName],
    );
  }
}
