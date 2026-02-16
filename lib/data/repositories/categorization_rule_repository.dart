import 'package:drift/drift.dart';
import '../../domain/models/categorization_rule.dart' as model;
import '../database/database.dart';

/// Repository for managing auto-categorization rules.
class CategorizationRuleRepository {
  final AppDatabase _db;

  CategorizationRuleRepository(this._db);

  /// Retrieves all categorization rules, ordered by priority (descending).
  Future<List<model.CategorizationRule>> getAllRules() async {
    final rules = await (_db.select(_db.categorizationRules)
          ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
        .get();
    return rules.map(_toModel).toList();
  }

  /// Retrieves only enabled rules, ordered by priority.
  Future<List<model.CategorizationRule>> getEnabledRules() async {
    final rules = await (_db.select(_db.categorizationRules)
          ..where((tbl) => tbl.enabled.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
        .get();
    return rules.map(_toModel).toList();
  }

  /// Retrieves a specific rule by its [id].
  Future<model.CategorizationRule?> getRuleById(String id) async {
    final rule = await (_db.select(_db.categorizationRules)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return rule != null ? _toModel(rule) : null;
  }

  /// Creates a new categorization rule.
  Future<void> createRule(model.CategorizationRule rule) async {
    await _db.into(_db.categorizationRules).insert(_toCompanion(rule));
  }

  /// Updates an existing categorization rule.
  Future<void> updateRule(model.CategorizationRule rule) async {
    await (_db.update(_db.categorizationRules)
          ..where((tbl) => tbl.id.equals(rule.id)))
        .write(_toCompanion(rule));
  }

  /// Deletes a categorization rule by [id].
  Future<void> deleteRule(String id) async {
    await (_db.delete(_db.categorizationRules)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Maps database entity to domain model.
  model.CategorizationRule _toModel(CategorizationRule rule) {
    return model.CategorizationRule(
      id: rule.id,
      name: rule.name,
      categoryId: rule.categoryId,
      matchType: model.RuleMatchType.values[rule.matchType],
      pattern: rule.pattern,
      caseSensitive: rule.caseSensitive,
      priority: rule.priority,
      enabled: rule.enabled,
      createdAt: rule.createdAt,
      updatedAt: rule.updatedAt,
    );
  }

  /// Maps domain model to database companion.
  CategorizationRulesCompanion _toCompanion(model.CategorizationRule rule) {
    return CategorizationRulesCompanion(
      id: Value(rule.id),
      name: Value(rule.name),
      categoryId: Value(rule.categoryId),
      matchType: Value(rule.matchType.index),
      pattern: Value(rule.pattern),
      caseSensitive: Value(rule.caseSensitive ?? true),
      priority: Value(rule.priority ?? 0),
      enabled: Value(rule.enabled ?? true),
      createdAt: Value(rule.createdAt),
      updatedAt: Value(rule.updatedAt),
    );
  }
}
