import 'package:share_plus/share_plus.dart';
import '../utils/currency_formatter.dart';
import '../../features/dashboard/data/daily_summary.dart';
import '../../features/catat/data/models/expense_category.dart';

abstract final class ExportService {
  static const _footer = '\n\n_Diekspor dari *GocarFinance* 🚗_';

  static const _bulan = [
    '','Jan','Feb','Mar','Apr','Mei',
    'Jun','Jul','Agu','Sep','Okt','Nov','Des'
  ];
  static const _hari = [
    'Min','Sen','Sel','Rab','Kam','Jum','Sab'
  ];

  // ── FORMAT & SHARE ──────────────────────────────────────

  static Future<void> shareHarian(DailySummary summary) async {
    await Share.share(_formatHarian(summary));
  }

  static Future<void> shareMingguan(List<DailySummary> summaries) async {
    await Share.share(_formatMingguan(summaries));
  }

  static Future<void> shareBulanan(
      List<DailySummary> summaries, DateTime bulan) async {
    await Share.share(_formatBulanan(summaries, bulan));
  }

  // ── TEMPLATE HARIAN ─────────────────────────────────────

  static String _formatHarian(DailySummary s) {
    final dt  = DateTime.tryParse(s.date) ?? DateTime.now();
    final buf = StringBuffer();

    buf.writeln('📊 *LAPORAN HARIAN - GOCARFINANCE*');
    buf.writeln(
        '📅 ${_hari[dt.weekday % 7]}, ${dt.day} ${_bulan[dt.month]} ${dt.year}');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━');

    // Net income
    final netSign = s.netIncome >= 0 ? '+' : '';
    buf.writeln(
        '\n💰 *NET PENGHASILAN*\n${netSign}${CurrencyFormatter.format(s.netIncome)}');

    // Pemasukan
    buf.writeln('\n📈 *PEMASUKAN*');
    if (s.trips.isEmpty) {
      buf.writeln('  Belum ada trip');
    } else {
      final gopay = s.trips.where((t) => t.paymentType == 'gopay').length;
      final cash  = s.trips.where((t) => t.paymentType == 'cash').length;
      if (gopay > 0) {
        final totalGopay = s.trips
            .where((t) => t.paymentType == 'gopay')
            .fold(0, (a, t) => a + t.totalIncome);
        buf.writeln(
            '  📱 GoPay  : ${gopay}x = ${CurrencyFormatter.formatCompact(totalGopay)}');
      }
      if (cash > 0) {
        final totalCash = s.trips
            .where((t) => t.paymentType == 'cash')
            .fold(0, (a, t) => a + t.totalIncome);
        buf.writeln(
            '  💵 Cash   : ${cash}x = ${CurrencyFormatter.formatCompact(totalCash)}');
      }
      buf.writeln(
          '  *Total   : ${CurrencyFormatter.format(s.totalIncome)}*');
    }

    // Pengeluaran
    buf.writeln('\n📉 *PENGELUARAN*');
    if (s.expenses.isEmpty) {
      buf.writeln('  Belum ada pengeluaran');
    } else {
      s.expenseByCategory.forEach((cat, amount) {
        final c = ExpenseCategory.fromName(cat);
        buf.writeln(
            '  ${c.emoji} ${c.label.padRight(8)}: ${CurrencyFormatter.formatCompact(amount)}');
      });
      buf.writeln(
          '  *Total   : ${CurrencyFormatter.format(s.totalExpense)}*');
    }

    // Stats
    buf.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('🚗 Total Trip  : ${s.tripCount} trip');
    if (s.totalKm > 0) {
      buf.writeln(
          '🛣️ Total KM    : ${s.totalKm.toStringAsFixed(1)} km');
    }

    buf.write(_footer);
    return buf.toString();
  }

  // ── TEMPLATE MINGGUAN ───────────────────────────────────

  static String _formatMingguan(List<DailySummary> summaries) {
    final from = DateTime.tryParse(summaries.first.date);
    final to   = DateTime.tryParse(summaries.last.date);

    final totalIncome  =
        summaries.fold(0, (s, d) => s + d.totalIncome);
    final totalExpense =
        summaries.fold(0, (s, d) => s + d.totalExpense);
    final totalNet     = totalIncome - totalExpense;
    final totalTrips   =
        summaries.fold(0, (s, d) => s + d.tripCount);
    final totalKm      =
        summaries.fold(0.0, (s, d) => s + d.totalKm);

    final buf = StringBuffer();

    buf.writeln('📊 *LAPORAN MINGGUAN - GOCARFINANCE*');
    if (from != null && to != null) {
      buf.writeln(
          '📅 ${from.day} ${_bulan[from.month]} – ${to.day} ${_bulan[to.month]} ${to.year}');
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━');

    final netSign = totalNet >= 0 ? '+' : '';
    buf.writeln(
        '\n💰 *NET TOTAL*\n${netSign}${CurrencyFormatter.format(totalNet)}');

    buf.writeln('\n📈 Pemasukan   : ${CurrencyFormatter.format(totalIncome)}');
    buf.writeln('📉 Pengeluaran : ${CurrencyFormatter.format(totalExpense)}');
    buf.writeln('🚗 Total Trip  : $totalTrips trip');
    if (totalKm > 0) {
      buf.writeln('🛣️ Total KM    : ${totalKm.toStringAsFixed(0)} km');
    }

    // Detail per hari
    buf.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('📆 *DETAIL PER HARI*');
    for (final day in summaries.reversed) {
      if (day.tripCount == 0 && day.expenses.isEmpty) continue;
      final dt = DateTime.tryParse(day.date);
      if (dt == null) continue;
      final sign = day.netIncome >= 0 ? '+' : '';
      buf.writeln(
          '  ${_hari[dt.weekday % 7]} ${dt.day}/${dt.month}: '
          '${sign}${CurrencyFormatter.formatCompact(day.netIncome)} '
          '(${day.tripCount} trip)');
    }

    buf.write(_footer);
    return buf.toString();
  }

  // ── TEMPLATE BULANAN ────────────────────────────────────

  static String _formatBulanan(
      List<DailySummary> summaries, DateTime bulan) {
    final totalIncome  =
        summaries.fold(0, (s, d) => s + d.totalIncome);
    final totalExpense =
        summaries.fold(0, (s, d) => s + d.totalExpense);
    final netIncome    = totalIncome - totalExpense;
    final totalTrips   =
        summaries.fold(0, (s, d) => s + d.tripCount);
    final totalKm      =
        summaries.fold(0.0, (s, d) => s + d.totalKm);

    final catTotals = <String, int>{};
    for (final day in summaries) {
      day.expenseByCategory.forEach((k, v) {
        catTotals[k] = (catTotals[k] ?? 0) + v;
      });
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buf = StringBuffer();

    buf.writeln('📊 *LAPORAN BULANAN - GOCARFINANCE*');
    buf.writeln(
        '📅 ${_bulan[bulan.month]} ${bulan.year} (${bulan.day} hari)');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━');

    final netSign = netIncome >= 0 ? '+' : '';
    buf.writeln(
        '\n💰 *NET PENGHASILAN*\n${netSign}${CurrencyFormatter.format(netIncome)}');

    buf.writeln('\n📈 Total Masuk    : ${CurrencyFormatter.format(totalIncome)}');
    buf.writeln('📉 Total Keluar   : ${CurrencyFormatter.format(totalExpense)}');
    buf.writeln('🚗 Total Trip     : $totalTrips trip');
    if (totalKm > 0) {
      buf.writeln(
          '🛣️ Total KM       : ${totalKm.toStringAsFixed(0)} km');
    }

    // Rata-rata harian
    final activeDays =
        summaries.where((d) => d.tripCount > 0).length;
    if (activeDays > 0) {
      buf.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('📐 *RATA-RATA HARI AKTIF ($activeDays hari)*');
      buf.writeln(
          '  💰 Net/hari   : ${CurrencyFormatter.formatCompact(netIncome ~/ activeDays)}');
      buf.writeln(
          '  🚗 Trip/hari  : ${(totalTrips / activeDays).toStringAsFixed(1)}');
    }

    // Breakdown pengeluaran
    if (sortedCats.isNotEmpty) {
      buf.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('📉 *RINCIAN PENGELUARAN*');
      for (final e in sortedCats) {
        final cat = ExpenseCategory.fromName(e.key);
        final pct = totalExpense > 0
            ? (e.value / totalExpense * 100).toStringAsFixed(0)
            : '0';
        buf.writeln(
            '  ${cat.emoji} ${cat.label.padRight(8)}: '
            '${CurrencyFormatter.formatCompact(e.value)} ($pct%)');
      }
    }

    buf.write(_footer);
    return buf.toString();
  }
}
