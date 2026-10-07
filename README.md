# DDM Pj Flutter DP

Aplicativo Flutter para controle de orçamento e despesas pessoais.

## Como executar no Chrome

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Abra o terminal na pasta do projeto.
3. Instale as dependências:

   ```powershell
   flutter pub get
   ```

4. Caso os arquivos Web ainda não existam, prepare o SQLite WASM:

   ```powershell
   dart run sqflite_common_ffi_web:setup
   ```

   Esse comando cria `web/sqlite3.wasm` e `web/sqflite_sw.js`.

5. Execute no Chrome, mantendo a mesma porta para preservar os dados do
   IndexedDB:

   ```powershell
   flutter run -d chrome
   ```

## Validação

```powershell
flutter analyze
```

Para testar manualmente a persistência, cadastre um usuário, inclua algumas
despesas, edite e exclua uma delas, use “Reiniciar gastos” e recarregue a
página. O banco deve manter o usuário e o orçamento, enquanto as despesas
devem refletir a última operação realizada.

Durante a execução:

- `r`: hot reload
- `R`: hot restart
- `q`: encerrar o aplicativo

## Como verificar o banco

### Verificar no Chrome

No Chrome, o SQLite é armazenado no `IndexedDB` por meio do SQLite WASM. Para
verificar os dados:

1. Execute a aplicação:

   ```powershell
   flutter run -d chrome
   ```

2. Cadastre um usuário e adicione algumas despesas.
3. Pressione `F12` para abrir o DevTools.
4. Acesse a aba **Application**.
5. No menu lateral, abra **Storage > IndexedDB**.
6. Expanda a origem usada pela aplicação, por exemplo:
   `http://localhost:xxxxx`.
7. Procure o banco relacionado ao aplicativo, normalmente com nome semelhante
   a `ddm_finance.db`.

O banco Web não é salvo como um arquivo `.db` comum. Ele fica dentro do
`IndexedDB` da origem e da porta utilizadas. Portanto, executar a aplicação em
outra porta pode resultar em outro banco vazio.

### Verificar pela aplicação

Também é possível confirmar a persistência pelo fluxo normal:

1. Cadastre um usuário.
2. Adicione uma ou mais despesas.
3. Edite ou exclua uma despesa.
4. Recarregue a página com `Ctrl + R`.
5. Faça login novamente.

O usuário, o orçamento e as despesas devem continuar disponíveis após o
recarregamento.

### Verificar com testes automatizados

O teste de CRUD está em `test/database_service_test.dart`. Execute:

```powershell
flutter test
```

Esse teste verifica cadastro de usuário, rejeição de duplicidade,
autenticação, criação, consulta, atualização e exclusão de despesas.

Também é possível executar as validações principais:

```powershell
flutter analyze
flutter test
flutter build web
```

### Verificar como arquivo SQLite no Windows/Desktop

No Windows/Desktop, o serviço usa SQLite via FFI. Para descobrir o caminho do
arquivo, adicione temporariamente este trecho após a abertura do banco em
`lib/database/database_service.dart`:

```dart
print('Banco SQLite: ${database.path}');
```

Depois execute:

```powershell
flutter run -d windows
```

O caminho será exibido no terminal. O arquivo pode ser aberto com ferramentas
como DB Browser for SQLite, SQLiteStudio ou uma extensão SQLite do VS Code.

### Consultas SQL úteis

Com o arquivo aberto em uma ferramenta SQLite, use:

```sql
SELECT * FROM users;
```

```sql
SELECT * FROM expenses;
```

```sql
SELECT
  users.username,
  expenses.category,
  expenses.description,
  expenses.amount
FROM expenses
JOIN users ON users.id = expenses.user_id;
```

Para calcular o total gasto por usuário:

```sql
SELECT
  user_id,
  SUM(amount) AS total_gasto
FROM expenses
GROUP BY user_id;
```

## Estrutura

```text
lib/
├── main.dart
├── database/
│   └── database_service.dart
├── models/
│   ├── expense.dart
│   └── user.dart
└── screens/
    ├── tela_login.dart
    ├── tela_cadastro.dart
    └── tela_controle.dart
```

## SQLite e APIs locais

O aplicativo usa `sqflite` com `sqflite_common_ffi_web`. No Chrome, o SQLite
WASM é persistido no IndexedDB do navegador; por isso, a mesma origem e porta
devem ser usadas durante os testes.

O serviço em `lib/database/database_service.dart` expõe as operações locais:

- usuários: cadastro, autenticação e consulta por nome;
- despesas: listar, consultar por ID, criar, atualizar, excluir e excluir
  todas as despesas de um usuário.

As consultas usam parâmetros (`whereArgs`) e o banco é inicializado
automaticamente antes da aplicação abrir.

### Tabelas

- `users`: `id`, `username` único, `password` e `budget`.
- `expenses`: `id`, `user_id`, `category`, `description`, `amount` e
  `created_at`, com chave estrangeira para `users` e exclusão em cascata.
