import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ── Rupiah Formatter (format angka jadi 28.000 saat ketik) ─

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final amount = int.parse(digits);
    final formatted = _addDots(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addDots(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Rupiah TextField ──────────────────────────────────────

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

// ── Helper: parse "28.000" → 28000 ───────────────────────

int parseRupiah(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  return int.tryParse(digits) ?? 0;
}
