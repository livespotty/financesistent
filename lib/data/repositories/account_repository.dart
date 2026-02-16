import 'package:drift/drift.dart';
import '../../domain/models/account.dart' as model;
import '../database/database.dart';

/// Repository for managing account data in the database.
class AccountRepository {
  final AppDatabase _db;

  /// Creates a new [AccountRepository] with the given [AppDatabase].
  AccountRepository(this._db);

  /// Retrieves all accounts from the database.
  Future<List<model.Account>> getAllAccounts() async {
    final accounts = await _db.select(_db.accounts).get();
    return accounts.map(_toModel).toList();
  }

  /// Retrieves a specific account by its [id].
  Future<model.Account?> getAccountById(String id) async {
    final account = await (_db.select(_db.accounts)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return account != null ? _toModel(account) : null;
  }

  /// Retrieves accounts filtered by [type].
  Future<List<model.Account>> getAccountsByType(model.AccountType type) async {
    final accounts = await (_db.select(_db.accounts)
          ..where((tbl) => tbl.type.equals(type.name)))
        .get();
    return accounts.map(_toModel).toList();
  }

  /// Inserts a new [account] into the database.
  Future<void> createAccount(model.Account account) async {
    await _db.into(_db.accounts).insert(_toCompanion(account));
  }

  /// Updates an existing [account] record.
  Future<void> updateAccount(model.Account account) async {
    await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(account.id)))
        .write(_toCompanion(account));
  }

  /// Deletes an account with the given [id].
  Future<void> deleteAccount(String id) async {
    await (_db.delete(_db.accounts)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Updates the [currentBalance] of an account by its [id].
  Future<void> updateAccountBalance(String id, double newBalance) async {
    await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(id)))
        .write(AccountsCompanion(
      currentBalance: Value(newBalance),
      updatedAt: Value(DateTime.now()),
    ),);
  }

  /// Maps a database [Account] entity to a domain [model.Account].
  model.Account _toModel(Account account) {
    return model.Account(
      id: account.id,
      name: account.name,
      type: model.AccountType.values.firstWhere(
        (e) => e.name == account.type,
      ),
      role: account.role != null
          ? model.AccountRole.values.firstWhere(
              (e) => e.name == account.role,
            )
          : null,
      currencyCode: account.currencyCode,
      currentBalance: account.currentBalance,
      openingBalance: account.openingBalance,
      notes: account.notes,
      active: account.active,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
    );
  }

  /// Maps a domain [model.Account] to a database [AccountsCompanion].
  AccountsCompanion _toCompanion(model.Account account) {
    return AccountsCompanion(
      id: Value(account.id),
      name: Value(account.name),
      type: Value(account.type.name),
      role: Value(account.role?.name),
      currencyCode: Value(account.currencyCode),
      currentBalance: Value(account.currentBalance),
      openingBalance: Value(account.openingBalance),
      notes: Value(account.notes),
      active: Value(account.active ?? true),
      createdAt: Value(account.createdAt),
      updatedAt: Value(account.updatedAt),
    );
  }
}
