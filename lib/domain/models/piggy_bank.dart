import 'package:freezed_annotation/freezed_annotation.dart';

part 'piggy_bank.freezed.dart';
part 'piggy_bank.g.dart';

@freezed
/// Represents a savings goal or "piggy bank" linked to an account.
abstract class PiggyBank with _$PiggyBank {
  /// Default factory for [PiggyBank].
  const factory PiggyBank({
    required String id,
    required String name,
    required String accountId,
    required double targetAmount,
    required double currentAmount,
    DateTime? targetDate,
    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _PiggyBank;

  /// Creates a [PiggyBank] from a JSON map.
  factory PiggyBank.fromJson(Map<String, dynamic> json) =>
      _$PiggyBankFromJson(json);
}
