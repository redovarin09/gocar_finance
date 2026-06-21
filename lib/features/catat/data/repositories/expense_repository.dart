import '../../../../core/database/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final DatabaseHelper _db;
  ExpenseRepository(this._db);

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await _db.database;
    return db.insert('expenses', expense.toMap());
  }

  Future<List<ExpenseModel>> getExpensesByDate(String date) async {
    final db = await _db.database;
    final maps = await db.query(
      'expenses',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return maps.map(ExpenseModel.fromMap).toList();
  }

  Future<List<ExpenseModel>> getExpensesInRange(String from, String to) async {
    final db = await _db.database;
    final maps = await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [from, to],
      orderBy: 'date ASC, created_at DESC',
    );
    return maps.map(ExpenseModel.fromMap).toList();
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    final db = await _db.database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _db.database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await _db.database;
    final maps = await db.query(
      'expenses',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map(ExpenseModel.fromMap).toList();
  }
}
