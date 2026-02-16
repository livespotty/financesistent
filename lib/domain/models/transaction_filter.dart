import 'package:freezed_annotation/freezed_annotation.dart';
import 'transaction_type.dart';

part 'transaction_filter.freezed.dart';

@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    String? searchQuery,
    TransactionType? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
  }) = _TransactionFilter;

  factory TransactionFilter.initial() => const TransactionFilter();
}
