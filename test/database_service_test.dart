import 'package:flutter_test/flutter_test.dart';

import 'package:ddm_pj_flutter_dp/database/database_service.dart';

void main() {
  test('DatabaseService supports user and expense CRUD', () async {
    final database = DatabaseService.instance;
    await database.initialize();
    final username = 'test_${DateTime.now().microsecondsSinceEpoch}';

    expect(
      await database.registerUser(
        username: username,
        password: 'secret',
        budget: 1000,
      ),
      isTrue,
    );
    expect(
      await database.registerUser(
        username: username,
        password: 'secret',
        budget: 1000,
      ),
      isFalse,
    );

    final user = await database.authenticate(
      username: username,
      password: 'secret',
    );
    expect(user, isNotNull);

    final created = await database.createExpense(
      userId: user!.id,
      category: 'Lazer',
      description: 'Cinema',
      amount: 45,
    );
    expect((await database.getExpense(user.id, created.id!))?.amount, 45);
    expect((await database.getExpenses(user.id)), hasLength(1));

    final updated = created.copyWith(amount: 50, description: 'Teatro');
    expect(await database.updateExpense(updated), isTrue);
    expect((await database.getExpense(user.id, created.id!))?.amount, 50);
    expect((await database.getExpense(user.id, created.id!))?.description,
        'Teatro');

    expect(await database.deleteExpense(user.id, created.id!), isTrue);
    expect(await database.getExpenses(user.id), isEmpty);
  });
}
