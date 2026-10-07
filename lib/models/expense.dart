class Expense {
  final int? id;
  final int userId;
  final String category;
  final String description;
  final double amount;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      category: map['category'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'category': category,
      'description': description,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Expense copyWith({
    String? category,
    String? description,
    double? amount,
  }) {
    return Expense(
      id: id,
      userId: userId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdAt: createdAt,
    );
  }
}
