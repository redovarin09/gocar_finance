enum ExpenseCategory {
  bensin('Bensin', '⛽'),
  parkir('Parkir', '🅿️'),
  makan('Makan', '🍱'),
  servis('Servis', '🔧'),
  lainnya('Lainnya', '📦');

  const ExpenseCategory(this.label, this.emoji);

  final String label;
  final String emoji;

  static ExpenseCategory fromName(String name) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ExpenseCategory.lainnya,
    );
  }
}
