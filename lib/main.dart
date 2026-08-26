import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/tela_login.dart';
import 'screens/tela_cadastro.dart';
import 'screens/tela_controle.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => TelaLogin(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => TelaCadastro(),
      ),
      GoRoute(
        path: '/control',
        name: 'control',
        builder: (context, state) {
          final username = state.queryParameters['username'] ?? '';
          return TelaControle(username: username);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Controle Financeiro',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: _router,
    );
  }
}
