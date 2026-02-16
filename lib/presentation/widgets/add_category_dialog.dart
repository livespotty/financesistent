import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/category.dart';
import '../../providers/providers.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  final Category? category;
  final Category? parentCategory;

  const AddCategoryDialog({super.key, this.category, this.parentCategory});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _notesController = TextEditingController(text: widget.category?.notes ?? '');
    _selectedParentId = widget.category?.parentId ?? widget.parentCategory?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final category = widget.category?.copyWith(
            name: _nameController.text,
            parentId: _selectedParentId,
            notes: _notesController.text,
            updatedAt: now,
          ) ??
          Category(
            id: const Uuid().v4(),
            name: _nameController.text,
            parentId: _selectedParentId,
            notes: _notesController.text,
            createdAt: now,
          );

      if (widget.category == null) {
        ref.read(categoriesProvider.notifier).addCategory(category);
      } else {
        ref.read(categoriesProvider.notifier).updateCategory(category);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Groceries',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  // Filter out current category and its descendants to prevent circular references
                  final availableParents = categories.where((c) {
                    if (widget.category == null) return true;
                    return c.id != widget.category!.id && c.parentId != widget.category!.id;
                  }).toList();

                  return DropdownButtonFormField<String?>(
                    value: _selectedParentId,
                    decoration: const InputDecoration(
                      labelText: 'Parent Category',
                      hintText: 'None (Top Level)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (Top Level)'),
                      ),
                      ...availableParents.map((category) {
                        return DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedParentId = value;
                      });
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
