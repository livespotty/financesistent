import 'package:drift/drift.dart';
import '../../domain/models/category.dart' as model;
import '../database/database.dart';

/// Repository for managing transaction categories in the database.
class CategoryRepository {
  final AppDatabase _db;

  /// Creates a new [CategoryRepository] with the given [AppDatabase].
  CategoryRepository(this._db);

  /// Retrieves all categories from the database.
  Future<List<model.Category>> getAllCategories() async {
    final categories = await _db.select(_db.categories).get();
    return categories.map(_toModel).toList();
  }

  /// Retrieves a specific category by its [id].
  Future<model.Category?> getCategoryById(String id) async {
    final category = await (_db.select(_db.categories)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return category != null ? _toModel(category) : null;
  }

  /// Inserts a new [category] into the database.
  Future<void> createCategory(model.Category category) async {
    await _db.into(_db.categories).insert(_toCompanion(category));
  }

  /// Updates an existing [category] record.
  Future<void> updateCategory(model.Category category) async {
    await (_db.update(_db.categories)
          ..where((tbl) => tbl.id.equals(category.id)))
        .write(_toCompanion(category));
  }

  /// Deletes a category with the given [id] and all its child categories.
  Future<void> deleteCategory(String id) async {
    // First, get all child categories and delete them recursively
    final children = await (_db.select(_db.categories)
          ..where((tbl) => tbl.parentId.equals(id)))
        .get();
    
    for (final child in children) {
      await deleteCategory(child.id);
    }
    
    // Then delete the category itself
    await (_db.delete(_db.categories)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Maps a database [Category] entity to a domain [model.Category].
  model.Category _toModel(Category category) {
    return model.Category(
      id: category.id,
      name: category.name,
      parentId: category.parentId,
      notes: category.notes,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  /// Maps a domain [model.Category] to a database [CategoriesCompanion].
  CategoriesCompanion _toCompanion(model.Category category) {
    return CategoriesCompanion(
      id: Value(category.id),
      name: Value(category.name),
      parentId: Value(category.parentId),
      notes: Value(category.notes),
      createdAt: Value(category.createdAt),
      updatedAt: Value(category.updatedAt),
    );
  }
}
