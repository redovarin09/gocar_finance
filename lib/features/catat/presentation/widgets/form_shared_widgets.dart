import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

// ── Section Label ─────────────────────────────────────────

class FormSectionLabel extends StatelessWidget {
  final String text;
  const FormSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
    );
  }
}

// ── Input Decoration ──────────────────────────────────────

InputDecoration formInputDecoration(String hint, {String? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textHint),
    suffixText: suffix,
    suffixStyle: AppTextStyles.bodySecondary,
    filled: true,
    fillColor: AppColors.cardBackground,
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

class RupiahTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;

  const RupiahTextField({
    super.key,
    required this.controller,
    this.hint = 'Rp 0',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [RupiahInputFormatter()],
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: formInputDecoration(hint).copyWith(
        prefixText: 'Rp ',
        prefixStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }
}


// -- Date Picker Field -----------------------------------------------------

class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  static const _hari = [
    'Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'
  ];
  static const _bulan = [
    '','Jan','Feb','Mar','Apr','Mei',
    'Jun','Jul','Agu','Sep','Okt','Nov','Des'
  ];

  String _format(DateTime d) =>
      "${_hari[d.weekday % 7]}, ${d.day} ${_bulan[d.month]} ${d.year}";

  Future<void> _pick(BuildContext context) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year, now.month - 3),
      lastDate: now,
      helpText: 'Pilih Tanggal Transaksi',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year  == now.year  &&
           selectedDate.month == now.month &&
           selectedDate.day   == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isToday ? AppColors.divider : AppColors.primary,
            width: _isToday ? 1 : 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: _isToday
                  ? AppColors.textSecondary
                  : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isToday
                    ? 'Hari Ini — ${_format(selectedDate)}'
                    : _format(selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isToday
                      ? AppColors.textPrimary
                      : AppColors.primary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: _isToday
                  ? AppColors.textHint
                  : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper: parse "28.000" → 28000 ───────────────────────

int parseRupiah(String raw) => RupiahInputFormatter.parse(raw);
