import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/notification_provider.dart';
import '../transactions/add_edit_transaction_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../categories/category_list_screen.dart';
import '../analytics/analytics_screen.dart';
import '../../widgets/budget/budget_alerts_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    await Future.wait([
      transactionProvider.refreshAll(),
      budgetProvider.fetchBudgets(refresh: true),
      notificationProvider.loadUnreadCount(), // Load notification count
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Welcome, ${user?.fullName ?? "User"}'),
      ),
      drawer: _buildDrawer(context, authProvider),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              _buildSummaryCards(context),
              const SizedBox(height: 24),

              // Budget Alerts
              const BudgetAlertsWidget(),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Recent Transactions
              Row(
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionListScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentTransactions(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiProvider(
                providers: [
                  ChangeNotifierProvider<CategoryProvider>.value(
                    value: context.read<CategoryProvider>(),
                  ),
                  ChangeNotifierProvider<TransactionProvider>.value(
                    value: context.read<TransactionProvider>(),
                  ),
                ],
                child: const AddEditTransactionScreen(),
              ),
            ),
          );
          if (result == true && mounted) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        return Column(
          children: [
            // Balance Card (Large)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Formatters.currency(transactionProvider.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${Formatters.dateTime(DateTime.now())}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Income & Expense Cards (Small)
            Row(
              children: [
                Expanded(
                  child: _buildSmallCard(
                    context: context,
                    title: 'Income',
                    amount: transactionProvider.totalIncome,
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSmallCard(
                    context: context,
                    title: 'Expense',
                    amount: transactionProvider.totalExpense,
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallCard({
    required BuildContext context,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(amount),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            label: 'Add Income',
            icon: Icons.add_circle_outline,
            color: AppColors.success,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider<CategoryProvider>.value(
                        value: context.read<CategoryProvider>(),
                      ),
                      ChangeNotifierProvider<TransactionProvider>.value(
                        value: context.read<TransactionProvider>(),
                      ),
                    ],
                    child: const AddEditTransactionScreen(
                      initialType: 'income',
                    ),
                  ),
                ),
              );
              if (result == true && mounted) {
                _loadData();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context: context,
            label: 'Add Expense',
            icon: Icons.remove_circle_outline,
            color: AppColors.danger,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider<CategoryProvider>.value(
                        value: context.read<CategoryProvider>(),
                      ),
                      ChangeNotifierProvider<TransactionProvider>.value(
                        value: context.read<TransactionProvider>(),
                      ),
                    ],
                    child: const AddEditTransactionScreen(
                      initialType: 'expense',
                    ),
                  ),
                ),
              );
              if (result == true && mounted) {
                _loadData();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final transactions = transactionProvider.transactions;

        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start adding your income and expenses',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length > 5 ? 5 : transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isIncome = transaction.isIncome;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isIncome ? AppColors.success : AppColors.danger)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome ? AppColors.success : AppColors.danger,
                  ),
                ),
                title: Text(
                  transaction.description ?? 'Transaction',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  '${transaction.categoryName ?? 'Uncategorized'} • ${Formatters.date(transaction.date)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                trailing: Text(
                  Formatters.currency(transaction.amount),
                  style: TextStyle(
                    color: isIncome ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/transactions/edit',
                    arguments: transaction,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            accountName: Text(
              user?.fullName ?? 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Budgets'),
            trailing: Consumer<BudgetProvider>(
              builder: (context, budgetProvider, child) {
                final alertCount = budgetProvider.alertBudgets.length;
                if (alertCount == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alertCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/budgets');
            },
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;
                if (unreadCount > 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
