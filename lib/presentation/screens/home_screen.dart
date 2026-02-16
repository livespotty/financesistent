import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../widgets/stat_card.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/account_card.dart';
import '../widgets/add_account_dialog.dart';
import 'transactions_screen.dart';
import 'accounts_screen.dart';
import 'budgets_screen.dart';
import 'reports_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';
import 'ai_chat_screen.dart';

/// The main container screen for the application.
/// Manages the [NavigationRail] and switches between different tabs.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a new [HomeScreen] instance.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Removed local _selectedIndex state


  /// The list of primary screens mapped to the navigation rail.
  final List<Widget> _screens = const [
    DashboardTab(),
    AiChatScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    BudgetsScreen(),
    CategoriesScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationProvider);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              ref.read(navigationProvider.notifier).setTab(index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.house),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.robot),
                label: Text('AI Assistant'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.arrowRightArrowLeft),
                label: Text('Transactions'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.buildingColumns),
                label: Text('Accounts'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.chartPie),
                label: Text('Budgets'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.tag),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.chartLine),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.gear),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[selectedIndex],
          ),
        ],
      ),
    );
  }
}

/// The main dashboard view providing a financial summary.
/// Uses a [CustomScrollView] with slivers for high performance on large datasets.
class DashboardTab extends ConsumerWidget {
  /// Creates a new [DashboardTab] instance.
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = ref.watch(totalBalanceProvider);
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpenses = ref.watch(monthlyExpensesProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final accounts = ref.watch(accountsProvider);

    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.bell),
              onPressed: () {},
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.gear),
              onPressed: () {},
            ),
            const SizedBox(width: 16),
          ],
        ),
        
        // Statistics Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: totalBalance.maybeWhen(
                    data: (balance) => StatCard(
                      title: 'Total Balance',
                      value: currencyFormat.format(balance),
                      icon: FontAwesomeIcons.wallet,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                    orElse: () => const StatCard(
                      title: 'Total Balance',
                      value: '...',
                      icon: FontAwesomeIcons.wallet,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: monthlyIncome.maybeWhen(
                    data: (income) => StatCard(
                      title: 'Monthly Income',
                      value: currencyFormat.format(income),
                      icon: FontAwesomeIcons.arrowTrendUp,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                    ),
                    orElse: () => const StatCard(
                      title: 'Monthly Income',
                      value: '...',
                      icon: FontAwesomeIcons.arrowTrendUp,
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: monthlyExpenses.maybeWhen(
                    data: (expenses) => StatCard(
                      title: 'Monthly Expenses',
                      value: currencyFormat.format(expenses),
                      icon: FontAwesomeIcons.arrowTrendDown,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                    ),
                    orElse: () => const StatCard(
                      title: 'Monthly Expenses',
                      value: '...',
                      icon: FontAwesomeIcons.arrowTrendDown,
                      gradient: LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Accounts Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accounts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddAccountDialog(),
                    );
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('Add Account'),
                ),
              ],
            ),
          ),
        ),

        // Accounts Grid
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: accounts.maybeWhen(
            data: (accountList) => accountList.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No accounts yet. Create one to get started!'),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => AccountCard(account: accountList[index]),
                      childCount: accountList.length,
                    ),
                  ),
            orElse: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),

        // Recent Transactions Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // This is handled in the parent HomeScreen state logic
                    // For now, let's just make sure the user knows they can click it
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ),

        // Recent Transactions List
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: recentTransactions.maybeWhen(
            data: (transactions) => transactions.isEmpty
                ? SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.receipt,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start tracking your finances by adding your first transaction',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: TransactionListItem(
                            transaction: transactions[index],
                          ),
                        );
                      },
                      childCount: transactions.length > 10 ? 10 : transactions.length,
                    ),
                  ),
            orElse: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        
        // Bottom spacing
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}
