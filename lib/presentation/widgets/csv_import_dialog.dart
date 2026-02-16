import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:csv/csv.dart';
import '../../domain/models/account.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../../providers/providers.dart';
import '../../services/csv_import_service.dart';
import 'csv_column_mapping_widget.dart';

/// Dialog for importing transactions from CSV files.
class CsvImportDialog extends ConsumerStatefulWidget {
  const CsvImportDialog({super.key});

  @override
  ConsumerState<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends ConsumerState<CsvImportDialog> {
  File? _selectedFile;
  Account? _selectedAccount;
  String? _selectedCategoryId;
  bool _isImporting = false;
  CsvImportResult? _importResult;
  List<Transaction>? _previewTransactions;
  bool _showColumnMapping = false;
  List<String> _csvHeaders = [];
  List<List<dynamic>> _csvSampleRows = [];
  Map<String, int?> _columnMapping = {};
  CsvColumnMapping? _customMapping;

  final _csvService = CsvImportService();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _importResult = null;
        _previewTransactions = null;
        _showColumnMapping = false;
        _customMapping = null;
      });
      
      // Parse CSV headers
      _parseCsvHeaders();
      
      // Auto-preview first 5 rows
      if (_selectedAccount != null) {
        _previewImport();
      }
    }
  }

  void _parseCsvHeaders() {
    if (_selectedFile == null) return;

    try {
      final content = _selectedFile!.readAsStringSync();
      final rows = const CsvToListConverter().convert(content);
      
      if (rows.isNotEmpty) {
        setState(() {
          _csvHeaders = rows.first.map((h) => h.toString()).toList();
          _csvSampleRows = rows.skip(1).take(5).toList();
          
          // Initialize mapping with null values
          _columnMapping = {
            'date': null,
            'description': null,
            'amount': null,
            'debit': null,
            'credit': null,
            'category': null,
            'notes': null,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse CSV: $e')),
        );
      }
    }
  }

  void _onMappingChanged(Map<String, int?> mapping) {
    setState(() {
      _columnMapping = mapping;
      
      // Create custom column mapping
      _customMapping = CsvColumnMapping(
        dateColumn: mapping['date'] ?? 0,
        descriptionColumn: mapping['description'] ?? 1,
        amountColumn: mapping['amount'],
        debitColumn: mapping['debit'],
        creditColumn: mapping['credit'],
        categoryColumn: mapping['category'],
        notesColumn: mapping['notes'],
      );
    });
    
    // Re-preview with new mapping
    if (_selectedAccount != null) {
      _previewImport();
    }
  }

  Future<void> _previewImport() async {
    if (_selectedFile == null || _selectedAccount == null) return;

    setState(() => _isImporting = true);

    try {
      final result = _csvService.importFromFile(
        _selectedFile!,
        defaultAccount: _selectedAccount!,
        defaultCategoryId: _selectedCategoryId,
        columnMapping: _customMapping,
      );

      setState(() {
        _previewTransactions = result.transactions.take(5).toList();
        _importResult = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview failed: $e')),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _performImport() async {
    if (_selectedFile == null || _selectedAccount == null || _importResult == null) {
      return;
    }

    setState(() => _isImporting = true);

    try {
      final transactionsNotifier = ref.read(transactionsProvider.notifier);
      
      // Import all transactions
      for (final transaction in _importResult!.transactions) {
        await transactionsNotifier.addTransaction(transaction);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${_importResult!.successCount} transactions',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.fileImport,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Import Transactions from CSV',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 1: Select CSV File',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedFile?.path.split('/').last ?? 'No file selected',
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _isImporting ? null : _pickFile,
                                  icon: const FaIcon(FontAwesomeIcons.folderOpen, size: 16),
                                  label: const Text('Browse'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Account Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 2: Select Default Account',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Transactions will be associated with this account',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            accountsAsync.when(
                              data: (accounts) => DropdownButtonFormField<String>(
                                value: _selectedAccount?.id,
                                decoration: const InputDecoration(
                                  labelText: 'Account',
                                  border: OutlineInputBorder(),
                                ),
                                items: accounts.map((account) {
                                  return DropdownMenuItem(
                                    value: account.id,
                                    child: Text(account.name),
                                  );
                                }).toList(),
                                onChanged: _isImporting ? null : (value) {
                                  final account = accounts.firstWhere((a) => a.id == value);
                                  setState(() => _selectedAccount = account);
                                  if (_selectedFile != null) {
                                    _previewImport();
                                  }
                                },
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error loading accounts: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Column Mapping Toggle
                    if (_csvHeaders.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Column Mapping',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _showColumnMapping
                                          ? 'Manually map CSV columns to transaction fields'
                                          : 'Auto-detection enabled. Click to customize mapping.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _showColumnMapping,
                                onChanged: (value) {
                                  setState(() => _showColumnMapping = value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Column Mapping Widget
                    if (_showColumnMapping && _csvHeaders.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CsvColumnMappingWidget(
                            headers: _csvHeaders,
                            sampleRows: _csvSampleRows,
                            initialMapping: _columnMapping,
                            onMappingChanged: _onMappingChanged,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Optional Category
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 3: Default Category (Optional)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            categoriesAsync.when(
                              data: (categories) => DropdownButtonFormField<String>(
                                value: _selectedCategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('None (Uncategorized)'),
                                  ),
                                  ...categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category.id,
                                      child: Text(category.name),
                                    );
                                  }),
                                ],
                                onChanged: _isImporting ? null : (value) {
                                  setState(() => _selectedCategoryId = value);
                                },
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error loading categories: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Preview
                    if (_previewTransactions != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Preview (First 5 Transactions)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: _previewTransactions!.map((t) {
                            return ListTile(
                              leading: FaIcon(
                                t.type == TransactionType.deposit
                                    ? FontAwesomeIcons.arrowDown
                                    : FontAwesomeIcons.arrowUp,
                                color: t.type == TransactionType.deposit
                                    ? Colors.green
                                    : Colors.red,
                                size: 16,
                              ),
                              title: Text(t.description),
                              subtitle: Text(
                                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
                              ),
                              trailing: Text(
                                '\$${t.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: t.type == TransactionType.deposit
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    // Import Summary
                    if (_importResult != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: _importResult!.hasErrors
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Summary',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Total rows: ${_importResult!.totalRows}'),
                              Text('Successfully parsed: ${_importResult!.successCount}'),
                              if (_importResult!.hasErrors) ...[
                                Text('Errors: ${_importResult!.errorCount}'),
                                const SizedBox(height: 8),
                                ...(_importResult!.errors.take(5).map((e) => Text(
                                      '• $e',
                                      style: theme.textTheme.bodySmall,
                                    ))),
                                if (_importResult!.errors.length > 5)
                                  Text(
                                    '... and ${_importResult!.errors.length - 5} more errors',
                                    style: theme.textTheme.bodySmall,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: (_isImporting ||
                            _selectedFile == null ||
                            _selectedAccount == null ||
                            _importResult == null ||
                            _importResult!.transactions.isEmpty)
                        ? null
                        : _performImport,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const FaIcon(FontAwesomeIcons.fileImport, size: 16),
                    label: Text(_isImporting ? 'Importing...' : 'Import'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
