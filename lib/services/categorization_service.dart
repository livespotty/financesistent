import '../domain/models/categorization_rule.dart';
import '../domain/models/transaction.dart';

/// Service for applying auto-categorization rules to transactions.
class CategorizationService {
  /// Applies categorization rules to a transaction and returns the category ID if matched.
  /// Returns null if no rule matches.
  String? applyCategorization(Transaction transaction, List<CategorizationRule> rules) {
    // Sort by priority (already sorted in repository, but ensure it here too)
    final sortedRules = List<CategorizationRule>.from(rules)
      ..sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));

    for (final rule in sortedRules) {
      if (rule.enabled == false) continue;

      if (_matchesRule(transaction.description, rule)) {
        return rule.categoryId;
      }
    }

    return null;
  }

  /// Checks if a description matches a categorization rule.
  bool _matchesRule(String description, CategorizationRule rule) {
    final caseSensitive = rule.caseSensitive ?? true;
    final text = caseSensitive ? description : description.toLowerCase();
    final pattern = caseSensitive ? rule.pattern : rule.pattern.toLowerCase();

    switch (rule.matchType) {
      case RuleMatchType.contains:
        return text.contains(pattern);
      case RuleMatchType.startsWith:
        return text.startsWith(pattern);
      case RuleMatchType.endsWith:
        return text.endsWith(pattern);
      case RuleMatchType.equals:
        return text == pattern;
      case RuleMatchType.regex:
        try {
          final regex = RegExp(
            rule.pattern,
            caseSensitive: caseSensitive,
          );
          return regex.hasMatch(description);
        } catch (e) {
          // Invalid regex, skip this rule
          return false;
        }
    }
  }
}
