import '../../../../core/database/database_helper.dart';
import '../models/trip_model.dart';

class TripRepository {
  final DatabaseHelper _db;
  TripRepository(this._db);

  Future<int> insertTrip(TripModel trip) async {
    final db = await _db.database;
    return db.insert('trips', trip.toMap());
  }

  Future<List<TripModel>> getTripsByDate(String date) async {
    final db = await _db.database;
    final maps = await db.query(
      'trips',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return maps.map(TripModel.fromMap).toList();
  }

  Future<List<TripModel>> getTripsInRange(String from, String to) async {
    final db = await _db.database;
    final maps = await db.query(
      'trips',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [from, to],
      orderBy: 'date ASC, created_at DESC',
    );
    return maps.map(TripModel.fromMap).toList();
  }

  Future<int> updateTrip(TripModel trip) async {
    final db = await _db.database;
    return db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = await _db.database;
    return db.delete('trips', where: 'id = ?', whereArgs: [id]);

  }

  Future<List<TripModel>> getAllTrips() async {
    final db = await _db.database;
    final maps = await db.query(
      'trips',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map(TripModel.fromMap).toList();
  }
}
