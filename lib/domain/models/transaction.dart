import 'package:freezed_annotation/freezed_annotation.dart';
import 'transaction_type.dart';
export 'transaction_type.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required TransactionType type,
    required String description,
    required DateTime date,
    required double amount,
    required String currencyCode,
    required String sourceAccountId,
    required String destinationAccountId,
    String? categoryId,
    String? budgetId,
    List<String>? tags,
    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
