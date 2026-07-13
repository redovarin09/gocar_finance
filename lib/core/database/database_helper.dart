import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  // NAIKKAN NOMOR INI setiap kali skema berubah
  static const int _dbVersion = 1;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'gocar_finance.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Skema awal (install baru) ────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
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

    // Index untuk mempercepat query by date (dipakai di semua repo)
    await db.execute('CREATE INDEX idx_trips_date ON trips(date)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute(
        'CREATE INDEX idx_incentive_date ON incentive_targets(date)');
  }

  // ── Migration path — jalan otomatis saat versi naik ──────

  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Setiap migrasi HARUS pakai ALTER TABLE / CREATE, TIDAK PERNAH DROP.
    // Tambahkan blok baru di bawah untuk versi berikutnya.

    // Contoh pola untuk versi mendatang (tidak dieksekusi sekarang):
    //
    // if (oldVersion < 2) {
    //   await db.execute(
    //     'ALTER TABLE trips ADD COLUMN is_cancelled INTEGER NOT NULL DEFAULT 0'
    //   );
    // }
    //
    // if (oldVersion < 3) {
    //   await db.execute(
    //     'ALTER TABLE expenses ADD COLUMN receipt_photo TEXT'
    //   );
    // }

    // Pastikan index selalu ada (aman dijalankan berulang dengan IF NOT EXISTS)
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_trips_date ON trips(date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_incentive_date ON incentive_targets(date)');
  }

  // ── Helper untuk debugging / testing migrasi ─────────────

  Future<int> getCurrentVersion() async {
    final db = await database;
    return db.getVersion();
  }
}
