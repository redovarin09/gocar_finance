import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/export_service.dart';
import '../../../shared/providers/app_providers.dart';
import 'widgets/laporan_widgets.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final tab = _tabController.index;
      final today = dateToString(DateTime.now());

      if (tab == 0) {
        // Harian
        final summary =
            await ref.read(dailySummaryProvider(today).future);
        await ExportService.shareHarian(summary);
      } else if (tab == 1) {
        // Mingguan
        final summaries = await ref.read(weeklyDataProvider.future);
        await ExportService.shareMingguan(summaries);
      } else {
        // Bulanan
        final summaries =
            await ref.read(monthlyDataProvider.future);
        await ExportService.shareBulanan(summaries, DateTime.now());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          // Export
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.share_rounded),
            color: AppColors.primary,
            tooltip: 'Export ke WhatsApp',
            onPressed: _isExporting ? null : _handleExport,
          ),
          // Refresh
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.label,
          tabs: const [
            Tab(text: 'Harian'),
            Tab(text: 'Mingguan'),
            Tab(text: 'Bulanan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TabHarian(),
          TabMingguan(),
          TabBulanan(),
        ],
      ),
    );
  }
}
