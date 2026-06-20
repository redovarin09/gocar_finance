import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../features/catat/data/models/trip_model.dart';
import '../../features/catat/data/models/expense_model.dart';
import '../../features/catat/data/repositories/trip_repository.dart';
import '../../features/catat/data/repositories/expense_repository.dart';
import '../../features/incentive/data/models/incentive_target_model.dart';
import '../../features/incentive/data/repositories/incentive_repository.dart';
import '../../features/dashboard/data/daily_summary.dart';

// ── Helper ────────────────────────────────────────────────

String dateToString(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

// ── Database ──────────────────────────────────────────────

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// ── Repositories ──────────────────────────────────────────

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(ref.watch(databaseHelperProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(databaseHelperProvider));
});

final incentiveRepositoryProvider = Provider<IncentiveRepository>((ref) {
  return IncentiveRepository(ref.watch(databaseHelperProvider));
});

// ── Tanggal yang sedang dilihat ───────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// ── Data harian ───────────────────────────────────────────

final dailyTripsProvider =
    FutureProvider.family<List<TripModel>, String>((ref, date) {
  return ref.watch(tripRepositoryProvider).getTripsByDate(date);
});

final dailyExpensesProvider =
    FutureProvider.family<List<ExpenseModel>, String>((ref, date) {
  return ref.watch(expenseRepositoryProvider).getExpensesByDate(date);
});

final dailySummaryProvider =
    FutureProvider.family<DailySummary, String>((ref, date) async {
  final trips    = await ref.watch(dailyTripsProvider(date).future);
  final expenses = await ref.watch(dailyExpensesProvider(date).future);
  return DailySummary(date: date, trips: trips, expenses: expenses);
});

final incentiveTargetsProvider =
    FutureProvider.family<List<IncentiveTargetModel>, String>((ref, date) {
  return ref.watch(incentiveRepositoryProvider).getTargetsByDate(date);
});
