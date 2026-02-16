import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// Frequency at which a budget is reset.
enum BudgetPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

@freezed
/// Represents a financial budget with a target amount and period.
abstract class Budget with _$Budget {
  /// Default factory for [Budget].
  const factory Budget({
    required String id,
    required String name,
    required double amount,
    required BudgetPeriod period,
    required DateTime startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    bool? active,
    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Budget;

  /// Creates a [Budget] from a JSON map.
  factory Budget.fromJson(Map<String, dynamic> json) =>
      _$BudgetFromJson(json);
}
