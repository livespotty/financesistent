import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// Represents the high-level classification of an account.
/// This determines how the account behaves in accounting calculations.
enum AccountType {
  /// Accounts that represent resources owned (e.g., Cash, Bank Accounts).
  /// These typically have a positive balance.
  asset,

  /// Accounts that represent money effectively spent or flowing out.
  /// Used for categorizing expenses.
  expense,

  /// Accounts that represent sources of income.
  /// Used for tracking earnings.
  revenue,

  /// Accounts that represent debts or obligations (e.g., Loans, Credit Cards).
  /// These typically have a negative balance or represent money owed.
  liability,
}

/// Defines the specific role or purpose of an Asset or Liability account.
/// This helps in UI presentation and specific business logic.
enum AccountRole {
  /// A standard checking or current account used for daily transactions.
  defaultAsset,

  /// A joint account shared with another person.
  sharedAsset,

  /// An account dedicated to savings.
  savingAsset,

  /// A credit card account. While strictly a liability, it is often treated
  /// as a spending account in personal finance apps.
  ccAsset,

  /// Represents physical cash on hand.
  cashWallet,
}

@freezed
abstract class Account with _$Account {
  const factory Account({
    required String id,
    required String name,
    /// The primary category of the account (Asset, Liability, etc.).
    required AccountType type,
    
    /// Optional specific role for the account (e.g., Savings, Cash Wallet).
    AccountRole? role,
    
    required String currencyCode,
    required double currentBalance,
    required double openingBalance,
    String? notes,
    bool? active,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
