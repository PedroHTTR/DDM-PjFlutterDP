import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../database/database_service.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _EstadoTelaCadastro();
}

class _EstadoTelaCadastro extends State<TelaCadastro> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final budget =
        double.tryParse(_budgetCtrl.text.replaceAll(',', '.')) ?? 0.0;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Preencha usuário e senha';
        _loading = false;
      });
      return;
    }

    final registered = await DatabaseService.instance.registerUser(
      username: username,
      password: password,
      budget: budget,
    );
    if (!registered) {
      if (!mounted) return;
      setState(() {
        _error = 'Usuário já existe';
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    context.go('/control?username=${Uri.encodeComponent(username)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameCtrl,
              decoration: InputDecoration(labelText: 'Usuário'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _budgetCtrl,
              decoration: InputDecoration(labelText: 'Orçamento (ex: 1200.00)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading ? CircularProgressIndicator() : Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
