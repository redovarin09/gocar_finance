import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/backup_service.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../core/services/auto_backup_service.dart';
import 'dart:io';
import '../../../shared/providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  // ── Backup ───────────────────────────────────────────────

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    try {
      await ref.read(backupServiceProvider).createAndShareBackup();
    } catch (e) {
      _showSnack('Gagal backup: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  // ── Restore ──────────────────────────────────────────────

  Future<void> _handleRestore() async {
    // Step 1: User paste JSON
    final jsonStr = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PasteJsonSheet(),
    );

    if (jsonStr == null || jsonStr.isEmpty) return;

    // Step 2: Konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Pulihkan Backup?'),
        content: const Text(
          'SEMUA DATA yang ada sekarang akan DIHAPUS '
          'dan diganti dengan isi backup.\n\n'
          'Proses ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Pulihkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Step 3: Restore
    setState(() => _isRestoring = true);
    try {
      final result = await ref.read(backupServiceProvider).restoreFromJson(jsonStr);

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
          // BACKUP
          _SectionHeader(icon: Icons.cloud_upload_rounded, title: 'Backup Data'),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _InfoTile(
              icon: Icons.info_outline_rounded,
              text: 'Backup disimpan sebagai file .json. '
                  'Share ke WhatsApp, Google Drive, Gmail, atau simpan di mana saja.',
            ),
            const _CardDivider(),
            _ActionTile(
              icon: Icons.ios_share_rounded,
              label: 'Buat & Bagikan Backup',
              sublabel: 'Ekspor semua data ke file .json',
              color: AppColors.primary,
              isLoading: _isBackingUp,
              onTap: _handleBackup,
            ),
          ]),

          const SizedBox(height: 24),

          // AUTO BACKUP LOKAL
          _SectionHeader(
            icon: Icons.save_rounded,
            title: 'Backup Otomatis',
          ),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _InfoTile(
              icon: Icons.info_outline_rounded,
              text: 'Backup otomatis berjalan setiap 24 jam '
                  'saat app dibuka. File disimpan di storage '
                  'HP kamu (max 7 file terakhir).',
            ),
            const _CardDivider(),
            _LastBackupTile(isRestoring: _isRestoring),
          ]),

          const SizedBox(height: 24),

          // RESTORE
          _SectionHeader(icon: Icons.cloud_download_rounded, title: 'Restore Data'),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _InfoTile(
              icon: Icons.info_outline_rounded,
              text: 'Cara restore:\n'
                  '1. Buka file .json backup (WA, Drive, dll)\n'
                  '2. Buka dengan text editor, copy SEMUA isinya\n'
                  '3. Paste di kolom yang muncul',
            ),
            const _CardDivider(),
            _InfoTile(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.warning,
              text: 'SEMUA data saat ini akan dihapus dan diganti isi backup.',
            ),
            const _CardDivider(),
            _ActionTile(
              icon: Icons.paste_rounded,
              label: 'Paste & Pulihkan Backup',
              sublabel: 'Tempel teks JSON dari file backup',
              color: AppColors.accent,
              isLoading: _isRestoring,
              onTap: _handleRestore,
            ),
          ]),

          const SizedBox(height: 24),

          // TAMPILAN
          _SectionHeader(
              icon: Icons.dark_mode_rounded, title: 'Tampilan'),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            Consumer(
              builder: (context, ref, _) {
                final isDark =
                    ref.watch(themeModeProvider) == ThemeMode.dark;
                return SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  secondary: Icon(
                    isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: isDark
                        ? AppColors.accent
                        : AppColors.primary,
                  ),
                  title: Text(
                    isDark ? 'Mode Gelap' : 'Mode Terang',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isDark
                        ? 'Nyaman untuk berkendara malam'
                        : 'Kontras tinggi untuk siang hari',
                    style: AppTextStyles.caption,
                  ),
                  value: isDark,
                  activeColor: AppColors.accent,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // INFO APP
          _SectionHeader(icon: Icons.info_rounded, title: 'Informasi Aplikasi'),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _InfoRow(label: 'Aplikasi', value: 'GocarFinance'),
            const _CardDivider(),
            _InfoRow(label: 'Versi', value: '1.0.0'),
            const _CardDivider(),
            _InfoRow(label: 'Database', value: 'SQLite — offline'),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Paste JSON Bottom Sheet ───────────────────────────────

class _PasteJsonSheet extends StatefulWidget {
  const _PasteJsonSheet();

  @override
  State<_PasteJsonSheet> createState() => _PasteJsonSheetState();
}

class _PasteJsonSheetState extends State<_PasteJsonSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kolom teks masih kosong!'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!text.contains('"GocarFinance"')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ini bukan file backup GocarFinance!'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('📋 Paste Teks Backup', style: AppTextStyles.h2),
            const SizedBox(height: 12),
            const Text(
              'Buka file .json di text viewer, copy semua isinya, '
              'lalu paste di bawah.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 7,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '{\n  "app": "GocarFinance",\n  ...\n}',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'Gunakan Teks Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget helpers ────────────────────────────────────────

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

class _LastBackupTile extends ConsumerStatefulWidget {
  final bool isRestoring;
  const _LastBackupTile({required this.isRestoring});

  @override
  ConsumerState<_LastBackupTile> createState() =>
      _LastBackupTileState();
}

class _LastBackupTileState extends ConsumerState<_LastBackupTile> {
  bool _isRunning = false;
  String _lastBackupText = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final dt = await AutoBackupService.getLastBackupTime();
    setState(() {
      if (dt == null) {
        _lastBackupText = 'Belum pernah backup';
      } else {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          _lastBackupText =
              '${diff.inMinutes} menit yang lalu';
        } else if (diff.inHours < 24) {
          _lastBackupText = '${diff.inHours} jam yang lalu';
        } else {
          _lastBackupText = '${diff.inDays} hari yang lalu';
        }
      }
    });
  }

  Future<void> _manualBackup() async {
    setState(() => _isRunning = true);
    try {
      final path = await AutoBackupService.manualBackup(
        tripRepo:      ref.read(tripRepositoryProvider),
        expenseRepo:   ref.read(expenseRepositoryProvider),
        incentiveRepo: ref.read(incentiveRepositoryProvider),
      );
      final fileName = path.split('/').last;
      await _loadLastBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Backup disimpan: $fileName'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal backup: $e'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Backup Terakhir',
                        style: AppTextStyles.bodySecondary),
                    Text(
                      _lastBackupText,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _CardDivider(),
        _ActionTile(
          icon: Icons.save_alt_rounded,
          label: 'Backup Sekarang',
          sublabel: 'Simpan ke storage HP',
          color: AppColors.primary,
          isLoading: _isRunning,
          onTap: _manualBackup,
        ),
      ],
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

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, color: AppColors.divider);
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
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodySecondary)),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
