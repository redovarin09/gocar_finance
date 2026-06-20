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

// ── Laporan: 7 hari terakhir ─────────────────────────────

final weeklyDataProvider = FutureProvider<List<DailySummary>>((ref) async {
  final now  = DateTime.now();
  final from = dateToString(now.subtract(const Duration(days: 6)));
  final to   = dateToString(now);

  final trips    = await ref.read(tripRepositoryProvider).getTripsInRange(from, to);
  final expenses = await ref.read(expenseRepositoryProvider).getExpensesInRange(from, to);

  final tMap = <String, List<TripModel>>{};
  final eMap = <String, List<ExpenseModel>>{};
  for (final t in trips)    tMap.putIfAbsent(t.date, () => []).add(t);
  for (final e in expenses) eMap.putIfAbsent(e.date, () => []).add(e);

  return List.generate(7, (i) {
    final d = dateToString(now.subtract(Duration(days: 6 - i)));
    return DailySummary(date: d, trips: tMap[d] ?? [], expenses: eMap[d] ?? []);
  });
});

// ── Laporan: bulan ini ────────────────────────────────────

final monthlyDataProvider = FutureProvider<List<DailySummary>>((ref) async {
  final now  = DateTime.now();
  final from = dateToString(DateTime(now.year, now.month, 1));
  final to   = dateToString(now);

  final trips    = await ref.read(tripRepositoryProvider).getTripsInRange(from, to);
  final expenses = await ref.read(expenseRepositoryProvider).getExpensesInRange(from, to);

  final tMap = <String, List<TripModel>>{};
  final eMap = <String, List<ExpenseModel>>{};
  for (final t in trips)    tMap.putIfAbsent(t.date, () => []).add(t);
  for (final e in expenses) eMap.putIfAbsent(e.date, () => []).add(e);

  return List.generate(now.day, (i) {
    final d = dateToString(DateTime(now.year, now.month, i + 1));
    return DailySummary(date: d, trips: tMap[d] ?? [], expenses: eMap[d] ?? []);
  });
});
