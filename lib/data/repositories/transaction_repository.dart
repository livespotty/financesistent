import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/models/transaction.dart' as model;
import '../../domain/models/transaction_type.dart';
import '../database/database.dart';

/// Repository for managing financial transactions in the database.
class TransactionRepository {
  final AppDatabase _db;

  /// Creates a new [TransactionRepository] with the given [AppDatabase].
  TransactionRepository(this._db);

  /// Retrieves all transactions from the database, ordered by date descending.
  Future<List<model.Transaction>> getAllTransactions() async {
    final transactions = await (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return transactions.map(_toModel).toList();
  }

  /// Retrieves a specific transaction by its [id].
  Future<model.Transaction?> getTransactionById(String id) async {
    final transaction = await (_db.select(_db.transactions)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return transaction != null ? _toModel(transaction) : null;
  }

  /// Retrieves transactions within a specific [start] and [end] date range.
  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await (_db.select(_db.transactions)
          ..where((tbl) =>
              tbl.date.isBiggerOrEqualValue(start) &
              tbl.date.isSmallerOrEqualValue(end),)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return transactions.map(_toModel).toList();
  }

  /// Retrieves all transactions associated with a specific [accountId].
  Future<List<model.Transaction>> getTransactionsByAccount(
    String accountId,
  ) async {
    final transactions = await (_db.select(_db.transactions)
          ..where((tbl) =>
              tbl.sourceAccountId.equals(accountId) |
              tbl.destinationAccountId.equals(accountId),)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return transactions.map(_toModel).toList();
  }

  /// Retrieves all transactions associated with a specific [categoryId].
  Future<List<model.Transaction>> getTransactionsByCategory(
    String categoryId,
  ) async {
    final transactions = await (_db.select(_db.transactions)
          ..where((tbl) => tbl.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return transactions.map(_toModel).toList();
  }

  /// Inserts a new [transaction] into the database.
  Future<void> createTransaction(model.Transaction transaction) async {
    await _db.into(_db.transactions).insert(_toCompanion(transaction));
  }

  /// Updates an existing [transaction] record.
  Future<void> updateTransaction(model.Transaction transaction) async {
    await (_db.update(_db.transactions)
          ..where((tbl) => tbl.id.equals(transaction.id)))
        .write(_toCompanion(transaction));
  }

  /// Deletes a transaction with the given [id].
  Future<void> deleteTransaction(String id) async {
    await (_db.delete(_db.transactions)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Maps a database [Transaction] entity to a domain [model.Transaction].
  /// Includes defensive parsing and default values for robustness.
  model.Transaction _toModel(Transaction transaction) {
    try {
      return model.Transaction(
        id: transaction.id,
        type: TransactionType.values.firstWhere(
          (e) => e.name == transaction.type,
          orElse: () => TransactionType.withdrawal,
        ),
        description: transaction.description,
        date: transaction.date,
        amount: transaction.amount,
        currencyCode: transaction.currencyCode,
        sourceAccountId: transaction.sourceAccountId,
        destinationAccountId: transaction.destinationAccountId,
        categoryId: transaction.categoryId,
        budgetId: transaction.budgetId,
        tags: _parseTags(transaction.tags),
        notes: transaction.notes,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
      );
    } catch (e) {
      print('Error parsing transaction ${transaction.id}: $e');
      rethrow;
    }
  }

  /// Safely parses a JSON string of tags into a list of strings.
  List<String>? _parseTags(String? tagsJson) {
    if (tagsJson == null) return null;
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) {
        return List<String>.from(decoded);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Maps a domain [model.Transaction] to a database [TransactionsCompanion].
  TransactionsCompanion _toCompanion(model.Transaction transaction) {
    return TransactionsCompanion(
      id: Value(transaction.id),
      type: Value(transaction.type.name),
      description: Value(transaction.description),
      date: Value(transaction.date),
      amount: Value(transaction.amount),
      currencyCode: Value(transaction.currencyCode),
      sourceAccountId: Value(transaction.sourceAccountId),
      destinationAccountId: Value(transaction.destinationAccountId),
      categoryId: Value(transaction.categoryId),
      budgetId: Value(transaction.budgetId),
      tags: Value(transaction.tags != null ? jsonEncode(transaction.tags) : null),
      notes: Value(transaction.notes),
      createdAt: Value(transaction.createdAt),
      updatedAt: Value(transaction.updatedAt),
    );
  }
}
