import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/providers.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/transaction_filter_dialog.dart';
import '../widgets/csv_import_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final filters = ref.watch(transactionFiltersProvider);
    
    final hasSearchQuery = filters.searchQuery != null && filters.searchQuery!.trim().isNotEmpty;
    if (_searchController.text != (filters.searchQuery ?? '')) {
      _searchController.text = filters.searchQuery ?? '';
      if (!_isSearching && hasSearchQuery) {
        _isSearching = true;
      }
    }

    final hasNonSearchFilters = filters.type != null || 
                                 filters.accountId != null || 
                                 filters.startDate != null || 
                                 filters.endDate != null ||
                                 filters.categoryId != null ||
                                 (filters.minAmount != null || filters.maxAmount != null);

    final hasActiveFilters = hasNonSearchFilters;




    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  filled: false,
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  ref.read(transactionFiltersProvider.notifier).setSearchQuery(value);
                },
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : FontAwesomeIcons.magnifyingGlass, size: 18),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(transactionFiltersProvider.notifier).setSearchQuery(null);
                }
              });
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.filter, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const TransactionFilterDialog(),
                  );
                },
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.fileImport, size: 18),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CsvImportDialog(),
              );
            },
            tooltip: 'Import from CSV',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) => transactions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.receipt,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      filters.searchQuery != null || hasActiveFilters
                          ? 'No matching transactions'
                          : 'No transactions yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (filters.searchQuery != null || hasActiveFilters)
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(transactionFiltersProvider.notifier).clearFilters();
                          setState(() => _isSearching = false);
                        },
                        child: const Text('Clear all filters'),
                      )
                    else
                      Text(
                        'Add your first transaction to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                  ],
                ),
              )
            : Column(
                children: [
                   if (hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Text('Filters applied', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => ref.read(transactionFiltersProvider.notifier).clearFilters(),
                            child: const Text('Reset', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        return TransactionListItem(
                          transaction: transactions[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddTransactionDialog(),
          );
        },
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Add Transaction'),
      ),
    );
  }
}
