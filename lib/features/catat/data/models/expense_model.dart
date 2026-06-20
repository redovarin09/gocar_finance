import 'expense_category.dart';

class ExpenseModel {
  final int? id;
  final String date;
  final String category;
  final int amount;
  final String? note;
  final String createdAt;

  const ExpenseModel({
    this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  ExpenseCategory get categoryEnum => ExpenseCategory.fromName(category);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'category': category,
      'amount': amount,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      category: map['category'] as String,
      amount: map['amount'] as int,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  ExpenseModel copyWith({
    int? id,
    String? date,
    String? category,
    int? amount,
    String? note,
    String? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
