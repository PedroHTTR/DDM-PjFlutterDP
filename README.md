# DDM Pj Flutter DP

Aplicativo Flutter para controle de orçamento e despesas pessoais.

## Como executar

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Abra o terminal na pasta do projeto.
3. Instale as dependências:

   ```powershell
   flutter pub get
   ```

4. Execute no Chrome:

   ```powershell
   flutter run -d chrome
   ```

Para executar no Windows:

```powershell
flutter run -d windows
```

## Validação

```powershell
flutter analyze
```

Durante a execução:

- `r`: hot reload
- `R`: hot restart
- `q`: encerrar o aplicativo

## Estrutura

```text
lib/
├── main.dart
└── screens/
    ├── tela_login.dart
    ├── tela_cadastro.dart
    └── tela_controle.dart
```
