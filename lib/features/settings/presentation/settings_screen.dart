import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/backup_service.dart';
import '../../../shared/providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp  = false;
  bool _isRestoring  = false;

  // ── Backup ───────────────────────────────────────────────

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    try {
      await ref.read(backupServiceProvider).createAndShareBackup();
    } catch (e) {
      _showSnack('Gagal membuat backup: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  // ── Restore ──────────────────────────────────────────────

  Future<void> _handleRestore() async {
    final confirm = await _confirmDialog(
      title: '⚠️ Pulihkan Backup?',
      content: 'SEMUA DATA yang ada sekarang akan DIHAPUS dan '
          'diganti dengan isi file backup.\n\n'
          'Pastikan file backup yang dipilih sudah benar.',
      confirmLabel: 'Ya, Pulihkan',
      confirmColor: AppColors.expense,
    );
    if (confirm != true) return;

    setState(() => _isRestoring = true);
    try {
      final result = await ref.read(backupServiceProvider).restoreFromFile();

      // Refresh semua provider
      ref.invalidate(dailySummaryProvider);
      ref.invalidate(dailyTripsProvider);
      ref.invalidate(dailyExpensesProvider);
      ref.invalidate(incentiveTargetsProvider);
      ref.invalidate(weeklyDataProvider);
      ref.invalidate(monthlyDataProvider);

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('✅ Restore Berhasil!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultRow('Trip', result.trips),
                _ResultRow('Pengeluaran', result.expenses),
                _ResultRow('Target Insentif', result.incentives),
                const SizedBox(height: 8),
                const Text(
                  'Data berhasil dipulihkan.',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnack('Gagal restore: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  Future<bool?> _confirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content, style: AppTextStyles.bodySecondary),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.expense : AppColors.income,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── BACKUP ──────────────────────────────────────
          _SectionHeader(
            icon: Icons.cloud_upload_rounded,
            title: 'Backup Data',
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.info_outline_rounded,
                text: 'Backup disimpan sebagai file .json. '
                    'Kamu bisa kirim ke WhatsApp, Google Drive, '
                    'Gmail, atau aplikasi lain sebagai cadangan.',
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.ios_share_rounded,
                label: 'Buat & Bagikan Backup',
                sublabel: 'Ekspor semua trip, pengeluaran & insentif',
                color: AppColors.primary,
                isLoading: _isBackingUp,
                onTap: _handleBackup,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── RESTORE ─────────────────────────────────────
          _SectionHeader(
            icon: Icons.cloud_download_rounded,
            title: 'Restore Data',
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warning,
                text: 'Restore akan MENGHAPUS semua data saat ini '
                    'dan menggantinya dengan isi file backup. '
                    'Proses ini tidak bisa dibatalkan.',
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.upload_file_rounded,
                label: 'Pilih File Backup (.json)',
                sublabel: 'Import dari storage / WhatsApp / Drive',
                color: AppColors.accent,
                isLoading: _isRestoring,
                onTap: _handleRestore,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── INFO APP ────────────────────────────────────
          _SectionHeader(
            icon: Icons.info_rounded,
            title: 'Informasi Aplikasi',
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoRow(label: 'Aplikasi', value: 'GocarFinance'),
              const _Divider(),
              _InfoRow(label: 'Versi', value: '1.0.0'),
              const _Divider(),
              _InfoRow(label: 'Database', value: 'SQLite — offline'),
              const _Divider(),
              _InfoRow(label: 'Platform', value: 'Android (Flutter)'),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final String label;
  final int count;
  const _ResultRow(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: AppColors.income, size: 16),
          const SizedBox(width: 8),
          Text('$count $label', style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.h2),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
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
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, color: AppColors.divider);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  const _InfoTile({
    required this.icon,
    required this.text,
    this.iconColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySecondary),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(sublabel, style: AppTextStyles.caption),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
      ),
      onTap: isLoading ? null : onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
