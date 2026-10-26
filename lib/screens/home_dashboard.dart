import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/widgets/add_transaction_sheet.dart';
import 'package:expensetracker_reloaded/services/sms_service.dart';
import 'package:expensetracker_reloaded/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:expensetracker_reloaded/routes/app_routes.dart' show createRoute, AppRoutes;
import 'dart:async';
import 'package:expensetracker_reloaded/widgets/action_card.dart';
import 'package:expensetracker_reloaded/widgets/transaction_tile.dart';
import 'package:expensetracker_reloaded/widgets/summary_row.dart';
import 'package:expensetracker_reloaded/screens/today_total_detail_page.dart';
import 'package:expensetracker_reloaded/widgets/app_drawer.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _hasPermission = false;
  late AnimationController _totalAnimController;
  late Animation<double> _totalScaleAnim;

  @override
  void initState() {
    super.initState();
    _totalAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _totalScaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _totalAnimController, curve: Curves.elasticOut),
    );
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _totalAnimController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    WidgetsBinding.instance.addObserver(this);
    await _requestPermissions();
    if (_hasPermission) _listenForSMS();
  }

  Future<void> _requestPermissions() async {
    await PermissionService.requestAll();
    final smsStatus = await Permission.sms.status;
    
    setState(() {
      _hasPermission = smsStatus.isGranted;
    });
    
    // Log the permission request result
    if (_hasPermission) {
      debugPrint('✅ SMS Permission GRANTED');
    } else if (smsStatus.isPermanentlyDenied) {
      debugPrint('❌ SMS Permission PERMANENTLY DENIED');
    } else {
      debugPrint('❌ SMS Permission DENIED');
    }
  }

  void _listenForSMS() {
    // Single process-wide listener; inserts go to SQLite (UI rewired in P6).
    unawaited(SmsService.start());
    unawaited(SmsService.importInboxOnce());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(currentDayProvider);
      _checkAndUpdatePermissions();
    }
  }

  Future<void> _checkAndUpdatePermissions() async {
    final status = await Permission.sms.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (_hasPermission) _listenForSMS();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(todaySummaryProvider);
    final week = ref.watch(weekSummaryProvider);
    final month = ref.watch(monthSummaryProvider);
    final todayTotal = summary.spent;
    final pendingReview = ref.watch(reviewQueueProvider).value?.length ?? 0;
    final transactions = (ref.watch(todayTransactionsProvider).value ?? const [])
        .reversed
        .map(txnToMap)
        .toList();
    ref.listen(todaySummaryProvider, (prev, next) {
      if (prev != null && next.count > prev.count) {
        _totalAnimController.forward(from: 0);
      }
    });
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Row(
          children: [
            Hero(
              tag: 'app-logo',
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF121212) 
                    : Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Expense Tracker',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ) ?? const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.fireplace_outlined),
            tooltip: 'Animation Showcase',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.animationShowcase);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Total Card with Hero animation
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(createRoute(
                      TodayTotalDetailPage(total: todayTotal),
                    ));
                  },
                  child: Hero(
                    tag: 'today-total-card',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Today's Total",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Live',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ScaleTransition(
                              scale: _totalScaleAnim,
                              child: Text(
                                '₹${todayTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Income ₹${summary.income.toStringAsFixed(2)}  ·  Net ${summary.netMinor < 0 ? '-' : '+'}₹${summary.net.abs().toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${transactions.length} transactions',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: ActionCard(
                        icon: Icons.add_circle_outline,
                        label: 'Add Expense',
                        color: Colors.blue,
                        onTap: _addTransaction,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionCard(
                        icon: Icons.history,
                        label: 'History',
                        color: Colors.purple,
                        onTap: () => Navigator.of(context).pushNamed('/history'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionCard(
                        icon: Icons.settings,
                        label: 'Settings',
                        color: Colors.orange,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.comprehensiveSettings),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                if (pendingReview > 0) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.rule, color: Colors.deepOrange),
                      title: Text(
                        '$pendingReview SMS need${pendingReview == 1 ? 's' : ''} review',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      subtitle: const Text(
                        'Tap Expense, Income or Ignore. Not counted until you decide.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                      onTap: () => Navigator.of(context).pushNamed('/review'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed('/history'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length > 5 ? 5 : transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[transactions.length - 1 - index];
                      return TransactionTile(
                        transaction: t,
                        index: index,
                      );
                    },
                  ),

                const SizedBox(height: 32),

                // Summary Card
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SummaryRow(
                        label: 'Today',
                        amount: todayTotal,
                        icon: Icons.today,
                        color: Colors.green,
                      ),
                      const Divider(height: 24),
                      SummaryRow(
                        label: 'This Week',
                        amount: week.spent,
                        icon: Icons.calendar_view_week,
                        color: Colors.blue,
                      ),
                      const Divider(height: 24),
                      SummaryRow(
                        label: 'This Month',
                        amount: month.spent,
                        icon: Icons.calendar_month,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addTransaction() async {
    final entry = await showAddTransactionSheet(context);
    if (entry == null || !mounted) return;
    await ref.read(transactionRepositoryProvider).addManual(
          amount: entry.amount,
          type: entry.type,
          note: entry.note,
        );
    if (mounted) unawaited(_totalAnimController.forward(from: 0));
  }
}
