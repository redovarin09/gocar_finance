import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/trip_model.dart';
import 'form_shared_widgets.dart';

class EditTripSheet extends ConsumerStatefulWidget {
  final TripModel trip;
  final VoidCallback onUpdated;
  const EditTripSheet({super.key, required this.trip, required this.onUpdated});

  @override
  ConsumerState<EditTripSheet> createState() => _EditTripSheetState();
}

class _EditTripSheetState extends ConsumerState<EditTripSheet> {
  late TextEditingController _fareCtrl;
  late TextEditingController _tipCtrl;
  late TextEditingController _kmCtrl;
  late String _paymentType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _fareCtrl = TextEditingController(text: _dots(t.fare));
    _tipCtrl  = TextEditingController(text: t.tip > 0 ? _dots(t.tip) : '');
    _kmCtrl   = TextEditingController(
      text: t.kmAdded > 0 ? t.kmAdded.toStringAsFixed(1) : '',
    );
    _paymentType = t.paymentType;
  }

  @override
  void dispose() {
    _fareCtrl.dispose();
    _tipCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  String _dots(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _save() async {
    final fare = parseRupiah(_fareCtrl.text);
    if (fare <= 0) {
      _snack('Nominal fare tidak boleh kosong!', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(tripRepositoryProvider).updateTrip(
        widget.trip.copyWith(
          fare: fare,
          paymentType: _paymentType,
          tip: parseRupiah(_tipCtrl.text),
          kmAdded:
              double.tryParse(_kmCtrl.text.replaceAll(',', '.')) ?? 0.0,
        ),
      );
      final d = widget.trip.date;
      ref.invalidate(dailySummaryProvider(d));
      ref.invalidate(dailyTripsProvider(d));
      ref.invalidate(weeklyDataProvider);
      ref.invalidate(monthlyDataProvider);
      widget.onUpdated();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _snack('Gagal update: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.expense : AppColors.income,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
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
              const Text('✏️ Edit Trip', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              const FormSectionLabel('💰 Nominal Fare'),
              const SizedBox(height: 8),
              RupiahTextField(controller: _fareCtrl),
              const SizedBox(height: 16),
              const FormSectionLabel('💳 Jenis Pembayaran'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Toggle(
                      label: '📱 GoPay',
                      selected: _paymentType == 'gopay',
                      onTap: () => setState(() => _paymentType = 'gopay'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Toggle(
                      label: '💵 Cash',
                      selected: _paymentType == 'cash',
                      onTap: () => setState(() => _paymentType = 'cash'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const FormSectionLabel('🎁 Tip (opsional)'),
              const SizedBox(height: 8),
              RupiahTextField(controller: _tipCtrl),
              const SizedBox(height: 16),
              const FormSectionLabel('🛣️ Jarak km (opsional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _kmCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: formInputDecoration('Contoh: 12.5', suffix: 'km'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Toggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
