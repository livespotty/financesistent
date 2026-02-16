import 'package:freezed_annotation/freezed_annotation.dart';

part 'categorization_rule.freezed.dart';
part 'categorization_rule.g.dart';

enum RuleMatchType {
  contains,
  startsWith,
  endsWith,
  equals,
  regex,
}

@freezed
abstract class CategorizationRule with _$CategorizationRule {
  const factory CategorizationRule({
    required String id,
    required String name,
    required String categoryId,
    required RuleMatchType matchType,
    required String pattern,
    bool? caseSensitive,
    int? priority,
    bool? enabled,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _CategorizationRule;

  factory CategorizationRule.fromJson(Map<String, dynamic> json) =>
      _$CategorizationRuleFromJson(json);
}
