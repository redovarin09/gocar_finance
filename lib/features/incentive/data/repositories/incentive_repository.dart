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
    final db = await _db.database;
    final maps = await db.query(
      'incentive_targets',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'trip_target ASC',
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
  
  Future<List<IncentiveTargetModel>> getAllTargets() async {
    final db = await _db.database;
    final maps = await db.query(
      'incentive_targets',
      orderBy: 'date ASC',
    );
    return maps.map(IncentiveTargetModel.fromMap).toList();
  }
}
