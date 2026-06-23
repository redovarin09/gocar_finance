import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/providers/app_providers.dart';
import 'widgets/laporan_widgets.dart';

class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Refresh data',
              onPressed: () {
                ref.invalidate(weeklyDataProvider);
                ref.invalidate(monthlyDataProvider);
                final today = dateToString(DateTime.now());
                ref.invalidate(dailySummaryProvider(today));
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: AppTextStyles.label,
            tabs: [
              Tab(text: 'Harian'),
              Tab(text: 'Mingguan'),
              Tab(text: 'Bulanan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TabHarian(),
            TabMingguan(),
            TabBulanan(),
          ],
        ),
      ),
    );
  }
}
