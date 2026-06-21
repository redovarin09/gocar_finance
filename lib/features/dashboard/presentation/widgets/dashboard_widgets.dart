import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../features/incentive/data/models/incentive_target_model.dart';
import '../../data/daily_summary.dart';
import '../../../../features/catat/data/models/trip_model.dart';
import '../../../../features/catat/data/models/expense_model.dart';
import '../../../../features/catat/data/models/expense_category.dart';
import '../../../../features/catat/presentation/widgets/edit_trip_sheet.dart';
import '../../../../features/catat/presentation/widgets/edit_expense_sheet.dart';

// ═══════════════════════════════════════════════
//  HERO INCOME CARD
// ═══════════════════════════════════════════════

class HeroIncomeCard extends StatelessWidget {
  final DailySummary summary;
  const HeroIncomeCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final net = summary.netIncome;
    final netText = net < 0
        ? '-${CurrencyFormatter.format(net.abs())}'
        : CurrencyFormatter.format(net);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005C08), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: label + badge trip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Penghasilan Hari Ini',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${summary.tripCount} Trip',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Angka utama
          Text(
            netText,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          // Sub-stats pemasukan & pengeluaran
          Row(
            children: [
              _SubStat(
                label: '⬆ Pemasukan',
                value: CurrencyFormatter.formatCompact(summary.totalIncome),
                valueColor: const Color(0xFF80E880),
              ),
              const SizedBox(width: 28),
              _SubStat(
                label: '⬇ Pengeluaran',
                value: CurrencyFormatter.formatCompact(summary.totalExpense),
                valueColor: const Color(0xFFFFB3B3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _SubStat({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  STATS ROW (trip | km | jenis biaya)
// ═══════════════════════════════════════════════

class StatsRow extends StatelessWidget {
  final DailySummary summary;
  const StatsRow({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.directions_car_rounded,
            label: 'Trip',
            value: '${summary.tripCount}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.speed_rounded,
            label: 'KM Hari Ini',
            value: '${summary.totalKm.toStringAsFixed(1)} km',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.category_rounded,
            label: 'Jenis Biaya',
            value: '${summary.expenseByCategory.length}',
            color: const Color(0xFF7B61FF),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  INSENTIF SECTION
// ═══════════════════════════════════════════════

class InsentifSection extends ConsumerWidget {
  final String date;
  final int tripCount;
  const InsentifSection({
    super.key,
    required this.date,
    required this.tripCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetsAsync = ref.watch(incentiveTargetsProvider(date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎯 Insentif Hari Ini', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        targetsAsync.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text('Error: $e', style: AppTextStyles.caption),
          data: (targets) {
            if (targets.isEmpty) return const _EmptyInsentif();
            return Column(
              children: targets
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InsentifCard(
                        target: t,
                        currentTrips: tripCount,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyInsentif extends StatelessWidget {
  const _EmptyInsentif();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_outlined, color: AppColors.textHint, size: 36),
          SizedBox(height: 8),
          Text('Belum ada target insentif', style: AppTextStyles.bodySecondary),
          SizedBox(height: 4),
          Text('Set target di tab Insentif', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _InsentifCard extends StatelessWidget {
  final IncentiveTargetModel target;
  final int currentTrips;
  const _InsentifCard({required this.target, required this.currentTrips});

  @override
  Widget build(BuildContext context) {
    final progress    = (currentTrips / target.tripTarget).clamp(0.0, 1.0);
    final remaining   = (target.tripTarget - currentTrips).clamp(0, target.tripTarget);
    final isAchieved  = currentTrips >= target.tripTarget;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchieved ? AppColors.primaryLight : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAchieved ? AppColors.primary : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: nama tier + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                target.tierName,
                style: AppTextStyles.label.copyWith(
                  color: isAchieved ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              isAchieved
                  ? const Text(
                      '✅ TERCAPAI',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      '$remaining trip lagi',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 8),
          // Counter & bonus
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentTrips',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                ' / ${target.tripTarget} trip',
                style: AppTextStyles.bodySecondary,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Bonus', style: AppTextStyles.caption),
                  Text(
                    CurrencyFormatter.formatCompact(target.bonusAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchieved ? AppColors.primary : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  RECENT TRANSACTIONS (dengan delete & edit)
// ═══════════════════════════════════════════════

// Tambahkan import ini di atas file (cari bagian imports):
// import '../../../../features/catat/data/models/trip_model.dart';
// import '../../../../features/catat/data/models/expense_model.dart';
// import '../../../../features/catat/data/models/expense_category.dart';
// import '../../../../features/catat/presentation/widgets/edit_trip_sheet.dart';
// import '../../../../features/catat/presentation/widgets/edit_expense_sheet.dart';

class RecentTransactions extends ConsumerWidget {
  final DailySummary summary;
  const RecentTransactions({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      ...summary.trips.map((t) => _TxItem(
            isIncome: true,
            label:
                'Trip (${t.paymentType == 'gopay' ? 'GoPay' : 'Cash'})',
            amount: t.totalIncome,
            icon: Icons.directions_car_rounded,
            iconColor: AppColors.primary,
            time: t.createdAt,
            note: t.kmAdded > 0
                ? '${t.kmAdded.toStringAsFixed(1)} km'
                : null,
            trip: t,
          )),
      ...summary.expenses.map((e) => _TxItem(
            isIncome: false,
            label:
                '${ExpenseCategory.fromName(e.category).emoji} ${ExpenseCategory.fromName(e.category).label}',
            amount: e.amount,
            icon: Icons.remove_circle_outline_rounded,
            iconColor: AppColors.expense,
            time: e.createdAt,
            note: e.note,
            expense: e,
          )),
    ]..sort((a, b) => b.time.compareTo(a.time));

    final shown = items.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📋 Transaksi Hari Ini', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        shown.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        color: AppColors.textHint, size: 36),
                    SizedBox(height: 8),
                    Text('Belum ada transaksi hari ini',
                        style: AppTextStyles.bodySecondary),
                    SizedBox(height: 4),
                    Text('Tap ➕ untuk mulai mencatat',
                        style: AppTextStyles.caption),
                  ],
                ),
              )
            : Container(
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
                  children: shown
                      .asMap()
                      .entries
                      .map((e) => _DismissibleTile(
                            item: e.value,
                            isLast: e.key == shown.length - 1,
                          ))
                      .toList(),
                ),
              ),
      ],
    );
  }
}

// ── Model untuk tiap baris transaksi ─────────────────────

class _TxItem {
  final bool isIncome;
  final String label;
  final int amount;
  final IconData icon;
  final Color iconColor;
  final String time;
  final String? note;
  final TripModel? trip;
  final ExpenseModel? expense;

  const _TxItem({
    required this.isIncome,
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.time,
    this.note,
    this.trip,
    this.expense,
  });

  String get formattedTime {
    try {
      final dt = DateTime.parse(time).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  String get date => trip?.date ?? expense?.date ?? '';
  int? get id => trip?.id ?? expense?.id;
}

// ── Tile dengan swipe-hapus dan tap-edit ─────────────────

class _DismissibleTile extends ConsumerWidget {
  final _TxItem item;
  final bool isLast;
  const _DismissibleTile({required this.item, required this.isLast});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Hapus "${item.label}" '
          '${CurrencyFormatter.formatCompact(item.amount)}?',
        ),
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

    if (item.trip != null && item.trip!.id != null) {
      await ref.read(tripRepositoryProvider).deleteTrip(item.trip!.id!);
    } else if (item.expense != null && item.expense!.id != null) {
      await ref
          .read(expenseRepositoryProvider)
          .deleteExpense(item.expense!.id!);
    }

    ref.invalidate(dailySummaryProvider(item.date));
    ref.invalidate(dailyTripsProvider(item.date));
    ref.invalidate(dailyExpensesProvider(item.date));
    ref.invalidate(weeklyDataProvider);
    ref.invalidate(monthlyDataProvider);
  }

  void _edit(BuildContext context, WidgetRef ref) {
    if (item.trip != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditTripSheet(
          trip: item.trip!,
          onUpdated: () {},
        ),
      );
    } else if (item.expense != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditExpenseSheet(
          expense: item.expense!,
          onUpdated: () {},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key('tx_${item.id}_${item.time}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _delete(context, ref);
        return false; // kita handle delete manual
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Hapus',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _edit(context, ref),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child:
                        Icon(item.icon, color: item.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                        if (item.note != null && item.note!.isNotEmpty)
                          Text(item.note!, style: AppTextStyles.caption),
                        const Text('Tap untuk edit',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.isIncome ? '+' : '-'}'
                        '${CurrencyFormatter.formatCompact(item.amount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.isIncome
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                      Text(item.formattedTime,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(
                  height: 1, indent: 70, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}
