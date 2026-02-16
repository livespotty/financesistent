import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance_point.freezed.dart';

@freezed
abstract class BalancePoint with _$BalancePoint {
  const factory BalancePoint({
    required DateTime date,
    required double balance,
  }) = _BalancePoint;
}
