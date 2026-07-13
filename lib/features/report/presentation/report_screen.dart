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
  DateTime _selectedMonth = DateTime.now();

  static const _bulan = [
    '','Jan','Feb','Mar','Apr','Mei',
    'Jun','Jul','Agu','Sep','Okt','Nov','Des'
  ];

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

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final tab   = _tabController.index;
      final today = dateToString(DateTime.now());
      bool success = false;

      if (tab == 0) {
        final summary =
            await ref.read(dailySummaryProvider(today).future);
        success = await ExportService.shareHarian(summary);
      } else if (tab == 1) {
        final summaries = await ref.read(weeklyDataProvider.future);
        success = await ExportService.shareMingguan(summaries);
      } else {
        final summaries = await ref.read(
          monthlyDataProvider(_selectedMonth).future,
        );
        success =
            await ExportService.shareBulanan(summaries, _selectedMonth);
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk diekspor'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Refresh data',
            onPressed: () {
              ref.invalidate(weeklyDataProvider);
              ref.invalidate(monthlyDataProvider(_selectedMonth));
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
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Harian'),
            Tab(text: 'Mingguan'),
            Tab(text: 'Bulanan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const TabHarian(),
          const TabMingguan(),
          Column(
            children: [
              _MonthNavigator(
                month: _selectedMonth,
                canGoNext: !_isCurrentMonth,
                onPrev: _prevMonth,
                onNext: _nextMonth,
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: TabBulanan(month: _selectedMonth),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -- Month Navigator ---------------------------------------------------------

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNavigator({
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  static const _bulan = [
    '','Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember'
  ];

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
              '${_bulan[month.month]} ${month.year}',
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
