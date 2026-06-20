import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/incentive_target_model.dart';

// ═══════════════════════════════════════════════
//  BANNER — Trip count hari ini
// ═══════════════════════════════════════════════

class TripCountBanner extends StatelessWidget {
  final int tripCount;
  const TripCountBanner({super.key, required this.tripCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Selesai Hari Ini',
                style: AppTextStyles.caption,
              ),
              Text(
                '$tripCount Trip',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════

class EmptyTargets extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyTargets({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.textHint,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Target Insentif',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan target trip harian dari\naplikasi GoCar kamu.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(200, 52),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Target',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TIER CARD — Dismissible (swipe kiri = hapus)
// ═══════════════════════════════════════════════

class InsentifTierCard extends StatelessWidget {
  final IncentiveTargetModel target;
  final int currentTrips;
  final VoidCallback onDelete;

  const InsentifTierCard({
    super.key,
    required this.target,
    required this.currentTrips,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('tier_${target.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Target?'),
            content: Text(
              'Hapus "${target.tierName}" (${target.tripTarget} trip)?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: AppColors.expense),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: _TierCardContent(target: target, currentTrips: currentTrips),
    );
  }
}

class _TierCardContent extends StatelessWidget {
  final IncentiveTargetModel target;
  final int currentTrips;
  const _TierCardContent({required this.target, required this.currentTrips});

  @override
  Widget build(BuildContext context) {
    final progress   = (currentTrips / target.tripTarget).clamp(0.0, 1.0);
    final remaining  = (target.tripTarget - currentTrips).clamp(0, target.tripTarget);
    final isAchieved = currentTrips >= target.tripTarget;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchieved ? AppColors.primaryLight : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAchieved ? AppColors.primary : AppColors.divider,
          width: isAchieved ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAchieved
                        ? Icons.emoji_events_rounded
                        : Icons.flag_rounded,
                    color: isAchieved ? AppColors.primary : AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    target.tierName,
                    style: AppTextStyles.label.copyWith(
                      color: isAchieved
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              isAchieved
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✅ TERCAPAI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$remaining lagi',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),

          // Trip count row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentTrips',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isAchieved ? AppColors.primary : AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  ' / ${target.tripTarget} trip',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Bonus', style: AppTextStyles.caption),
                  Text(
                    CurrencyFormatter.formatCompact(target.bonusAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchieved ? AppColors.primary : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Persen
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: isAchieved ? AppColors.primary : AppColors.warning,
              ),
            ),
          ),

          // Hint hapus
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.swipe_left_rounded, size: 12, color: AppColors.textHint),
              SizedBox(width: 4),
              Text('Geser kiri untuk hapus', style: TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  BOTTOM SHEET — Form tambah target
// ═══════════════════════════════════════════════

class AddTargetSheet extends ConsumerStatefulWidget {
  final String date;
  final VoidCallback onSaved;

  const AddTargetSheet({
    super.key,
    required this.date,
    required this.onSaved,
  });

  @override
  ConsumerState<AddTargetSheet> createState() => _AddTargetSheetState();
}

class _AddTargetSheetState extends ConsumerState<AddTargetSheet> {
  final _tierNameCtrl   = TextEditingController(text: 'Tier 1');
  final _tripTargetCtrl = TextEditingController();
  final _bonusCtrl      = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _tierNameCtrl.dispose();
    _tripTargetCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
  }

  int _parseRupiah(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _simpan() async {
    final tierName   = _tierNameCtrl.text.trim();
    final tripTarget = int.tryParse(_tripTargetCtrl.text.trim()) ?? 0;
    final bonus      = _parseRupiah(_bonusCtrl.text);

    if (tierName.isEmpty || tripTarget <= 0 || bonus <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field wajib diisi dengan benar!'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final target = IncentiveTargetModel(
        date: widget.date,
        tierName: tierName,
        tripTarget: tripTarget,
        bonusAmount: bonus,
        createdAt: DateTime.now().toIso8601String(),
      );

      await ref.read(incentiveRepositoryProvider).insertTarget(target);
      widget.onSaved();

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('🎯 Tambah Target Insentif', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            const Text(
              'Salin dari halaman insentif di aplikasi GoCar',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 20),

            // Nama tier
            const _SheetLabel('Nama Tier'),
            const SizedBox(height: 8),
            TextField(
              controller: _tierNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _dec('Contoh: Tier 1, Tier Emas'),
            ),
            const SizedBox(height: 14),

            // Target trip
            const _SheetLabel('Target Trip'),
            const SizedBox(height: 8),
            TextField(
              controller: _tripTargetCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _dec('Contoh: 20'),
            ),
            const SizedBox(height: 14),

            // Bonus
            const _SheetLabel('Nominal Bonus (Rp)'),
            const SizedBox(height: 8),
            TextField(
              controller: _bonusCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [_RupiahFormatter()],
              decoration: _dec('Contoh: 75.000').copyWith(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      )
                    : const Text(
                        'Simpan Target',
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

// ── Private helpers ───────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
    );
  }
}

InputDecoration _dec(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textHint),
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
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _RupiahFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final n = int.parse(digits);
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
