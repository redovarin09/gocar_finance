import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/providers/app_providers.dart';
import '../../features/catat/data/models/trip_model.dart';
import '../../features/catat/data/models/expense_model.dart';
import '../../features/incentive/data/models/incentive_target_model.dart';
import '../../features/catat/data/repositories/trip_repository.dart';
import '../../features/catat/data/repositories/expense_repository.dart';
import '../../features/incentive/data/repositories/incentive_repository.dart';
import '../database/database_helper.dart';

class RestoreResult {
  final int trips;
  final int expenses;
  final int incentives;
  const RestoreResult({
    required this.trips,
    required this.expenses,
    required this.incentives,
  });
}

class BackupService {
  final TripRepository _tripRepo;
  final ExpenseRepository _expenseRepo;
  final IncentiveRepository _incentiveRepo;

  BackupService(this._tripRepo, this._expenseRepo, this._incentiveRepo);

  /// Buat backup JSON → share via WhatsApp/Drive/Email/dll
  Future<void> createAndShareBackup() async {
    final trips      = await _tripRepo.getAllTrips();
    final expenses   = await _expenseRepo.getAllExpenses();
    final incentives = await _incentiveRepo.getAllTargets();

    final backupMap = {
      'version': 1,
      'app': 'GocarFinance',
      'exported_at': DateTime.now().toIso8601String(),
      'data': {
        'trips': trips.map((t) => t.toMap()).toList(),
        'expenses': expenses.map((e) => e.toMap()).toList(),
        'incentive_targets': incentives.map((i) => i.toMap()).toList(),
      },
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backupMap);

    final tempDir  = await getTemporaryDirectory();
    final now      = DateTime.now();
    final dateTag  = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final file = File('${tempDir.path}/gocarfinance_backup_$dateTag.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'GocarFinance Backup – $dateTag',
    );
  }

  /// Restore dari teks JSON (paste manual oleh user)
  Future<RestoreResult> restoreFromJson(String jsonStr) async {
    if (jsonStr.trim().isEmpty) {
      throw Exception('Teks JSON kosong');
    }
    return _processRestore(jsonStr.trim());
  }

  Future<RestoreResult> _processRestore(String jsonStr) async {
    late final Map<String, dynamic> backup;
    try {
      backup = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Format tidak valid — bukan JSON yang benar');
    }

    if (backup['app'] != 'GocarFinance') {
      throw Exception('Ini bukan file backup GocarFinance');
    }

    final data          = backup['data'] as Map<String, dynamic>;
    final tripsRaw      = (data['trips'] as List).cast<Map<String, dynamic>>();
    final expensesRaw   = (data['expenses'] as List).cast<Map<String, dynamic>>();
    final incentivesRaw = (data['incentive_targets'] as List).cast<Map<String, dynamic>>();

    final db = await DatabaseHelper.instance.database;
    await db.delete('trips');
    await db.delete('expenses');
    await db.delete('incentive_targets');

    for (final raw in tripsRaw) {
      await _tripRepo.insertTrip(TripModel.fromMap(raw).copyWith(id: null));
    }
    for (final raw in expensesRaw) {
      await _expenseRepo.insertExpense(
        ExpenseModel.fromMap(raw).copyWith(id: null),
      );
    }
    for (final raw in incentivesRaw) {
      final t = IncentiveTargetModel.fromMap(raw);
      await _incentiveRepo.insertTarget(
        IncentiveTargetModel(
          date: t.date,
          tierName: t.tierName,
          tripTarget: t.tripTarget,
          bonusAmount: t.bonusAmount,
          createdAt: t.createdAt,
        ),
      );
    }

    return RestoreResult(
      trips: tripsRaw.length,
      expenses: expensesRaw.length,
      incentives: incentivesRaw.length,
    );
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(tripRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(incentiveRepositoryProvider),
  );
});
