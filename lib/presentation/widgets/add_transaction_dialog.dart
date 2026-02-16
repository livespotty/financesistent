import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../../providers/providers.dart';

/// A dialog that allows users to record a new financial transaction.
/// Supports expenses, income, and transfers between accounts.
class AddTransactionDialog extends ConsumerStatefulWidget {
  /// The existing transaction to edit, if any.
  final Transaction? transaction;

  /// Creates a new [AddTransactionDialog] instance.
  const AddTransactionDialog({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}
class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.withdrawal;
  String? _selectedSourceAccount;
  String? _selectedDestinationAccount;
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'USD';
  String? _selectedCategoryId;
  List<String> _tags = [];
  final _tagController = TextEditingController();
  Timer? _debounceTimer;
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _descriptionController.text = widget.transaction!.description;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes ?? '';
      _selectedType = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
      _selectedCurrency = widget.transaction!.currencyCode;
      
      if (_selectedType == TransactionType.deposit) {
        _selectedSourceAccount = widget.transaction!.destinationAccountId;
      } else {
        _selectedSourceAccount = widget.transaction!.sourceAccountId;
      }
      
      if (_selectedType == TransactionType.transfer) {
        _selectedDestinationAccount = widget.transaction!.destinationAccountId;
      }
      
      _tags = widget.transaction!.tags ?? [];
      _selectedCategoryId = widget.transaction!.categoryId;
    }
    
    // Listen to description changes for auto-categorization
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      if (_descriptionController.text.trim().isEmpty) return;
      
      // If user has already manually selected a category, don't overwrite it
      // unless they clear it or we want to be more aggressive.
      // For now, let's only suggest if it is null.
      if (_selectedCategoryId != null) return;

      final description = _descriptionController.text;
      final rulesNotifier = ref.read(categorizationRulesProvider.notifier);

      // 1. Try strict rules first (Regex)
      String? categoryId = await rulesNotifier.applyCategorization(description);

      // 2. If no rule matched, try AI
      if (categoryId == null && mounted) {
        setState(() => _isAiLoading = true);
        categoryId = await rulesNotifier.suggestCategoryWithAI(description);
        if (mounted) setState(() => _isAiLoading = false);
      }

      if (categoryId != null && mounted && _selectedCategoryId == null) {
        setState(() {
          _selectedCategoryId = categoryId;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSourceAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an account')),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      String sourceId = _selectedSourceAccount!;
      String destId = _selectedSourceAccount!; // Default placeholder

      if (_selectedType == TransactionType.deposit) {
        destId = _selectedSourceAccount!;
        sourceId = _selectedSourceAccount!; 
      } else if (_selectedType == TransactionType.transfer) {
        if (_selectedDestinationAccount == null) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a destination account')),
          );
          return;
        }
        destId = _selectedDestinationAccount!;
      } else {
        // Withdrawal
        destId = _selectedSourceAccount!;
      }

      if (widget.transaction != null) {
        // Edit
        final updatedTransaction = widget.transaction!.copyWith(
          type: _selectedType,
          description: _descriptionController.text,
          date: _selectedDate,
          amount: amount,
          currencyCode: _selectedCurrency,
          sourceAccountId: sourceId,
          destinationAccountId: destId,
          categoryId: _selectedCategoryId,
          tags: _tags.isEmpty ? null : _tags,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        ref.read(transactionsProvider.notifier).updateTransaction(widget.transaction!, updatedTransaction);
      } else {
        // Create
        final transaction = Transaction(
          id: const Uuid().v4(),
          type: _selectedType,
          description: _descriptionController.text,
          date: _selectedDate,
          amount: amount,
          currencyCode: _selectedCurrency,
          sourceAccountId: sourceId,
          destinationAccountId: destId,
          categoryId: _selectedCategoryId,
          tags: _tags.isEmpty ? null : _tags,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: DateTime.now(),
        );
        ref.read(transactionsProvider.notifier).addTransaction(transaction);
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Transaction Type Selector
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment<TransactionType>(
                      value: TransactionType.withdrawal,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward, color: Colors.red),
                    ),
                    ButtonSegment<TransactionType>(
                      value: TransactionType.deposit,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward, color: Colors.green),
                    ),
                    ButtonSegment<TransactionType>(
                      value: TransactionType.transfer,
                      label: Text('Transfer'),
                      icon: Icon(Icons.swap_horiz, color: Colors.blue),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<TransactionType> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: FaIcon(FontAwesomeIcons.pen, size: 18),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Amount and Currency
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: FaIcon(FontAwesomeIcons.moneyBill, size: 18),
                          ),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                        ),
                        items: ['USD', 'EUR', 'GBP', 'JPY', 'CAD'].map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCurrency = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: FaIcon(FontAwesomeIcons.calendar, size: 18),
                      ),
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Accounts
                accountsAsync.when(
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return const Text('No accounts available. Please create an account first.');
                    }
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedSourceAccount,
                          decoration: InputDecoration(
                            labelText: _selectedType == TransactionType.deposit ? 'To Account' : 'From Account',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: FaIcon(FontAwesomeIcons.buildingColumns, size: 18),
                            ),
                          ),
                          items: accounts.map((account) {
                            return DropdownMenuItem(
                              value: account.id,
                              child: Text(account.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSourceAccount = value;
                              // Reset destination if it's the same as source (for transfer)
                              if (_selectedDestinationAccount == value) {
                                _selectedDestinationAccount = null;
                              }
                            });
                          },
                        ),
                        if (_selectedType == TransactionType.transfer) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedDestinationAccount,
                            decoration: const InputDecoration(
                              labelText: 'To Account',
                              border: OutlineInputBorder(),
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(FontAwesomeIcons.buildingColumns, size: 18),
                              ),
                            ),
                            items: accounts.where((a) => a.id != _selectedSourceAccount).map((account) {
                              return DropdownMenuItem(
                                value: account.id,
                                child: Text(account.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDestinationAccount = value;
                              });
                            },
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading accounts'),
                ),
                const SizedBox(height: 16),

                  // Category
                ref.watch(categoriesProvider).when(
                  data: (categories) {
                    return DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category (Optional)',
                        hintText: 'Select or auto-assign',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: FaIcon(FontAwesomeIcons.tag, size: 18),
                        ),
                        suffixIcon: _isAiLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_selectedCategoryId != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategoryId = null;
                                      });
                                    },
                                  )
                                : null),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...categories.map((category) {
                          return DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Tags
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              labelText: 'Tags (Optional)',
                              hintText: 'Add a tag and press Enter',
                              border: OutlineInputBorder(),
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(FontAwesomeIcons.tag, size: 18),
                              ),
                            ),
                            onFieldSubmitted: (value) {
                              if (value.trim().isNotEmpty && !_tags.contains(value.trim())) {
                                setState(() {
                                  _tags.add(value.trim());
                                  _tagController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Add tag',
                          onPressed: () {
                            final value = _tagController.text.trim();
                            if (value.isNotEmpty && !_tags.contains(value)) {
                              setState(() {
                                _tags.add(value);
                                _tagController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _tags.remove(tag);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: FaIcon(FontAwesomeIcons.noteSticky, size: 18),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(widget.transaction != null ? 'Save Changes' : 'Add Transaction'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
