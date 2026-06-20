import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'gocar_finance.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel trip / pemasukan
    await db.execute('''
      CREATE TABLE trips (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        date         TEXT    NOT NULL,
        fare         INTEGER NOT NULL,
        payment_type TEXT    NOT NULL,
        tip          INTEGER NOT NULL DEFAULT 0,
        km_added     REAL    NOT NULL DEFAULT 0,
        created_at   TEXT    NOT NULL
      )
    ''');

    // Tabel pengeluaran
    await db.execute('''
      CREATE TABLE expenses (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        date       TEXT    NOT NULL,
        category   TEXT    NOT NULL,
        amount     INTEGER NOT NULL,
        note       TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    // Tabel target insentif harian
    await db.execute('''
      CREATE TABLE incentive_targets (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        date         TEXT    NOT NULL,
        tier_name    TEXT    NOT NULL,
        trip_target  INTEGER NOT NULL,
        bonus_amount INTEGER NOT NULL,
        created_at   TEXT    NOT NULL
      )
    ''');
  }
}
