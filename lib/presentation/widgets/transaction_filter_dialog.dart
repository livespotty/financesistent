import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_type.dart';
import '../../providers/providers.dart';

class TransactionFilterDialog extends ConsumerStatefulWidget {
  const TransactionFilterDialog({super.key});

  @override
  ConsumerState<TransactionFilterDialog> createState() => _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends ConsumerState<TransactionFilterDialog> {
  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(transactionFiltersProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final dateFormat = DateFormat.yMMMd();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Transactions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(transactionFiltersProvider.notifier).clearFilters();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Transaction Type
            const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: TransactionType.withdrawal, label: Text('Expense')),
                ButtonSegment(value: TransactionType.deposit, label: Text('Income')),
                ButtonSegment(value: TransactionType.transfer, label: Text('Transfer')),
              ],
              selected: {filters.type},
              onSelectionChanged: (Set<TransactionType?> value) {
                if (value.isNotEmpty) {
                  ref.read(transactionFiltersProvider.notifier).setTransactionType(value.first);
                }
              },
            ),
            const SizedBox(height: 24),

            // Account
            const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            accountsAsync.when(
              data: (accounts) => DropdownButtonFormField<String?>(
                value: filters.accountId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Accounts')),
                  ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                ],
                onChanged: (value) {
                  ref.read(transactionFiltersProvider.notifier).setAccountId(value);
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading accounts'),
            ),
            const SizedBox(height: 24),

            // Category
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ref.watch(categoriesProvider).when(
              data: (categories) => DropdownButtonFormField<String?>(
                value: filters.categoryId,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  suffixIcon: filters.categoryId != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            ref.read(transactionFiltersProvider.notifier).setCategoryId(null);
                          },
                        )
                      : null,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (value) {
                  ref.read(transactionFiltersProvider.notifier).setCategoryId(value);
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading categories'),
            ),
            const SizedBox(height: 24),

            // Date Range
            const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: filters.startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        ref.read(transactionFiltersProvider.notifier).setDateRange(date, filters.endDate);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(filters.startDate != null ? dateFormat.format(filters.startDate!) : 'Start Date'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: filters.endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        ref.read(transactionFiltersProvider.notifier).setDateRange(filters.startDate, date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(filters.endDate != null ? dateFormat.format(filters.endDate!) : 'End Date'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
