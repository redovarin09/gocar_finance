import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/expense_model.dart';
import 'form_shared_widgets.dart';

class EditExpenseSheet extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  final VoidCallback onUpdated;
  const EditExpenseSheet(
      {super.key, required this.expense, required this.onUpdated});

  @override
  ConsumerState<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<EditExpenseSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late ExpenseCategory _category;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amountCtrl = TextEditingController(text: _dots(e.amount));
    _noteCtrl   = TextEditingController(text: e.note ?? '');
    _category   = ExpenseCategory.fromName(e.category);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
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
    final amount = parseRupiah(_amountCtrl.text);
    if (amount <= 0) {
      _snack('Nominal tidak boleh kosong!', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(expenseRepositoryProvider).updateExpense(
        widget.expense.copyWith(
          category: _category.name,
          amount: amount,
          note: _noteCtrl.text.trim().isEmpty
              ? null
              : _noteCtrl.text.trim(),
        ),
      );
      final d = widget.expense.date;
      ref.invalidate(dailySummaryProvider(d));
      ref.invalidate(dailyExpensesProvider(d));
      ref.invalidate(weeklyDataProvider);
      ref.invalidate(monthlyDataProvider(DateTime.now()));
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
              const Text('✏️ Edit Pengeluaran', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              const FormSectionLabel('📂 Kategori'),
              const SizedBox(height: 10),
              _CategoryRow(
                selected: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 16),
              const FormSectionLabel('💸 Nominal'),
              const SizedBox(height: 8),
              RupiahTextField(controller: _amountCtrl),
              const SizedBox(height: 16),
              const FormSectionLabel('📝 Catatan (opsional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    formInputDecoration('Contoh: SPBU Shell, 5 liter'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expense,
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

class _CategoryRow extends StatelessWidget {
  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onChanged;
  const _CategoryRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cats = ExpenseCategory.values;
    return Row(
      children: cats.map((cat) {
        final isSelected = cat == selected;
        final isLast = cat == cats.last;
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
                  Text(cat.emoji,
                      style: const TextStyle(fontSize: 22)),
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
