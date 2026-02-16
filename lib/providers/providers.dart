import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/database/database.dart' as db;
import '../data/repositories/account_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/categorization_rule_repository.dart';
import '../domain/models/account.dart';
import '../domain/models/transaction.dart';
import '../domain/models/transaction_type.dart';
import '../domain/models/transaction_filter.dart';
import '../domain/models/balance_point.dart';
import '../domain/models/category.dart';
import '../domain/models/categorization_rule.dart';
import '../services/categorization_service.dart';
import '../services/ollama_service.dart';
import 'settings_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

part 'providers.g.dart';

/// Provides the SharedPreferences instance.
/// Must be overridden in main() with a resolved SharedPreferences instance.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferences must be overridden');
}

@Riverpod(keepAlive: true)
class Navigation extends _$Navigation {
  @override
  int build() {
    return 0; // Dashboard by default
  }

  void setTab(int index) {
    state = index;
  }
}

// Database Provider
@Riverpod(keepAlive: true)
/// Provides the singleton instance of the [db.AppDatabase].
db.AppDatabase database(Ref ref) {
  return db.AppDatabase();
}

// Repository Providers
@riverpod
/// Provides the [AccountRepository] instance.
AccountRepository accountRepository(Ref ref) {
  final database = ref.watch(databaseProvider);
  return AccountRepository(database);
}
@riverpod
/// Provides the [CategoryRepository] instance.
CategoryRepository categoryRepository(Ref ref) {
  final database = ref.watch(databaseProvider);
  return CategoryRepository(database);
}

@riverpod
/// Provides the [TransactionRepository] instance.
TransactionRepository transactionRepository(Ref ref) {
  final database = ref.watch(databaseProvider);
  return TransactionRepository(database);
}

@riverpod
/// Provides the [CategorizationRuleRepository] instance.
CategorizationRuleRepository categorizationRuleRepository(Ref ref) {
  final database = ref.watch(databaseProvider);
  return CategorizationRuleRepository(database);
}

@riverpod
/// Provides the [CategorizationService] instance.
CategorizationService categorizationService(Ref ref) {
  return CategorizationService();
}

@riverpod
/// Provides the [OllamaService] instance.
OllamaService ollamaService(Ref ref) {
  final settings = ref.watch(settingsProvider);
  
  // Create service with current settings.
  // When settings change, this provider will rebuild and return a new service instance.
  return OllamaService(
    baseUrl: settings.ollamaBaseUrl,
    model: settings.ollamaModel,
  );
}

// Account Providers
@riverpod
/// Manages the state and operations for accounts.
class Accounts extends _$Accounts {
  @override
  FutureOr<List<Account>> build() async {
    final repository = ref.watch(accountRepositoryProvider);
    return repository.getAllAccounts();
  }

  /// Adds a new [account] and refreshes the state.
  Future<void> addAccount(Account account) async {
    final repository = ref.read(accountRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createAccount(account);
      return repository.getAllAccounts();
    });
  }

  /// Updates an existing [account] and refreshes the state.
  Future<void> updateAccount(Account account) async {
    final repository = ref.read(accountRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateAccount(account);
      return repository.getAllAccounts();
    });
  }

  /// Deletes an account by [id] and refreshes the state.
  Future<void> deleteAccount(String id) async {
    final repository = ref.read(accountRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteAccount(id);
      return repository.getAllAccounts();
    });
  }

  /// Manually triggers a refresh of the accounts list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
/// Provides a filtered list of accounts that are of type 'asset'.
FutureOr<List<Account>> assetAccounts(Ref ref) async {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.value?.where((a) => a.type == AccountType.asset).toList() ?? [];
}

// Transaction Providers
@Riverpod(keepAlive: true)
/// Manages the state and operations for transactions.
class Transactions extends _$Transactions {
  @override
  FutureOr<List<Transaction>> build() async {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getAllTransactions();
  }

  /// Adds a new [transaction], updates associated account balances, and refreshes state.
  Future<void> addTransaction(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final accountRepository = ref.read(accountRepositoryProvider);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createTransaction(transaction);
      await _updateBalancesForNewTransaction(transaction, accountRepository);
      
      // Invalidate accounts to trigger refresh across the app
      ref.invalidate(accountsProvider);
      return repository.getAllTransactions();
    });
  }

  /// Deletes a [transaction], reverses its balance effect, and refreshes state.
  Future<void> deleteTransaction(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final accountRepository = ref.read(accountRepositoryProvider);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteTransaction(transaction.id);
      await _reverseBalancesForTransaction(transaction, accountRepository);
      
      ref.invalidate(accountsProvider);
      return repository.getAllTransactions();
    });
  }

  /// Updates a [transaction]. For simplicity, it reverses the old effect and applies the new one.
  Future<void> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    final accountRepository = ref.read(accountRepositoryProvider);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 1. Reverse old effect
      await _reverseBalancesForTransaction(oldTransaction, accountRepository);
      // 2. Update transaction in DB
      await repository.updateTransaction(newTransaction);
      // 3. Apply new effect
      await _updateBalancesForNewTransaction(newTransaction, accountRepository);
      
      ref.invalidate(accountsProvider);
      return repository.getAllTransactions();
    });
  }

  Future<void> _updateBalancesForNewTransaction(Transaction t, AccountRepository repo) async {
    if (t.type == TransactionType.withdrawal) {
      final account = await repo.getAccountById(t.sourceAccountId);
      if (account != null) {
        await repo.updateAccountBalance(account.id, account.currentBalance - t.amount);
      }
    } else if (t.type == TransactionType.deposit) {
      final account = await repo.getAccountById(t.destinationAccountId);
      if (account != null) {
        await repo.updateAccountBalance(account.id, account.currentBalance + t.amount);
      }
    } else if (t.type == TransactionType.transfer) {
      final source = await repo.getAccountById(t.sourceAccountId);
      final dest = await repo.getAccountById(t.destinationAccountId);
      if (source != null) await repo.updateAccountBalance(source.id, source.currentBalance - t.amount);
      if (dest != null) await repo.updateAccountBalance(dest.id, dest.currentBalance + t.amount);
    }
  }

  Future<void> _reverseBalancesForTransaction(Transaction t, AccountRepository repo) async {
    if (t.type == TransactionType.withdrawal) {
      final account = await repo.getAccountById(t.sourceAccountId);
      if (account != null) {
        await repo.updateAccountBalance(account.id, account.currentBalance + t.amount);
      }
    } else if (t.type == TransactionType.deposit) {
      final account = await repo.getAccountById(t.destinationAccountId);
      if (account != null) {
        await repo.updateAccountBalance(account.id, account.currentBalance - t.amount);
      }
    } else if (t.type == TransactionType.transfer) {
      final source = await repo.getAccountById(t.sourceAccountId);
      final dest = await repo.getAccountById(t.destinationAccountId);
      if (source != null) await repo.updateAccountBalance(source.id, source.currentBalance + t.amount);
      if (dest != null) await repo.updateAccountBalance(dest.id, dest.currentBalance - t.amount);
    }
  }

  /// Manually triggers a refresh of the transactions list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// Filter Providers
@Riverpod(keepAlive: true)
class TransactionFilters extends _$TransactionFilters {
  @override
  TransactionFilter build() => TransactionFilter.initial();

  void setSearchQuery(String? query) => state = state.copyWith(searchQuery: query);
  void setTransactionType(TransactionType? t) => state = state.copyWith(type: t);
  void setAccountId(String? accountId) => state = state.copyWith(accountId: accountId);
  void setCategoryId(String? categoryId) => state = state.copyWith(categoryId: categoryId);
  void setDateRange(DateTime? start, DateTime? end) => state = state.copyWith(startDate: start, endDate: end);
  void setFilters(TransactionFilter filter) => state = filter;
  void clearFilters() => state = TransactionFilter.initial();
}

@Riverpod(keepAlive: true)
FutureOr<List<Transaction>> filteredTransactions(Ref ref) async {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filters = ref.watch(transactionFiltersProvider);

  final transactions = transactionsAsync.value ?? [];

  return transactions.where((t) {
    // Search Query
    if (filters.searchQuery != null && filters.searchQuery!.trim().isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase().trim();
      final inDescription = t.description.toLowerCase().contains(query);
      final inNotes = t.notes?.toLowerCase().contains(query) ?? false;
      final inTags = t.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false;
      if (!inDescription && !inNotes && !inTags) return false;
    }

    // Type
    if (filters.type != null && t.type != filters.type) return false;

    // Account
    if (filters.accountId != null && 
        t.sourceAccountId != filters.accountId && 
        t.destinationAccountId != filters.accountId) return false;

    // Category
    if (filters.categoryId != null && t.categoryId != filters.categoryId) return false;

    // Date Range
    if (filters.startDate != null) {
      final start = DateTime(filters.startDate!.year, filters.startDate!.month, filters.startDate!.day);
      if (t.date.isBefore(start)) return false;
    }
    if (filters.endDate != null) {
      final end = DateTime(filters.endDate!.year, filters.endDate!.month, filters.endDate!.day, 23, 59, 59);
      if (t.date.isAfter(end)) return false;
    }

    // Tags
    if (filters.tags != null && filters.tags!.isNotEmpty) {
      if (t.tags == null || !filters.tags!.every((filterTag) => t.tags!.contains(filterTag))) {
        return false;
      }
    }

    return true;
  }).toList();
}

@riverpod
FutureOr<List<Transaction>> accountTransactions(Ref ref, String accountId) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionsByAccount(accountId);
}

@riverpod
/// Provides transactions from the last 30 days.
FutureOr<List<Transaction>> recentTransactions(Ref ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  return repository.getTransactionsByDateRange(thirtyDaysAgo, now);
}

// Statistics Providers
@riverpod
/// Calculates the total balance across all asset accounts.
FutureOr<double> totalBalance(Ref ref) async {
  final accountsAsync = ref.watch(assetAccountsProvider);
  final accountsList = accountsAsync.value ?? [];
  return accountsList.fold<double>(0.0, (sum, account) => sum + account.currentBalance);
}

@riverpod
/// Calculates total expenses (withdrawals) for the current month.
FutureOr<double> monthlyExpenses(Ref ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final transactionsList = await repository.getTransactionsByDateRange(
    startOfMonth,
    now,
  );
  
  return transactionsList
      .where((t) => t.type == TransactionType.withdrawal)
      .fold<double>(0.0, (sum, t) => sum + t.amount);
}

@riverpod
/// Calculates total income (deposits) for the current month.
FutureOr<double> monthlyIncome(Ref ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final transactionsList = await repository.getTransactionsByDateRange(
    startOfMonth,
    now,
  );
  
  return transactionsList
      .where((t) => t.type == TransactionType.deposit)
      .fold<double>(0.0, (sum, t) => sum + t.amount);
}

@riverpod
FutureOr<List<BalancePoint>> accountBalanceHistory(Ref ref, String accountId) async {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);

  final account = await accountRepo.getAccountById(accountId);
  if (account == null) return [];

  final transactions = await transactionRepo.getTransactionsByAccount(accountId);
  // Sort by date ascending for sequential calculation
  final sortedTransactions = transactions..sort((a, b) => a.date.compareTo(b.date));

  final history = <BalancePoint>[];
  double currentBalance = account.openingBalance;

  // Add initial point
  history.add(BalancePoint(
    date: account.createdAt.subtract(const Duration(seconds: 1)),
    balance: currentBalance,
  ));

  for (final t in sortedTransactions) {
    if (t.type == TransactionType.withdrawal) {
      if (t.sourceAccountId == accountId) {
        currentBalance -= t.amount;
      }
    } else if (t.type == TransactionType.deposit) {
      if (t.destinationAccountId == accountId) {
        currentBalance += t.amount;
      }
    } else if (t.type == TransactionType.transfer) {
      if (t.sourceAccountId == accountId) {
        currentBalance -= t.amount;
      } else if (t.destinationAccountId == accountId) {
        currentBalance += t.amount;
      }
    }
    
    history.add(BalancePoint(
      date: t.date,
      balance: currentBalance,
    ));
  }

  return history;
}

@riverpod
/// Manages the state and operations for categories.
class Categories extends _$Categories {
  @override
  FutureOr<List<Category>> build() async {
    final repository = ref.watch(categoryRepositoryProvider);
    return repository.getAllCategories();
  }

  /// Adds a new [category] and refreshes state.
  Future<void> addCategory(Category category) async {
    final repository = ref.watch(categoryRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createCategory(category);
      return repository.getAllCategories();
    });
  }

  /// Updates an existing [category] and refreshes state.
  Future<void> updateCategory(Category category) async {
    final repository = ref.watch(categoryRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateCategory(category);
      return repository.getAllCategories();
    });
  }

  /// Deletes a category by [id] and refreshes state.
  Future<void> deleteCategory(String id) async {
    final repository = ref.watch(categoryRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteCategory(id);
      return repository.getAllCategories();
    });
  }
}
@riverpod
/// Manages the state and operations for categorization rules.
class CategorizationRules extends _$CategorizationRules {
  @override
  FutureOr<List<CategorizationRule>> build() async {
    final repository = ref.watch(categorizationRuleRepositoryProvider);
    return repository.getAllRules();
  }

  /// Adds a new categorization rule and refreshes state.
  Future<void> addRule(CategorizationRule rule) async {
    final repository = ref.watch(categorizationRuleRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createRule(rule);
      return repository.getAllRules();
    });
  }

  /// Updates an existing categorization rule and refreshes state.
  Future<void> updateRule(CategorizationRule rule) async {
    final repository = ref.watch(categorizationRuleRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateRule(rule);
      return repository.getAllRules();
    });
  }

  /// Deletes a categorization rule by [id] and refreshes state.
  Future<void> deleteRule(String id) async {
    final repository = ref.watch(categorizationRuleRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteRule(id);
      return repository.getAllRules();
    });
  }

  /// Applies categorization rules to a transaction description.
  /// Returns the category ID if a rule matches, null otherwise.
  Future<String?> applyCategorization(String description) async {
    final repository = ref.watch(categorizationRuleRepositoryProvider);
    final service = ref.watch(categorizationServiceProvider);
    final rules = await repository.getEnabledRules();
    
    // Create a temporary transaction for matching
    final tempTransaction = Transaction(
      id: '',
      type: TransactionType.withdrawal,
      description: description,
      date: DateTime.now(),
      amount: 0,
      currencyCode: 'USD',
      sourceAccountId: '',
      destinationAccountId: '',
      createdAt: DateTime.now(),
    );
    
    return service.applyCategorization(tempTransaction, rules);
  }

  /// Uses local AI (Ollama) to guess the category for a transaction description.
  Future<String?> suggestCategoryWithAI(String description) async {
    final settings = ref.read(settingsProvider);
    if (!settings.enableAi) return null;

    final ollama = ref.read(ollamaServiceProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    
    // Check connection first to avoid hanging if Ollama isn't running
    final isConnected = await ollama.checkConnection();
    if (!isConnected) return null;

    final categories = await categoryRepo.getAllCategories();
    
    return ollama.categorizeTransaction(description, categories);
  }
}
