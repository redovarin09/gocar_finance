import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/providers/app_providers.dart';
import '../data/models/incentive_target_model.dart';
import 'widgets/incentif_widgets.dart';

class InsentifScreen extends ConsumerWidget {
  const InsentifScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today          = dateToString(DateTime.now());
    final targetsAsync   = ref.watch(incentiveTargetsProvider(today));
    final lastUsedAsync  = ref.watch(lastUsedTargetsProvider);
    final tripsAsync     = ref.watch(dailyTripsProvider(today));

    final int tripCount = tripsAsync.when(
      data: (trips) => trips.length,
      loading: ()    => 0,
      error: (_, __) => 0,
    );

    void invalidateAll() {
      ref.invalidate(incentiveTargetsProvider(today));
      ref.invalidate(lastUsedTargetsProvider);
      ref.invalidate(dailyTripsProvider(today));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insentif Hari Ini'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: AppColors.primary,
            tooltip: 'Tambah target',
            onPressed: () => _showAddSheet(context, ref, today),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textSecondary,
            onPressed: invalidateAll,
          ),
        ],
      ),
      body: Column(
        children: [
          TripCountBanner(tripCount: tripCount),

          Expanded(
            child: targetsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
              data: (targets) {
                if (targets.isEmpty) {
                  // Cek apakah ada target kemarin
                  return lastUsedAsync.when(
                    loading: () => EmptyTargets(
                      onAdd: () => _showAddSheet(context, ref, today),
                      onCopy: null,
                    ),
                    error: (_, __) => EmptyTargets(
                      onAdd: () => _showAddSheet(context, ref, today),
                      onCopy: null,
                    ),
                    data: (lastTargets) => EmptyTargets(
                      onAdd: () => _showAddSheet(context, ref, today),
                      onCopy: lastTargets.isEmpty
                          ? null
                          : () async {
                              await _copyLastTargets(
                                context, ref, today, lastTargets,
                              );
                            },
                      lastTargetCount: lastTargets.length,
                    ),
                  );
                }

                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  children: [
                    // Banner auto-copy jika baru pindah hari
                    ...targets.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InsentifTierCard(
                          target: t,
                          currentTrips: tripCount,
                          onDelete: () async {
                            await ref
                                .read(incentiveRepositoryProvider)
                                .deleteTarget(t.id!);
                            ref.invalidate(
                                incentiveTargetsProvider(today));
                          },
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showAddSheet(context, ref, today),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize:
                            const Size(double.infinity, 52),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Tambah Tier Lain',
                        style: TextStyle(
                            fontWeight: FontWeight.w600),
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

  Future<void> _copyLastTargets(
    BuildContext context,
    WidgetRef ref,
    String today,
    List lastTargets,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📋 Salin Target?'),
        content: Text(
          'Salin ${lastTargets.length} target dari hari terakhir '
          'ke hari ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salin'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = ref.read(incentiveRepositoryProvider);
    for (final t in lastTargets) {
      await repo.insertTarget(
        IncentiveTargetModel(
          date: today,
          tierName: t.tierName,
          tripTarget: t.tripTarget,
          bonusAmount: t.bonusAmount,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    ref.invalidate(incentiveTargetsProvider(today));
    ref.invalidate(lastUsedTargetsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Target berhasil disalin ke hari ini!'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddSheet(
      BuildContext context, WidgetRef ref, String today) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTargetSheet(
        date: today,
        onSaved: () {
          ref.invalidate(incentiveTargetsProvider(today));
          ref.invalidate(lastUsedTargetsProvider);
        },
      ),
    );
  }
}
