import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/models/account.dart';
import '../../providers/providers.dart';
import 'add_account_dialog.dart';
import '../screens/account_details_screen.dart';

/// A card widget that displays information for a specific [Account].
/// Shows the account type icon, name, and current balance with thematic colors.
class AccountCard extends StatelessWidget {
  /// The account data to display.
  final Account account;

  /// Creates a new [AccountCard] instance.
  const AccountCard({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: account.currencyCode);
    
    IconData getAccountIcon() {
      switch (account.type) {
        case AccountType.asset:
          return FontAwesomeIcons.wallet;
        case AccountType.expense:
          return FontAwesomeIcons.arrowDown;
        case AccountType.revenue:
          return FontAwesomeIcons.arrowUp;
        case AccountType.liability:
          return FontAwesomeIcons.creditCard;
      }
    }

    Color getAccountColor() {
      switch (account.type) {
        case AccountType.asset:
          return const Color(0xFF6366F1);
        case AccountType.expense:
          return const Color(0xFFEF4444);
        case AccountType.revenue:
          return const Color(0xFF10B981);
        case AccountType.liability:
          return const Color(0xFFF59E0B);
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountDetailsScreen(account: account),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getAccountColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    getAccountIcon(),
                    color: getAccountColor(),
                    size: 16,
                  ),
                ),
                const Spacer(),
                if (account.active == false)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                Consumer(
                  builder: (context, ref, child) {
                    return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 22),
                      tooltip: 'Account Options',
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(
                            context: context,
                            builder: (context) => AddAccountDialog(account: account),
                          );
                        } else if (value == 'delete') {
                          ref.read(accountsProvider.notifier).deleteAccount(account.id);
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
            const SizedBox(height: 12),
            Text(
              account.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                currencyFormat.format(account.currentBalance),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: getAccountColor(),
                    ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
