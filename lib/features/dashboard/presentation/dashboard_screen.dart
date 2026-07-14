import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/providers/app_providers.dart';
import 'widgets/dashboard_widgets.dart';
import 'widgets/trend_chart_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static String _tanggalHariIni() {
    final now = DateTime.now();
    const hari = [
      'Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'
    ];
    const bulan = [
      '','Jan','Feb','Mar','Apr','Mei',
      'Jun','Jul','Agu','Sep','Okt','Nov','Des'
    ];
    return '${hari[now.weekday % 7]}, ${now.day} ${bulan[now.month]}';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today       = dateToString(DateTime.now());
    final summaryAsync = ref.watch(dailySummaryProvider(today));


    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GocarFinance', style: AppTextStyles.h2),
            Text(_tanggalHariIni(), style: AppTextStyles.caption),
          ],
        ),
        actions: [
  IconButton(
    icon: const Icon(Icons.settings_rounded),
    color: AppColors.textSecondary,
    tooltip: 'Pengaturan & Backup',
    onPressed: () => context.push('/settings'),
  ),
  IconButton(
    icon: const Icon(Icons.refresh_rounded),
    color: AppColors.textSecondary,
    onPressed: () {
      ref.invalidate(dailySummaryProvider(today));
      ref.invalidate(incentiveTargetsProvider(today));
    },
  ),
],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dailySummaryProvider(today));
          ref.invalidate(incentiveTargetsProvider(today));
        },
        child: summaryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Gagal memuat data:\n$err',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (summary) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              HeroIncomeCard(summary: summary),
              const SizedBox(height: 16),
              const TrendChartCard(),
              const SizedBox(height: 24),
              StatsRow(summary: summary),
              const SizedBox(height: 24),
              InsentifSection(date: today, tripCount: summary.tripCount),
              const SizedBox(height: 24),
              RecentTransactions(summary: summary),
            ],
          ),
        ),
      ),
    );
  }
}
