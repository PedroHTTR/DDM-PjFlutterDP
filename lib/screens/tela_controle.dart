import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class TelaControle extends StatefulWidget {
  final String username;
  const TelaControle({Key? key, required this.username}) : super(key: key);

  @override
  State<TelaControle> createState() => _EstadoTelaControle();
}

class _EstadoTelaControle extends State<TelaControle> {
  double _budget = 0.0;
  double _spent = 0.0;
  bool _loading = true;
  final _expenseCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final List<Map<String, dynamic>> _expenses = [];
  String _selectedCategory = 'Outros';
  String? _message;

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

  String get _budgetKey => 'user:${widget.username}:budget';
  String get _spentKey => 'user:${widget.username}:spent';
  String get _expensesKey => 'user:${widget.username}:expenses';

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
    final prefs = await SharedPreferences.getInstance();
    final budget = prefs.getDouble(_budgetKey) ?? 0.0;
    final spent = prefs.getDouble(_spentKey) ?? 0.0;
    final savedExpenses = prefs.getStringList(_expensesKey) ?? [];
    final expenses = <Map<String, dynamic>>[];
    for (final item in savedExpenses) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          expenses.add(decoded);
        }
      } on FormatException {}
    }
    if (!mounted) return;
    setState(() {
      _budget = budget;
      _spent = spent;
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
      setState(() {
        _message = 'Informe um valor válido';
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _spent += value;
    _expenses.add({
      'category': _selectedCategory,
      'description': _descriptionCtrl.text.trim().isEmpty
          ? _selectedCategory
          : _descriptionCtrl.text.trim(),
      'amount': value,
    });
    await prefs.setDouble(_spentKey, _spent);
    await prefs.setStringList(
      _expensesKey,
      _expenses.map(jsonEncode).toList(),
    );
    if (!mounted) return;
    setState(() {
      _message = 'Despesa adicionada';
      _expenseCtrl.clear();
      _descriptionCtrl.clear();
    });
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_spentKey, 0.0);
    await prefs.remove(_expensesKey);
    if (!mounted) return;
    setState(() {
      _spent = 0.0;
      _expenses.clear();
      _message = 'Gastos reiniciados';
    });
  }

  Future<void> _logout() async {
    // simply go back to login
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <String, double>{};
    for (final expense in _expenses) {
      final category = expense['category'] as String;
      final amount = (expense['amount'] as num).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text('Controle - ${widget.username}'),
        actions: [IconButton(onPressed: _logout, icon: Icon(Icons.logout))],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Orçamento: R\$ ${_budget.toStringAsFixed(2)}'),
                  Text('Gasto: R\$ ${_spent.toStringAsFixed(2)}'),
                  if (sortedCategories.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text('Distribuição dos gastos',
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
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
                    SizedBox(height: 8),
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
                                SizedBox(width: 8),
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
                    decoration: InputDecoration(
                        labelText: 'Descrição (ex: Pagamento do carro)'),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(labelText: 'Tipo de despesa'),
                    items: _categories
                        .map((category) => DropdownMenuItem(
                            value: category, child: Text(category)))
                        .toList(),
                    onChanged: (category) =>
                        setState(() => _selectedCategory = category!),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _expenseCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: 'Adicionar despesa (ex: 50.00)'),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: _addExpense, child: Text('Adicionar')),
                  TextButton(
                      onPressed: _reset, child: Text('Reiniciar gastos')),
                  if (_message != null) ...[
                    SizedBox(height: 8),
                    Text(_message!, style: TextStyle(color: Colors.green)),
                  ]
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
    textPainter.text = TextSpan(
      text: 'Gasto / Orçamento',
      style: const TextStyle(fontSize: 11, color: Colors.black54),
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, -8));
  }

  @override
  bool shouldRepaint(covariant _ExpensesChartPainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.colors != colors;
  }
}
