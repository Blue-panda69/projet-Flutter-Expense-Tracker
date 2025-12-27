enum ExpenseCategory {
  food,
  transport,
  rent,
  shopping,
  health,
  other,
}

class Expense {
  Expense({
    this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  final int? id;
  final int userId;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  Expense copyWith({
    int? id,
    int? userId,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'amount': amount,
      'category': category.index,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values[map['category'] as int],
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
    );
  }
}


