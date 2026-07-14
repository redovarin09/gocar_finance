import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/daily_summary.dart';

enum _TrendMode { netIncome, incomeExpense, tripCount }

class TrendChartCard extends ConsumerStatefulWidget {
  const TrendChartCard({super.key});

  @override
  ConsumerState<TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends ConsumerState<TrendChartCard> {
  _TrendMode _mode = _TrendMode.netIncome;

  @override
  Widget build(BuildContext context) {
    final trendAsync = ref.watch(trend30DaysProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tren 30 Hari', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          _ModeSelector(
            mode: _mode,
            onChanged: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: 16),
          trendAsync.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Gagal memuat data tren',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            ),
            data: (summaries) {
              if (summaries.every((s) => s.tripCount == 0)) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Belum ada data 30 hari terakhir',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 200,
                child: _TrendLineChart(summaries: summaries, mode: _mode),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final _TrendMode mode;
  final ValueChanged<_TrendMode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeChip(
          label: 'Net Income',
          selected: mode == _TrendMode.netIncome,
          onTap: () => onChanged(_TrendMode.netIncome),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Income vs Expense',
          selected: mode == _TrendMode.incomeExpense,
          onTap: () => onChanged(_TrendMode.incomeExpense),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Jumlah Trip',
          selected: mode == _TrendMode.tripCount,
          onTap: () => onChanged(_TrendMode.tripCount),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  final List<DailySummary> summaries;
  final _TrendMode mode;

  const _TrendLineChart({required this.summaries, required this.mode});

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = <LineChartBarData>[];

    switch (mode) {
      case _TrendMode.netIncome:
        lines.add(_buildLine(
          summaries
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.netIncome.toDouble()))
              .toList(),
          AppColors.primary,
        ));
        break;
      case _TrendMode.incomeExpense:
        lines.add(_buildLine(
          summaries
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.totalIncome.toDouble()))
              .toList(),
          AppColors.income,
        ));
        lines.add(_buildLine(
          summaries
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.totalExpense.toDouble()))
              .toList(),
          AppColors.expense,
        ));
        break;
      case _TrendMode.tripCount:
        lines.add(_buildLine(
          summaries
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.tripCount.toDouble()))
              .toList(),
          AppColors.accent,
        ));
        break;
    }

    final allValues = lines.expand((l) => l.spots).map((s) => s.y).toList();
    final maxRaw = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxRaw <= 0 ? 100.0 : maxRaw * 1.2;
    final minRaw = allValues.isEmpty
        ? 0.0
        : allValues.reduce((a, b) => a < b ? a : b);
    final minY = minRaw < 0 ? minRaw * 1.2 : 0.0;
    final interval = ((maxY - minY) / 4).clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toStringAsFixed(0),
                style: AppTextStyles.caption,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= summaries.length || idx % 5 != 0) {
                  return const SizedBox();
                }
                final dateParts = summaries[idx].date.split('-');
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${dateParts[2]}/${dateParts[1]}',
                    style: AppTextStyles.caption,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: lines,
      ),
    );
  }
}
