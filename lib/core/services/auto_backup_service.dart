import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/providers/app_providers.dart';

class AutoBackupService {
  static const _kLastBackup  = 'last_auto_backup_ms';
  static const _kInterval    = Duration(hours: 24);
  static const _folderName   = 'GocarFinance_Backups';
  static const _maxBackups   = 7;

  // ── Cek & jalankan backup ────────────────────────────────

  static Future<String?> checkAndBackup(Ref ref) async {
    try {
      final prefs       = await SharedPreferences.getInstance();
      final lastMs      = prefs.getInt(_kLastBackup) ?? 0;
      final lastBackup  = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final now         = DateTime.now();

      if (now.difference(lastBackup) < _kInterval) return null;

      final path = await _doBackup(ref);
      await prefs.setInt(_kLastBackup, now.millisecondsSinceEpoch);
      return path;
    } catch (e) {
      return null; // Gagal silently, tidak ganggu user
    }
  }

  // ── Backup manual (dari settings) ────────────────────────

  static Future<String> manualBackup(Ref ref) async {
    final path  = await _doBackup(ref);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _kLastBackup, DateTime.now().millisecondsSinceEpoch);
    return path;
  }

  // ── Ambil waktu backup terakhir ──────────────────────────

  static Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms    = prefs.getInt(_kLastBackup);
    if (ms == null || ms == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // ── Daftar file backup ───────────────────────────────────

  static Future<List<File>> getBackupFiles() async {
    final dir = await _getBackupDir();
    if (dir == null || !dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }

  // ── Private ───────────────────────────────────────────────

  static Future<String> _doBackup(Ref ref) async {
    final trips      = await ref.read(tripRepositoryProvider).getAllTrips();
    final expenses   = await ref.read(expenseRepositoryProvider).getAllExpenses();
    final incentives = await ref.read(incentiveRepositoryProvider).getAllTargets();

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
    final dir     = await _getBackupDir();

    if (dir == null) throw Exception('Storage tidak tersedia');
    await dir.create(recursive: true);

    // Rotasi: hapus backup lama (>7 file)
    await _rotate(dir);

    // Tulis file baru
    final now     = DateTime.now();
    final dateTag =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/gocarfinance_$dateTag.json');
    await file.writeAsString(jsonStr);
    return file.path;
  }

  static Future<Directory?> _getBackupDir() async {
    try {
      // Coba external storage dulu (accessible dari file manager)
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        return Directory('${ext.path}/$_folderName');
      }
      // Fallback ke app documents dir
      final docs = await getApplicationDocumentsDirectory();
      return Directory('${docs.path}/$_folderName');
    } catch (_) {
      return null;
    }
  }

  static Future<void> _rotate(Directory dir) async {
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));

      for (int i = _maxBackups; i < files.length; i++) {
        await files[i].delete();
      }
    } catch (_) {}
  }
}

// ── Provider ──────────────────────────────────────────────

/// Berjalan sekali per sesi app (bukan auto-dispose)
final autoBackupSessionProvider = FutureProvider<String?>((ref) {
  return AutoBackupService.checkAndBackup(ref);
});
