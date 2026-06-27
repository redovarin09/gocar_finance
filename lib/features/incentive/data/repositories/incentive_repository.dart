import '../../../../core/database/database_helper.dart';
import '../models/incentive_target_model.dart';

class IncentiveRepository {
  final DatabaseHelper _db;
  IncentiveRepository(this._db);

  Future<int> insertTarget(IncentiveTargetModel target) async {
    final db = await _db.database;
    return db.insert('incentive_targets', target.toMap());
  }

  Future<List<IncentiveTargetModel>> getTargetsByDate(String date) async {
    final db   = await _db.database;
    final maps = await db.query(
      'incentive_targets',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'trip_target ASC',
    );
    return maps.map(IncentiveTargetModel.fromMap).toList();
  }

  /// Ambil target dari tanggal terakhir yang punya data sebelum [date]
  Future<List<IncentiveTargetModel>> getLastUsedTargets(String date) async {
    final db   = await _db.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT date FROM incentive_targets '
      'WHERE date < ? ORDER BY date DESC LIMIT 1',
      [date],
    );
    if (rows.isEmpty) return [];
    final lastDate = rows.first['date'] as String;
    return getTargetsByDate(lastDate);
  }

  /// Copy target dari [fromDate] ke [toDate]
  Future<void> copyTargetsToDate({
    required String fromDate,
    required String toDate,
  }) async {
    final sources = await getTargetsByDate(fromDate);
    for (final t in sources) {
      await insertTarget(
        IncentiveTargetModel(
          date: toDate,
          tierName: t.tierName,
          tripTarget: t.tripTarget,
          bonusAmount: t.bonusAmount,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  Future<List<IncentiveTargetModel>> getAllTargets() async {
    final db   = await _db.database;
    final maps = await db.query(
      'incentive_targets',
      orderBy: 'date ASC',
    );
    return maps.map(IncentiveTargetModel.fromMap).toList();
  }

  Future<int> deleteTarget(int id) async {
    final db = await _db.database;
    return db.delete(
      'incentive_targets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
