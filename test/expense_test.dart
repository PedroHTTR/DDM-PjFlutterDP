import 'package:flutter_test/flutter_test.dart';

import 'package:ddm_pj_flutter_dp/models/expense.dart';

void main() {
  test('Expense converts to and from a database row', () {
    final expense = Expense(
      id: 7,
      userId: 3,
      category: 'Lazer',
      description: 'Cinema',
      amount: 45.50,
      createdAt: DateTime.parse('2026-10-07T12:00:00.000Z'),
    );

    final restored = Expense.fromMap({
      'id': expense.id,
      ...expense.toMap(),
    });

    expect(restored.id, expense.id);
    expect(restored.userId, expense.userId);
    expect(restored.category, expense.category);
    expect(restored.description, expense.description);
    expect(restored.amount, expense.amount);
    expect(restored.createdAt, expense.createdAt);
  });
}
