import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/trip_model.dart';
import 'form_shared_widgets.dart';

class FormPemasukan extends ConsumerStatefulWidget {
  const FormPemasukan({super.key});

  @override
  ConsumerState<FormPemasukan> createState() => _FormPemasukanState();
}

class _FormPemasukanState extends ConsumerState<FormPemasukan> {
  final _fareCtrl = TextEditingController();
  final _tipCtrl  = TextEditingController();
  final _kmCtrl   = TextEditingController();
  String _paymentType = 'gopay';
  bool _isSaving = false;

  @override
  void dispose() {
    _fareCtrl.dispose();
    _tipCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final fare = parseRupiah(_fareCtrl.text);
    if (fare <= 0) {
      _showSnack('Nominal fare tidak boleh kosong!', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final trip = TripModel(
        date: dateToString(now),
        fare: fare,
        paymentType: _paymentType,
        tip: parseRupiah(_tipCtrl.text),
        kmAdded: double.tryParse(
              _kmCtrl.text.replaceAll(',', '.'),
            ) ?? 0.0,
        createdAt: now.toIso8601String(),
      );

      await ref.read(tripRepositoryProvider).insertTrip(trip);

      final today = dateToString(now);
      ref.invalidate(dailySummaryProvider(today));
      ref.invalidate(dailyTripsProvider(today));
      ref.invalidate(weeklyDataProvider);
      ref.invalidate(monthlyDataProvider);

      // Cek insentif & kirim notifikasi
      final targets = await ref
          .read(incentiveRepositoryProvider)
          .getTargetsByDate(today);
      final trips = await ref
          .read(tripRepositoryProvider)
          .getTripsByDate(today);
      await NotificationService.checkInsentif(
        currentTrips: trips.length,
        targets: targets,
      );

      _fareCtrl.clear();
      _tipCtrl.clear();
      _kmCtrl.clear();
      setState(() => _paymentType = 'gopay');

      _showSnack('Trip ${CurrencyFormatter.format(fare)} tersimpan ✅');
    } catch (e) {
      _showSnack('Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FormSectionLabel('💰 Nominal Fare (setelah potongan GoJek)'),
          const SizedBox(height: 8),
          RupiahTextField(
            controller: _fareCtrl,
            hint: '0',
            autofocus: true,
          ),
          const SizedBox(height: 20),

          const FormSectionLabel('💳 Jenis Pembayaran'),
          const SizedBox(height: 8),
          _PaymentToggle(
            selected: _paymentType,
            onChanged: (val) => setState(() => _paymentType = val),
          ),
          const SizedBox(height: 20),

          const FormSectionLabel('🎁 Tip (opsional)'),
          const SizedBox(height: 8),
          RupiahTextField(controller: _tipCtrl, hint: '0'),
          const SizedBox(height: 20),

          const FormSectionLabel('🛣️ Jarak Trip km (opsional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _kmCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            decoration: formInputDecoration('Contoh: 12.5', suffix: 'km'),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 22),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Trip',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Toggle ────────────────────────────────────────

class _PaymentToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PaymentToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleBtn(
            label: '📱 GoPay',
            isSelected: selected == 'gopay',
            onTap: () => onChanged('gopay'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleBtn(
            label: '💵 Cash',
            isSelected: selected == 'cash',
            onTap: () => onChanged('cash'),
          ),
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
