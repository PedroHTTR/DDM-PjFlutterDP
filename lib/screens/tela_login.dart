import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({Key? key}) : super(key: key);

  @override
  State<TelaLogin> createState() => _EstadoTelaLogin();
}

class _EstadoTelaLogin extends State<TelaLogin> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final stored = prefs.getString('user:$username:password');
    await Future.delayed(Duration(milliseconds: 300));
    if (!mounted) return;
    if (stored != null && stored == password) {
      // navigate to control and pass username as query param
      context.go('/control?username=${Uri.encodeComponent(username)}');
    } else {
      setState(() {
        _error = 'Usuário ou senha incorretos';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
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
            SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? CircularProgressIndicator() : Text('Entrar'),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: Text('Criar conta'),
            )
          ],
        ),
      ),
    );
  }
}
