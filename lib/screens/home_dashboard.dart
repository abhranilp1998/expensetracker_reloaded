import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:expensetracker_reloaded/data/txn_view.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/screens/today_insights_page.dart';
import 'package:expensetracker_reloaded/services/sms_service.dart';
import 'package:expensetracker_reloaded/utils/constants.dart';
import 'package:expensetracker_reloaded/widgets/add_transaction_sheet.dart';
import 'package:expensetracker_reloaded/widgets/app_drawer.dart';
import 'package:expensetracker_reloaded/widgets/summary_row.dart';
import 'package:expensetracker_reloaded/widgets/transaction_tile.dart';
import 'package:expensetracker_reloaded/utils/money.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';

/// Home tab: today's spend hero, income/net, week/month stats, recent transactions.
class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with WidgetsBindingObserver, TickerProviderStateMixin {
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
    WidgetsBinding.instance.addObserver(this);
    _softStartSms();
  }

  Future<void> _softStartSms() async {
    // Do NOT call requestAll on every launch — permissions live in onboarding/Settings.
    if (await Permission.sms.isGranted) {
      unawaited(SmsService.start());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _totalAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(currentDayProvider);
      _softStartSms();
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    ref.watch(currencyProvider); // rebuild on currency change
    final summary = ref.watch(todaySummaryProvider);
    // Watched so a rename in Profile shows here at once (bug #5).
    final userName = ref.watch(userNameProvider).value ?? 'User';
    final week = ref.watch(weekSummaryProvider);
    final month = ref.watch(monthSummaryProvider);
    // Recent = newest 5 overall, not only today's (run4 bug).
    final transactions = ref
        .watch(recentTransactionsProvider)
        .map(txnToMap)
        .toList();
    ref.listen(todaySummaryProvider, (prev, next) {
      if (prev != null && next.count > prev.count) {
        _totalAnimController.forward(from: 0);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_greeting, $userName',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentDayProvider);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Clear the extended FAB (56 + margins) and the system inset.
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + 88 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(createRoute(const TodayInsightsPage()));
                },
                child: Hero(
                  tag: 'today-total-card',
                  flightShuttleBuilder: heroCardShuttle,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary,
                            cs.primary.withValues(alpha: 0.65),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
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
                              Text(
                                "Today's spend",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: cs.onPrimary.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.insights,
                                color: cs.onPrimary.withValues(alpha: 0.9),
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ScaleTransition(
                            scale: _totalScaleAnim,
                            child: Text(
                              Money.minor(summary.spentMinor),
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Income ${Money.minor(summary.incomeMinor)}  ·  '
                            'Net ${Money.minor(summary.netMinor, signed: true)}',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${plural(transactions.length, 'transaction')} · tap for insights',
                                style: TextStyle(
                                  color: cs.onPrimary.withValues(alpha: 0.75),
                                  fontSize: 13,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: cs.onPrimary.withValues(alpha: 0.75),
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'This week',
                      amountMinor: week.spentMinor,
                      icon: Icons.calendar_view_week,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'This month',
                      amountMinor: month.spentMinor,
                      icon: Icons.calendar_month,
                    ),
                  ),
                ],
              ),
              // Snapshot sits above Recent so the Add button never covers
              // "Net today" (bug #19).
              const SizedBox(height: 24),
              Text(
                'Balance snapshot',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SummaryRow(
                        label: 'Today spent',
                        amountMinor: summary.spentMinor,
                        icon: Icons.today,
                        color: cs.primary,
                      ),
                      const Divider(height: 24),
                      SummaryRow(
                        label: 'Today income',
                        amountMinor: summary.incomeMinor,
                        icon: Icons.south_west,
                        color: cs.tertiary,
                      ),
                      const Divider(height: 24),
                      SummaryRow(
                        label: 'Net today',
                        amountMinor: summary.netMinor,
                        signed: true,
                        icon: Icons.account_balance_wallet_outlined,
                        color: summary.netMinor < 0 ? cs.error : cs.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    // Switch to the Activity tab instead of pushing a second
                    // Activity page (bug #18).
                    onPressed: () =>
                        ref.read(shellTabProvider.notifier).select(1),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: cs.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) => TransactionTile(
                    transaction: transactions[index],
                    index: index,
                    showDate: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addTransaction() async {
    Haptics.tap();
    final entry = await showAddTransactionSheet(context);
    if (entry == null || !mounted) return;
    await ref
        .read(transactionRepositoryProvider)
        .addManual(
          amountMinor: entry.amountMinor,
          type: entry.type,
          note: entry.note,
        );
    if (mounted) unawaited(_totalAnimController.forward(from: 0));
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.amountMinor,
    required this.icon,
  });
  final String label;
  final int amountMinor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            Money.minor(amountMinor),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
