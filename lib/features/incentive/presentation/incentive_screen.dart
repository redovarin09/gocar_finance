import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/providers/app_providers.dart';
import 'widgets/incentif_widgets.dart';

class InsentifScreen extends ConsumerWidget {
  const InsentifScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today       = dateToString(DateTime.now());
    final targetsAsync = ref.watch(incentiveTargetsProvider(today));
    final tripsAsync   = ref.watch(dailyTripsProvider(today));

    final int tripCount = tripsAsync.when(
      data: (trips) => trips.length,
      loading: ()     => 0,
      error: (_, __)  => 0,
    );

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
            onPressed: () {
              ref.invalidate(incentiveTargetsProvider(today));
              ref.invalidate(dailyTripsProvider(today));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner jumlah trip hari ini
          TripCountBanner(tripCount: tripCount),

          // List target tier
          Expanded(
            child: targetsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTextStyles.bodySecondary),
              ),
              data: (targets) {
                if (targets.isEmpty) {
                  return EmptyTargets(
                    onAdd: () => _showAddSheet(context, ref, today),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  children: [
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
                            ref.invalidate(incentiveTargetsProvider(today));
                          },
                        ),
                      ),
                    ),
                    // Tombol tambah tier lain
                    OutlinedButton.icon(
                      onPressed: () => _showAddSheet(context, ref, today),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Tambah Tier Lain',
                        style: TextStyle(fontWeight: FontWeight.w600),
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

  void _showAddSheet(BuildContext context, WidgetRef ref, String today) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTargetSheet(
        date: today,
        onSaved: () => ref.invalidate(incentiveTargetsProvider(today)),
      ),
    );
  }
}
