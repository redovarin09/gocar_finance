import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/expense_model.dart';
import 'form_shared_widgets.dart';

class FormPengeluaran extends ConsumerStatefulWidget {
  const FormPengeluaran({super.key});

  @override
  ConsumerState<FormPengeluaran> createState() => _FormPengeluaranState();
}

class _FormPengeluaranState extends ConsumerState<FormPengeluaran> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.bensin;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final amount = parseRupiah(_amountCtrl.text);
    if (amount <= 0) {
      _showSnack('Nominal tidak boleh kosong!', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    // Simpan sebelum reset
    final savedCategory = _category;

    try {
      final now = DateTime.now();
      final expense = ExpenseModel(
        date: dateToString(now),
        category: _category.name,
        amount: amount,
        note: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
        createdAt: now.toIso8601String(),
      );

      await ref.read(expenseRepositoryProvider).insertExpense(expense);

      final today = dateToString(now);
      ref.invalidate(dailySummaryProvider(today));
      ref.invalidate(dailyExpensesProvider(today));

      _amountCtrl.clear();
      _noteCtrl.clear();
      setState(() => _category = ExpenseCategory.bensin);

      _showSnack(
        '${savedCategory.emoji} ${savedCategory.label} '
        '${CurrencyFormatter.format(amount)} tersimpan ✅',
      );
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
          const FormSectionLabel('📂 Kategori Pengeluaran'),
          const SizedBox(height: 10),
          _CategoryGrid(
            selected: _category,
            onChanged: (cat) => setState(() => _category = cat),
          ),
          const SizedBox(height: 20),

          const FormSectionLabel('💸 Nominal'),
          const SizedBox(height: 8),
          RupiahTextField(
            controller: _amountCtrl,
            hint: '0',
            autofocus: false,
          ),
          const SizedBox(height: 20),

          const FormSectionLabel('📝 Catatan (opsional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: formInputDecoration('Contoh: SPBU Shell, 5 liter'),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
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
                _isSaving ? 'Menyimpan...' : 'Simpan Pengeluaran',
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

// ── Category Grid ─────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onChanged;
  const _CategoryGrid({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final categories = ExpenseCategory.values;
    return Row(
      children: categories.map((cat) {
        final isSelected = cat == selected;
        final isLast = cat == categories.last;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentLight
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cat.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
