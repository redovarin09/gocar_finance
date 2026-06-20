import '../../catat/data/models/trip_model.dart';
import '../../catat/data/models/expense_model.dart';

class DailySummary {
  final String date;
  final List<TripModel> trips;
  final List<ExpenseModel> expenses;

  const DailySummary({
    required this.date,
    required this.trips,
    required this.expenses,
  });

  // Computed properties — tidak disimpan ke DB
  int get totalIncome  => trips.fold(0, (s, t) => s + t.totalIncome);
  int get totalExpense => expenses.fold(0, (s, e) => s + e.amount);
  int get netIncome    => totalIncome - totalExpense;
  int get tripCount    => trips.length;
  double get totalKm  => trips.fold(0.0, (s, t) => s + t.kmAdded);

  // Pengeluaran per kategori → untuk pie/bar chart
  Map<String, int> get expenseByCategory {
    final result = <String, int>{};
    for (final e in expenses) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }
}
