import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction.dart';
import '../../providers/providers.dart';
import 'add_transaction_dialog.dart';

/// A list tile widget that displays summary information for a single [Transaction].
/// Shows the transaction type icon, description, date, and amount with signed indicators (+/-).
class TransactionListItem extends StatelessWidget {
  /// The transaction data to display in the list item.
  final Transaction transaction;

  /// Creates a new [TransactionListItem] instance.
  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: transaction.currencyCode);
    final dateFormat = DateFormat('MMM d, y');

    IconData getTransactionIcon() {
      switch (transaction.type) {
        case TransactionType.withdrawal:
          return FontAwesomeIcons.arrowDown;
        case TransactionType.deposit:
          return FontAwesomeIcons.arrowUp;
        case TransactionType.transfer:
          return FontAwesomeIcons.arrowRightArrowLeft;
        default:
          return FontAwesomeIcons.question;
      }
    }

    Color getTransactionColor() {
      switch (transaction.type) {
        case TransactionType.withdrawal:
          return const Color(0xFFEF4444);
        case TransactionType.deposit:
          return const Color(0xFF10B981);
        case TransactionType.transfer:
          return const Color(0xFF6366F1);
        default:
          return Colors.grey;
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: getTransactionColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: FaIcon(
          getTransactionIcon(),
          color: getTransactionColor(),
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(transaction.date),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          if (transaction.tags != null && transaction.tags!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: transaction.tags!.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200, width: 0.5),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.type == TransactionType.withdrawal
                    ? '-${currencyFormat.format(transaction.amount)}'
                    : '+${currencyFormat.format(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: getTransactionColor(),
                ),
              ),
              if (transaction.tags != null && transaction.tags!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.tags!.first,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Consumer(
            builder: (context, ref, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 22),
                tooltip: 'Transaction Options',
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (context) => AddTransactionDialog(transaction: transaction),
                    );
                  } else if (value == 'delete') {
                    ref.read(transactionsProvider.notifier).deleteTransaction(transaction);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
