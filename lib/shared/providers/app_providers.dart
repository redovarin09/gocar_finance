import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../features/catat/data/models/trip_model.dart';
import '../../features/catat/data/models/expense_model.dart';
import '../../features/catat/data/repositories/trip_repository.dart';
import '../../features/catat/data/repositories/expense_repository.dart';
import '../../features/incentive/data/models/incentive_target_model.dart';
import '../../features/incentive/data/repositories/incentive_repository.dart';
import '../../features/dashboard/data/daily_summary.dart';
import '../../core/services/auto_backup_service.dart';

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

final trend30DaysProvider = FutureProvider<List<DailySummary>>((ref) async {
  final now  = DateTime.now();
  final from = dateToString(now.subtract(const Duration(days: 29)));
  final to   = dateToString(now);

  final tripRepo    = ref.watch(tripRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final trips    = await tripRepo.getTripsInRange(from, to);
  final expenses = await expenseRepo.getExpensesInRange(from, to);

  final tMap = <String, List<TripModel>>{};
  final eMap = <String, List<ExpenseModel>>{};
  for (final t in trips)    tMap.putIfAbsent(t.date, () => []).add(t);
  for (final e in expenses) eMap.putIfAbsent(e.date, () => []).add(e);

  return List.generate(30, (i) {
    final d = dateToString(now.subtract(Duration(days: 29 - i)));
    return DailySummary(date: d, trips: tMap[d] ?? [], expenses: eMap[d] ?? []);
  });
});

final weeklyDataProvider = FutureProvider<List<DailySummary>>((ref) async {
  final now  = DateTime.now();
  final from = dateToString(now.subtract(const Duration(days: 6)));
  final to   = dateToString(now);

  final tripRepo    = ref.watch(tripRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final trips    = await tripRepo.getTripsInRange(from, to);
  final expenses = await expenseRepo.getExpensesInRange(from, to);

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

final monthlyDataProvider =
    FutureProvider.family<List<DailySummary>, DateTime>((ref, month) async {
  final now       = DateTime.now();
  final isCurrent = month.year == now.year && month.month == now.month;
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final lastDay     = isCurrent ? now.day : daysInMonth;

  final from = dateToString(DateTime(month.year, month.month, 1));
  final to   = dateToString(DateTime(month.year, month.month, lastDay));

  final tripRepo2    = ref.watch(tripRepositoryProvider);
  final expenseRepo2 = ref.watch(expenseRepositoryProvider);
  final trips    = await tripRepo2.getTripsInRange(from, to);
  final expenses = await expenseRepo2.getExpensesInRange(from, to);

  final tMap = <String, List<TripModel>>{};
  final eMap = <String, List<ExpenseModel>>{};
  for (final t in trips)    tMap.putIfAbsent(t.date, () => []).add(t);
  for (final e in expenses) eMap.putIfAbsent(e.date, () => []).add(e);

  return List.generate(lastDay, (i) {
    final d = dateToString(DateTime(month.year, month.month, i + 1));
    return DailySummary(date: d, trips: tMap[d] ?? [], expenses: eMap[d] ?? []);
  });
});

// ── Target terakhir yang pernah dipakai ──────────────────

final lastUsedTargetsProvider =
    FutureProvider<List<IncentiveTargetModel>>((ref) {
  final today = dateToString(DateTime.now());
  return ref
      .watch(incentiveRepositoryProvider)
      .getLastUsedTargets(today);
});

// -- Auto backup session --------------------------------------------------

final autoBackupSessionProvider = FutureProvider<String?>((ref) {
  // keepAlive: provider tidak di-dispose saat widget rebuild
  ref.keepAlive();
  return AutoBackupService.checkAndBackup(
    tripRepo:      ref.read(tripRepositoryProvider),
    expenseRepo:   ref.read(expenseRepositoryProvider),
    incentiveRepo: ref.read(incentiveRepositoryProvider),
  );
});

// -- Riwayat: custom date range --------------------------------------------

class DateRangeParam {
  final String from;
  final String to;
  const DateRangeParam({required this.from, required this.to});

  @override
  bool operator ==(Object other) =>
      other is DateRangeParam && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

final riwayatProvider =
    FutureProvider.family<List<DailySummary>, DateRangeParam>(
        (ref, range) async {
  final tripRepo    = ref.watch(tripRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);

  final trips    = await tripRepo.getTripsInRange(range.from, range.to);
  final expenses = await expenseRepo.getExpensesInRange(range.from, range.to);

  final tMap = <String, List<TripModel>>{};
  final eMap = <String, List<ExpenseModel>>{};
  for (final t in trips)    tMap.putIfAbsent(t.date, () => []).add(t);
  for (final e in expenses) eMap.putIfAbsent(e.date, () => []).add(e);

  final allDates = <String>{...tMap.keys, ...eMap.keys}.toList()
    ..sort((a, b) => b.compareTo(a)); // terbaru dulu

  return allDates.map((d) {
    return DailySummary(
      date: d,
      trips: tMap[d] ?? [],
      expenses: eMap[d] ?? [],
    );
  }).toList();
});
