import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/models/account.dart';
import '../../providers/providers.dart';
import '../widgets/transaction_list_item.dart';

class AccountDetailsScreen extends ConsumerWidget {
  final Account account;

  const AccountDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(accountBalanceHistoryProvider(account.id));
    final transactionsAsync = ref.watch(accountTransactionsProvider(account.id));
    final currencyFormat = NumberFormat.currency(symbol: account.currencyCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit account logic
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance History',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(account.currentBalance),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: historyAsync.when(
                          data: (history) {
                            if (history.isEmpty) {
                              return const Center(child: Text('No history data available'));
                            }
                            final minX = history.first.date.millisecondsSinceEpoch.toDouble();
                            final maxX = history.last.date.millisecondsSinceEpoch.toDouble();
                            
                            return LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                minX: minX,
                                maxX: maxX,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: history.map((p) {
                                      return FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.balance);
                                    }).toList(),
                                    isCurved: true,
                                    color: Theme.of(context).colorScheme.primary,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surfaceContainerHighest,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                        return LineTooltipItem(
                                          '${DateFormat.yMMMd().format(date)}\n${currencyFormat.format(spot.y)}',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Error: $err')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No transactions for this account')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return TransactionListItem(transaction: transactions[index]);
                  },
                  childCount: transactions.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
