import 'dart:io';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/transaction.dart';
import '../domain/models/transaction_type.dart';
import '../domain/models/account.dart';

/// Service for importing transactions from CSV files.
/// Supports multiple CSV formats and provides flexible column mapping.
class CsvImportService {
  final _uuid = const Uuid();

  /// Import result containing successfully imported transactions and errors.
  CsvImportResult importFromFile(
    File file, {
    required Account defaultAccount,
    String? defaultCategoryId,
    CsvColumnMapping? columnMapping,
  }) {
    try {
      final content = file.readAsStringSync();
      return importFromString(
        content,
        defaultAccount: defaultAccount,
        defaultCategoryId: defaultCategoryId,
        columnMapping: columnMapping,
      );
    } catch (e) {
      return CsvImportResult(
        transactions: [],
        errors: ['Failed to read file: $e'],
        totalRows: 0,
      );
    }
  }

  /// Import transactions from CSV string content.
  CsvImportResult importFromString(
    String csvContent, {
    required Account defaultAccount,
    String? defaultCategoryId,
    CsvColumnMapping? columnMapping,
  }) {
    final List<Transaction> transactions = [];
    final List<String> errors = [];

    try {
      // Parse CSV
      final rows = const CsvToListConverter().convert(csvContent);
      
      if (rows.isEmpty) {
        return CsvImportResult(
          transactions: [],
          errors: ['CSV file is empty'],
          totalRows: 0,
        );
      }

      // Auto-detect column mapping if not provided
      final mapping = columnMapping ?? _autoDetectColumns(rows.first);
      
      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          final transaction = _parseRow(
            row,
            mapping,
            defaultAccount,
            defaultCategoryId,
          );
          
          if (transaction != null) {
            transactions.add(transaction);
          }
        } catch (e) {
          errors.add('Row ${i + 1}: $e');
        }
      }

      return CsvImportResult(
        transactions: transactions,
        errors: errors,
        totalRows: rows.length - 1, // Exclude header
      );
    } catch (e) {
      return CsvImportResult(
        transactions: [],
        errors: ['Failed to parse CSV: $e'],
        totalRows: 0,
      );
    }
  }

  /// Auto-detect column indices based on common header names.
  CsvColumnMapping _autoDetectColumns(List<dynamic> headerRow) {
    final headers = headerRow.map((h) => h.toString().toLowerCase()).toList();
    
    int? findColumn(List<String> possibleNames) {
      for (final name in possibleNames) {
        final index = headers.indexWhere((h) => h.contains(name));
        if (index != -1) return index;
      }
      return null;
    }

    return CsvColumnMapping(
      dateColumn: findColumn(['date', 'transaction date', 'posted date']) ?? 0,
      descriptionColumn: findColumn(['description', 'memo', 'details', 'payee']) ?? 1,
      amountColumn: findColumn(['amount', 'value', 'total']),
      debitColumn: findColumn(['debit', 'withdrawal', 'spent', 'payment']),
      creditColumn: findColumn(['credit', 'deposit', 'received', 'income']),
      categoryColumn: findColumn(['category', 'type', 'class']),
      notesColumn: findColumn(['notes', 'comment', 'reference']),
    );
  }

  /// Parse a single CSV row into a Transaction.
  Transaction? _parseRow(
    List<dynamic> row,
    CsvColumnMapping mapping,
    Account defaultAccount,
    String? defaultCategoryId,
  ) {
    if (row.isEmpty) return null;

    // Extract date
    final dateStr = _getCell(row, mapping.dateColumn);
    final date = _parseDate(dateStr);
    if (date == null) {
      throw Exception('Invalid date format: $dateStr');
    }

    // Extract description
    final description = _getCell(row, mapping.descriptionColumn);
    if (description.isEmpty) {
      throw Exception('Description is required');
    }

    // Determine account type for proper transaction classification
    final isLiabilityAccount = defaultAccount.type == AccountType.liability;
    final isAssetAccount = defaultAccount.type == AccountType.asset;

    // Extract amount and determine type based on account type
    double? amount;
    TransactionType type = TransactionType.withdrawal;

    if (mapping.amountColumn != null) {
      // Single amount column
      final amountStr = _getCell(row, mapping.amountColumn!);
      amount = _parseAmount(amountStr);
      
      if (amount != null) {
        // For ASSET accounts (checking, savings):
        // - Negative amount = money going out (withdrawal/expense)
        // - Positive amount = money coming in (deposit/income)
        //
        // For LIABILITY accounts (credit cards, loans):
        // - Negative amount = payment to reduce liability (deposit/payment)
        // - Positive amount = charge increasing liability (withdrawal/expense)
        
        if (isLiabilityAccount) {
          // Liability: positive = charge (withdrawal), negative = payment (deposit)
          if (amount < 0) {
            type = TransactionType.deposit; // Payment to card
            amount = amount.abs();
          } else {
            type = TransactionType.withdrawal; // Charge on card
          }
        } else {
          // Asset: negative = expense (withdrawal), positive = income (deposit)
          if (amount < 0) {
            type = TransactionType.withdrawal;
            amount = amount.abs();
          } else {
            type = TransactionType.deposit;
          }
        }
      }
    } else if (mapping.debitColumn != null && mapping.creditColumn != null) {
      // Separate debit/credit columns
      final debitStr = _getCell(row, mapping.debitColumn!);
      final creditStr = _getCell(row, mapping.creditColumn!);
      
      final debit = _parseAmount(debitStr);
      final credit = _parseAmount(creditStr);
      
      // For ASSET accounts:
      // - Debit column = money going out (withdrawal/expense)
      // - Credit column = money coming in (deposit/income)
      //
      // For LIABILITY accounts:
      // - Debit column = charges/purchases (withdrawal/expense)
      // - Credit column = payments (deposit/payment to card)
      //
      // Note: The logic is the same for both account types when using
      // separate debit/credit columns, as the column names already
      // indicate the direction of money flow
      
      if (debit != null && debit > 0) {
        amount = debit;
        type = TransactionType.withdrawal; // Expense or charge
      } else if (credit != null && credit > 0) {
        amount = credit;
        type = TransactionType.deposit; // Income or payment
      }
    }

    if (amount == null || amount == 0) {
      throw Exception('Invalid or missing amount');
    }

    // Extract optional fields
    final category = mapping.categoryColumn != null 
        ? _getCell(row, mapping.categoryColumn!) 
        : null;
    
    final notes = mapping.notesColumn != null 
        ? _getCell(row, mapping.notesColumn!) 
        : null;

    // Create transaction with correct account assignment
    // For ALL account types:
    // - Withdrawal (expense/charge): source = this account, destination = empty
    // - Deposit (income/payment): source = empty, destination = this account
    return Transaction(
      id: _uuid.v4(),
      type: type,
      amount: amount,
      currencyCode: defaultAccount.currencyCode,
      description: description,
      date: date,
      sourceAccountId: type == TransactionType.withdrawal ? defaultAccount.id : '',
      destinationAccountId: type == TransactionType.deposit ? defaultAccount.id : '',
      categoryId: defaultCategoryId,
      notes: notes?.isNotEmpty == true ? notes : null,
      tags: category != null && category.isNotEmpty ? [category] : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Safely get a cell value from a row.
  String _getCell(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index]?.toString().trim() ?? '';
  }

  /// Parse a date string in various common formats.
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // Try ISO format first
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // Try common US formats: MM/DD/YYYY, M/D/YYYY
    final usDatePattern = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final usMatch = usDatePattern.firstMatch(dateStr);
    if (usMatch != null) {
      final month = int.parse(usMatch.group(1)!);
      final day = int.parse(usMatch.group(2)!);
      final year = int.parse(usMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // Try European format: DD/MM/YYYY, D/M/YYYY
    final euDatePattern = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final euMatch = euDatePattern.firstMatch(dateStr);
    if (euMatch != null) {
      final day = int.parse(euMatch.group(1)!);
      final month = int.parse(euMatch.group(2)!);
      final year = int.parse(euMatch.group(3)!);
      // Heuristic: if day > 12, it's definitely DD/MM/YYYY
      if (day > 12) {
        return DateTime(year, month, day);
      }
    }

    // Try dash format: YYYY-MM-DD
    final dashPattern = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
    final dashMatch = dashPattern.firstMatch(dateStr);
    if (dashMatch != null) {
      final year = int.parse(dashMatch.group(1)!);
      final month = int.parse(dashMatch.group(2)!);
      final day = int.parse(dashMatch.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }

  /// Parse an amount string, handling currency symbols and formatting.
  double? _parseAmount(String amountStr) {
    if (amountStr.isEmpty) return null;

    // Remove currency symbols, spaces, and commas
    String cleaned = amountStr
        .replaceAll(RegExp(r'[\$£€¥,\s]'), '')
        .replaceAll('(', '-')
        .replaceAll(')', '')
        .trim();

    try {
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }
}

/// Column mapping for CSV import.
class CsvColumnMapping {
  final int dateColumn;
  final int descriptionColumn;
  final int? amountColumn; // Single amount column (can be negative)
  final int? debitColumn; // Separate debit column
  final int? creditColumn; // Separate credit column
  final int? categoryColumn;
  final int? notesColumn;

  CsvColumnMapping({
    required this.dateColumn,
    required this.descriptionColumn,
    this.amountColumn,
    this.debitColumn,
    this.creditColumn,
    this.categoryColumn,
    this.notesColumn,
  });
}

/// Result of CSV import operation.
class CsvImportResult {
  final List<Transaction> transactions;
  final List<String> errors;
  final int totalRows;

  CsvImportResult({
    required this.transactions,
    required this.errors,
    required this.totalRows,
  });

  int get successCount => transactions.length;
  int get errorCount => errors.length;
  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => transactions.isNotEmpty && errors.isEmpty;
}
