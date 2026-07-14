import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/providers/app_providers.dart';
import '../../catat/data/models/expense_category.dart';

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;

  static const _bulan = [
    '','Jan','Feb','Mar','Apr','Mei',
    'Jun','Jul','Agu','Sep','Okt','Nov','Des'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate   = now;
    _fromDate = now.subtract(const Duration(days: 30));
  }

  String _fmtDate(DateTime d) => '${d.day} ${_bulan[d.month]} ${d.year}';

  Future<void> _pickRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      helpText: 'Pilih Rentang Tanggal',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      setState(() {
        _fromDate = result.start;
        _toDate   = result.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = DateRangeParam(
      from: dateToString(_fromDate),
      to: dateToString(_toDate),
    );
    final riwayatAsync = ref.watch(riwayatProvider(range));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            color: AppColors.primary,
            tooltip: 'Pilih rentang tanggal',
            onPressed: _pickRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // Range indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            color: AppColors.primaryLight,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${_fmtDate(_fromDate)} — ${_fmtDate(_toDate)}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: riwayatAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: AppTextStyles.bodySecondary),
              ),
              data: (summaries) {
                if (summaries.isEmpty) {
                  return const _EmptyRiwayat();
                }

                final totalIncome = summaries.fold(
                    0, (s, d) => s + d.totalIncome);
                final totalExpense = summaries.fold(
                    0, (s, d) => s + d.totalExpense);
                final totalTrips = summaries.fold(
                    0, (s, d) => s + d.tripCount);

                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    // Summary
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryChip(
                            label: 'Net',
                            value: CurrencyFormatter.formatCompact(
                                totalIncome - totalExpense),
                            color: (totalIncome - totalExpense) >= 0
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryChip(
                            label: 'Trip',
                            value: '$totalTrips',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryChip(
                            label: 'Hari',
                            value: '${summaries.length}',
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Per-day list
                    ...summaries.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RiwayatDayCard(summary: s),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -- Empty State --------------------------------------------------------

class _EmptyRiwayat extends StatelessWidget {
  const _EmptyRiwayat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              color: AppColors.textHint, size: 56),
          SizedBox(height: 12),
          Text('Tidak ada transaksi di rentang ini',
              style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}

// -- Summary Chip ---------------------------------------------------------

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          )),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// -- Day Card ---------------------------------------------------------

class _RiwayatDayCard extends StatefulWidget {
  final dynamic summary;
  const _RiwayatDayCard({required this.summary});

  @override
  State<_RiwayatDayCard> createState() => _RiwayatDayCardState();
}

class _RiwayatDayCardState extends State<_RiwayatDayCard> {
  bool _expanded = false;

  static const _hari = [
    'Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'
  ];
  static const _bulan = [
    '','Jan','Feb','Mar','Apr','Mei',
    'Jun','Jul','Agu','Sep','Okt','Nov','Des'
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    DateTime? dt;
    try { dt = DateTime.parse(s.date); } catch (_) {}

    final dayLabel = dt != null
        ? '${_hari[dt.weekday % 7]}, ${dt.day} ${_bulan[dt.month]} ${dt.year}'
        : s.date;

    return Container(
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
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dayLabel, style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          '${s.tripCount} trip · '
                          '${s.expenses.length} pengeluaran',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCompact(s.netIncome),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: s.netIncome >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            ..._buildDetailRows(s),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDetailRows(dynamic s) {
    final rows = <Widget>[];

    for (final t in s.trips) {
      rows.add(_DetailRow(
        emoji: t.paymentType == 'gopay' ? '📱' : '💵',
        label: 'Trip (${t.paymentType == 'gopay' ? 'GoPay' : 'Cash'})',
        amount: t.totalIncome,
        isIncome: true,
      ));
    }
    for (final e in s.expenses) {
      final cat = ExpenseCategory.fromName(e.category);
      rows.add(_DetailRow(
        emoji: cat.emoji,
        label: cat.label,
        amount: e.amount,
        isIncome: false,
      ));
    }
    return rows;
  }
}

class _DetailRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int amount;
  final bool isIncome;
  const _DetailRow({
    required this.emoji,
    required this.label,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.formatCompact(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}
