import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/models/category.dart';
import '../../providers/providers.dart';
import '../widgets/add_category_dialog.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  List<Category> _getTopLevelCategories(List<Category> categories) {
    return categories.where((c) => c.parentId == null).toList();
  }

  List<Category> _getChildCategories(List<Category> categories, String parentId) {
    return categories.where((c) => c.parentId == parentId).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoriesAsync.when(
        data: (categories) => categories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.tags,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No categories yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Add categories to organize your transactions'),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: _getTopLevelCategories(categories).map((category) {
                  return _CategoryTile(
                    category: category,
                    allCategories: categories,
                    level: 0,
                  );
                }).toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddCategoryDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }
}

class _CategoryTile extends ConsumerStatefulWidget {
  final Category category;
  final List<Category> allCategories;
  final int level;

  const _CategoryTile({
    required this.category,
    required this.allCategories,
    required this.level,
  });

  @override
  ConsumerState<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends ConsumerState<_CategoryTile> {
  bool _isExpanded = false;

  List<Category> get _children {
    return widget.allCategories
        .where((c) => c.parentId == widget.category.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = _children.isNotEmpty;
    final indent = widget.level * 24.0;

    return Column(
      children: [
        Card(
          margin: EdgeInsets.only(bottom: 8, left: indent),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasChildren)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  )
                else
                  const SizedBox(width: 48),
                CircleAvatar(
                  child: FaIcon(
                    widget.level == 0 ? FontAwesomeIcons.tag : FontAwesomeIcons.tags,
                    size: 16,
                  ),
                ),
              ],
            ),
            title: Text(widget.category.name),
            subtitle: widget.category.notes != null ? Text(widget.category.notes!) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: 'Add subcategory',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddCategoryDialog(
                        parentCategory: widget.category,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddCategoryDialog(category: widget.category),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () {
                    // Show confirmation if has children
                    if (hasChildren) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Category'),
                          content: const Text(
                            'This category has subcategories. Deleting it will also delete all subcategories. Continue?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(categoriesProvider.notifier).deleteCategory(widget.category.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ref.read(categoriesProvider.notifier).deleteCategory(widget.category.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && hasChildren)
          ..._children.map((child) {
            return _CategoryTile(
              category: child,
              allCategories: widget.allCategories,
              level: widget.level + 1,
            );
          }),
      ],
    );
  }
}
