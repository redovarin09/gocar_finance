import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/catat/data/models/expense_category.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../features/dashboard/data/daily_summary.dart';
import '../../../../features/catat/data/models/trip_model.dart';
import '../../../../features/catat/data/models/expense_model.dart';
import '../../../../features/catat/presentation/widgets/edit_trip_sheet.dart';
import '../../../../features/catat/presentation/widgets/edit_expense_sheet.dart';



const _hari  = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];
const _bulan = ['','Jan','Feb','Mar','Apr','Mei',
                 'Jun','Jul','Agu','Sep','Okt','Nov','Des'];

// ═══════════════════════════════════════════════════════════
//  TAB HARIAN
// ═══════════════════════════════════════════════════════════

class TabHarian extends ConsumerStatefulWidget {
  const TabHarian({super.key});

  @override
  ConsumerState<TabHarian> createState() => _TabHarianState();
}

class _TabHarianState extends ConsumerState<TabHarian> {
  DateTime _date = DateTime.now();

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr     = dateToString(_date);
    final summaryAsync = ref.watch(dailySummaryProvider(dateStr));

    return Column(
      children: [
        // Navigasi tanggal
        _DateNavigator(
          date: _date,
          canGoNext: !_isToday,
          onPrev: () => setState(
            () => _date = _date.subtract(const Duration(days: 1)),
          ),
          onNext: () => setState(
            () => _date = _date.add(const Duration(days: 1)),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        Expanded(
          child: summaryAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: AppTextStyles.bodySecondary),
            ),
            data: (summary) => summary.tripCount == 0 &&
                    summary.expenses.isEmpty
                ? const _EmptyDay()
                : _DailyDetail(summary: summary),
          ),
        ),
      ],
    );
  }
}

// ── Date Navigator ────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateNavigator({
    required this.date,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: AppColors.textPrimary,
            onPressed: onPrev,
          ),
          Expanded(
            child: Text(
              '${_hari[date.weekday % 7]}, '
              '${date.day} ${_bulan[date.month]} ${date.year}',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: canGoNext ? AppColors.textPrimary : AppColors.textHint,
            ),
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ── Daily Detail ──────────────────────────────────────────

class _DailyDetail extends ConsumerWidget {
  final DailySummary summary;
  const _DailyDetail({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      ...summary.trips.map(
        (t) => _TxRow(
          isIncome: true,
          emoji: t.paymentType == 'gopay' ? '📱' : '💵',
          label: 'Trip (${t.paymentType == 'gopay' ? 'GoPay' : 'Cash'})',
          sub: t.kmAdded > 0 ? '${t.kmAdded.toStringAsFixed(1)} km' : '',
          amount: t.totalIncome,
          time: t.createdAt,
          trip: t,
        ),
      ),
      ...summary.expenses.map(
        (e) => _TxRow(
          isIncome: false,
          emoji: ExpenseCategory.fromName(e.category).emoji,
          label: ExpenseCategory.fromName(e.category).label,
          sub: e.note ?? '',
          amount: e.amount,
          time: e.createdAt,
          expense: e,
        ),
      ),
    ]..sort((a, b) => b.time.compareTo(a.time));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _SummaryGrid(summary: summary),
        const SizedBox(height: 20),
        const Text('Semua Transaksi', style: AppTextStyles.h2),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              return _TransactionTile(
                row: e.value,
                isLast: e.key == items.length - 1,
                ref: ref,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
         
          

// ── Summary Grid (4 kartu) ────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final DailySummary summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Net income full-width
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: summary.netIncome >= 0
                ? AppColors.primaryLight
                : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: summary.netIncome >= 0
                  ? AppColors.primary
                  : AppColors.expense,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Penghasilan',
                style: AppTextStyles.caption.copyWith(
                  color: summary.netIncome >= 0
                      ? AppColors.primary
                      : AppColors.expense,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(summary.netIncome),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: summary.netIncome >= 0
                      ? AppColors.primary
                      : AppColors.expense,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                label: '⬆ Pemasukan',
                value: CurrencyFormatter.formatCompact(summary.totalIncome),
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniCard(
                label: '⬇ Pengeluaran',
                value: CurrencyFormatter.formatCompact(summary.totalExpense),
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                label: '🚗 Trip',
                value: '${summary.tripCount}x',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniCard(
                label: '🛣️ Total KM',
                value: '${summary.totalKm.toStringAsFixed(1)} km',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction tile ──────────────────────────────────────

class _TxRow {
  final bool isIncome;
  final String emoji;
  final String label;
  final String sub;
  final int amount;
  final String time;
  final TripModel? trip;
  final ExpenseModel? expense;

  const _TxRow({
    required this.isIncome,
    required this.emoji,
    required this.label,
    required this.sub,
    required this.amount,
    required this.time,
    this.trip,
    this.expense,
  });

  String get hhmm {
    try {
      final dt = DateTime.parse(time).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:'
          '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }

  String get date => trip?.date ?? expense?.date ?? '';
  int? get id => trip?.id ?? expense?.id;
}

class _TransactionTile extends StatelessWidget {
  final _TxRow row;
  final bool isLast;
  final WidgetRef ref;
  const _TransactionTile(
      {required this.row, required this.isLast, required this.ref});

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text('Hapus "${row.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (row.trip?.id != null) {
      await ref.read(tripRepositoryProvider).deleteTrip(row.trip!.id!);
    } else if (row.expense?.id != null) {
      await ref
          .read(expenseRepositoryProvider)
          .deleteExpense(row.expense!.id!);
    }
    ref.invalidate(dailySummaryProvider(row.date));
    ref.invalidate(dailyTripsProvider(row.date));
    ref.invalidate(dailyExpensesProvider(row.date));
    ref.invalidate(weeklyDataProvider);
    ref.invalidate(monthlyDataProvider);
  }

  void _edit(BuildContext context) {
    if (row.trip != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            EditTripSheet(trip: row.trip!, onUpdated: () {}),
      );
    } else if (row.expense != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            EditExpenseSheet(expense: row.expense!, onUpdated: () {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('lap_${row.id}_${row.time}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _delete(context);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 26),
      ),
      child: GestureDetector(
        onTap: () => _edit(context),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(row.emoji,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500),
                        ),
                        if (row.sub.isNotEmpty)
                          Text(row.sub, style: AppTextStyles.caption),
                        const Text('Tap untuk edit',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${row.isIncome ? '+' : '-'}'
                        '${CurrencyFormatter.formatCompact(row.amount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: row.isIncome
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                      Text(row.hhmm, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(
                  height: 1, indent: 56, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}
   
               
      

// ═══════════════════════════════════════════════════════════
//  TAB MINGGUAN
// ═══════════════════════════════════════════════════════════

class TabMingguan extends ConsumerWidget {
  const TabMingguan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyDataProvider);

    return weeklyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodySecondary)),
      data: (summaries) {
        final totalIncome  = summaries.fold(0, (s, d) => s + d.totalIncome);
        final totalExpense = summaries.fold(0, (s, d) => s + d.totalExpense);
        final totalNet     = totalIncome - totalExpense;
        final totalTrips   = summaries.fold(0, (s, d) => s + d.tripCount);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Judul minggu
            Text(
              '7 Hari Terakhir',
              style: AppTextStyles.h1,
            ),
            Text(
              '${_fmtDate(summaries.first.date)} – ${_fmtDate(summaries.last.date)}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),

            // Summary row
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    label: '💰 Net',
                    value: CurrencyFormatter.formatCompact(totalNet),
                    color: totalNet >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniCard(
                    label: '🚗 Total Trip',
                    value: '$totalTrips trip',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    label: '⬆ Pemasukan',
                    value: CurrencyFormatter.formatCompact(totalIncome),
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniCard(
                    label: '⬇ Pengeluaran',
                    value: CurrencyFormatter.formatCompact(totalExpense),
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bar chart
            const Text('Net per Hari', style: AppTextStyles.h2),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _WeeklyBarChart(summaries: summaries),
            ),
            const SizedBox(height: 24),

            // Per-hari list
            const Text('Detail Per Hari', style: AppTextStyles.h2),
            const SizedBox(height: 10),
            ...summaries.reversed.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DayRow(summary: s),
              ),
            ),
          ],
        );
      },
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day} ${_bulan[dt.month]}';
    } catch (_) {
      return d;
    }
  }
}

// ── Bar Chart ─────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<DailySummary> summaries;
  const _WeeklyBarChart({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final maxVal = summaries
        .map((s) => s.netIncome.abs().toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxVal > 0 ? maxVal * 1.3 : 100000.0;
    final interval = chartMax / 4;

    return BarChart(
      BarChartData(
        maxY: chartMax,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barGroups: summaries.asMap().entries.map((e) {
          final s = e.value;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: s.netIncome > 0 ? s.netIncome.toDouble() : 0,
                color: s.tripCount > 0 ? AppColors.income : AppColors.divider,
                width: 26,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= summaries.length) {
                  return const SizedBox();
                }
                try {
                  final dt = DateTime.parse(summaries[idx].date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _hari[dt.weekday % 7],
                      style: AppTextStyles.caption,
                    ),
                  );
                } catch (_) {
                  return const SizedBox();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  CurrencyFormatter.formatCompact(value.toInt()),
                  style: AppTextStyles.caption,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ── Day Row ───────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final DailySummary summary;
  const _DayRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    try { dt = DateTime.parse(summary.date); } catch (_) {}

    final dayLabel = dt != null
        ? '${_hari[dt.weekday % 7]}, ${dt.day} ${_bulan[dt.month]}'
        : summary.date;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${summary.tripCount} trip'
                  '${summary.totalKm > 0 ? ' · ${summary.totalKm.toStringAsFixed(0)} km' : ''}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatCompact(summary.netIncome),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: summary.netIncome >= 0
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ),
              Text(
                '⬆${CurrencyFormatter.formatCompact(summary.totalIncome)}'
                ' ⬇${CurrencyFormatter.formatCompact(summary.totalExpense)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB BULANAN
// ═══════════════════════════════════════════════════════════

class TabBulanan extends ConsumerWidget {
  const TabBulanan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlyDataProvider);
    final now = DateTime.now();

    return monthlyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodySecondary)),
      data: (summaries) {
        final totalIncome  = summaries.fold(0, (s, d) => s + d.totalIncome);
        final totalExpense = summaries.fold(0, (s, d) => s + d.totalExpense);
        final netIncome    = totalIncome - totalExpense;
        final totalTrips   = summaries.fold(0, (s, d) => s + d.tripCount);
        final totalKm      = summaries.fold(0.0, (s, d) => s + d.totalKm);

        // Akumulasi pengeluaran per kategori
        final catTotals = <String, int>{};
        for (final day in summaries) {
          day.expenseByCategory.forEach((k, v) {
            catTotals[k] = (catTotals[k] ?? 0) + v;
          });
        }
        final sortedCats = catTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Header bulan
            Text(
              '${_bulan[now.month]} ${now.year}',
              style: AppTextStyles.h1,
            ),
            Text(
              '${now.day} hari berjalan',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),

            // Net income hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF005C08), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net Bulan Ini',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(netIncome),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    label: '⬆ Total Masuk',
                    value: CurrencyFormatter.formatCompact(totalIncome),
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniCard(
                    label: '⬇ Total Keluar',
                    value: CurrencyFormatter.formatCompact(totalExpense),
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    label: '🚗 Total Trip',
                    value: '$totalTrips trip',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniCard(
                    label: '🛣️ Total KM',
                    value: '${totalKm.toStringAsFixed(0)} km',
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Breakdown pengeluaran per kategori
            if (sortedCats.isNotEmpty) ...[
              const Text('Rincian Pengeluaran', style: AppTextStyles.h2),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: sortedCats.asMap().entries.map((e) {
                    final cat = ExpenseCategory.fromName(e.value.key);
                    final pct = totalExpense > 0
                        ? e.value.value / totalExpense
                        : 0.0;
                    final isLast = e.key == sortedCats.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cat.emoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cat.label,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatCompact(
                                        e.value.value),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: AppColors.divider,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.expense),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                              height: 1,
                              indent: 16,
                              color: AppColors.divider),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
