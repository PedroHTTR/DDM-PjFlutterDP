import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../database/database_service.dart';
import '../models/expense.dart';
import '../models/user.dart';

class TelaControle extends StatefulWidget {
  final String username;

  const TelaControle({super.key, required this.username});

  @override
  State<TelaControle> createState() => _EstadoTelaControle();
}

class _EstadoTelaControle extends State<TelaControle> {
  double _budget = 0.0;
  bool _loading = true;
  final _expenseCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final List<Expense> _expenses = [];
  String _selectedCategory = 'Outros';
  String? _message;
  User? _user;

  static const _categories = [
    'Moradia',
    'Alimentação',
    'Transporte',
    'Carro',
    'Lazer',
    'Saúde',
    'Educação',
    'Outros',
  ];

  static const _categoryColors = <String, Color>{
    'Moradia': Color(0xFF1565C0),
    'Alimentação': Color(0xFFE65100),
    'Transporte': Color(0xFF6A1B9A),
    'Carro': Color(0xFF00838F),
    'Lazer': Color(0xFFC62828),
    'Saúde': Color(0xFF2E7D32),
    'Educação': Color(0xFFAD1457),
    'Outros': Color(0xFF546E7A),
  };

  double get _spent =>
      _expenses.fold<double>(0, (total, expense) => total + expense.amount);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _expenseCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final user = await DatabaseService.instance.getUser(widget.username);
    final expenses = user == null
        ? <Expense>[]
        : await DatabaseService.instance.getExpenses(user.id);
    if (!mounted) return;
    setState(() {
      _user = user;
      _budget = user?.budget ?? 0.0;
      _expenses
        ..clear()
        ..addAll(expenses);
      _loading = false;
    });
  }

  Future<void> _addExpense() async {
    final value =
        double.tryParse(_expenseCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (value <= 0) {
      setState(() => _message = 'Informe um valor válido');
      return;
    }
    final user = _user;
    if (user == null) {
      setState(() => _message = 'Usuário não encontrado');
      return;
    }
    final description = _descriptionCtrl.text.trim().isEmpty
        ? _selectedCategory
        : _descriptionCtrl.text.trim();
    final expense = await DatabaseService.instance.createExpense(
      userId: user.id,
      category: _selectedCategory,
      description: description,
      amount: value,
    );
    if (!mounted) return;
    setState(() {
      _expenses.insert(0, expense);
      _message = 'Despesa adicionada';
      _expenseCtrl.clear();
      _descriptionCtrl.clear();
    });
  }

  Future<void> _reset() async {
    final user = _user;
    if (user == null) return;
    await DatabaseService.instance.deleteAllExpenses(user.id);
    if (!mounted) return;
    setState(() {
      _expenses.clear();
      _message = 'Gastos reiniciados';
    });
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir despesa?'),
        content: Text('A despesa "${expense.description}" será excluída.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || expense.id == null || _user == null) return;
    await DatabaseService.instance.deleteExpense(_user!.id, expense.id!);
    if (!mounted) return;
    setState(() {
      _expenses.removeWhere((item) => item.id == expense.id);
      _message = 'Despesa excluída';
    });
  }

  Future<void> _editExpense(Expense expense) async {
    final amountCtrl = TextEditingController(
      text: expense.amount.toStringAsFixed(2),
    );
    final descriptionCtrl = TextEditingController(text: expense.description);
    var category = expense.category;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar despesa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Tipo de despesa'),
                items: _categories
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => category = value);
                },
              ),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                if (amount == null || amount <= 0 || _user == null) return;
                final updated = Expense(
                  id: expense.id,
                  userId: _user!.id,
                  category: category,
                  description: descriptionCtrl.text.trim().isEmpty
                      ? category
                      : descriptionCtrl.text.trim(),
                  amount: amount,
                  createdAt: expense.createdAt,
                );
                await DatabaseService.instance.updateExpense(updated);
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    amountCtrl.dispose();
    descriptionCtrl.dispose();
    if (saved != true || !mounted) return;
    await _loadData();
    if (!mounted) return;
    setState(() => _message = 'Despesa atualizada');
  }

  Future<void> _logout() async {
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <String, double>{};
    for (final expense in _expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text('Controle - ${widget.username}'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Orçamento: R\$ ${_budget.toStringAsFixed(2)}'),
                  Text('Gasto: R\$ ${_spent.toStringAsFixed(2)}'),
                  if (sortedCategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Distribuição dos gastos',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: CustomPaint(
                        painter: _ExpensesChartPainter(
                          categories: sortedCategories,
                          colors: _categoryColors,
                          spent: _spent,
                          budget: _budget,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sortedCategories.map((entry) {
                      final categoryPercent =
                          _spent > 0 ? entry.value / _spent : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _categoryColors[entry.key],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(entry.key),
                              ],
                            ),
                            Text(
                                'R\$ ${entry.value.toStringAsFixed(2)}  ${(categoryPercent * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                      );
                    }),
                  ],
                  TextField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Descrição (ex: Pagamento do carro)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de despesa'),
                    items: _categories
                        .map((category) => DropdownMenuItem(
                            value: category, child: Text(category)))
                        .toList(),
                    onChanged: (category) =>
                        setState(() => _selectedCategory = category!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _expenseCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Adicionar despesa (ex: 50.00)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: _addExpense, child: const Text('Adicionar')),
                  TextButton(
                      onPressed: _reset, child: const Text('Reiniciar gastos')),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!,
                        style: const TextStyle(color: Colors.green)),
                  ],
                  if (_expenses.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Despesas',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._expenses.map(
                      (expense) => Card(
                        child: ListTile(
                          title: Text(expense.description),
                          subtitle: Text(expense.category),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('R\$ ${expense.amount.toStringAsFixed(2)}'),
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => _editExpense(expense),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'Excluir',
                                onPressed: () => _deleteExpense(expense),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ExpensesChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final Map<String, Color> colors;
  final double spent;
  final double budget;

  _ExpensesChartPainter({
    required this.categories,
    required this.colors,
    required this.spent,
    required this.budget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = categories.fold<double>(0, (sum, entry) => sum + entry.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    var startAngle = -math.pi / 2;

    for (final entry in categories) {
      final sweepAngle = 2 * math.pi * entry.value / total;
      final paint = Paint()
        ..color = colors[entry.key] ?? Colors.grey
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.58, centerPaint);

    final budgetPercent = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '${(budgetPercent * 100).toStringAsFixed(1)}%',
      style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, 22));
    textPainter.text = const TextSpan(
      text: 'Gasto / Orçamento',
      style: TextStyle(fontSize: 11, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, -8));
  }

  @override
  bool shouldRepaint(covariant _ExpensesChartPainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.colors != colors;
  }
}
