import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Route _createRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(0.0, 0.1), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOut));
      return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: animation.drive(tween), child: child));
    },
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Hero(
                tag: 'app-logo',
                flightShuttleBuilder: (flightContext, animation, flightDirection, fromContext, toContext) {
                  // Use the source hero's child during the flight and scale it
                  final Hero hero = (flightDirection == HeroFlightDirection.push
                      ? fromContext.widget as Hero
                      : toContext.widget as Hero);
                  return ScaleTransition(
                    scale: animation.drive(Tween(begin: 0.85, end: 1.0).chain(CurveTween(curve: Curves.easeOut))),
                    child: hero.child,
                  );
                },
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.green.shade600,
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      size: 56, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to ExpenseTracker',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Automatically track expenses from SMS, view daily summaries, and manage your history.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacement(_createRoute(const HomeDashboard()));
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Get Started'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                child: const Text('Skip for now'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with WidgetsBindingObserver {
  final Telephony telephony = Telephony.instance;
  double todayTotal = 0.0;
  List<Map<String, dynamic>> transactions = [];
  Timer? _midnightTimer;
  bool _hasPermission = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    WidgetsBinding.instance.addObserver(this);
    _prefs = await SharedPreferences.getInstance();
    todayTotal = _prefs?.getDouble('todayTotal') ?? 0.0;

    // Load saved transactions
    final savedTransactions = _prefs?.getStringList('transactions') ?? [];
    setState(() {
      transactions = savedTransactions
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    });

    await _requestPermissions();
    _setupMidnightReset();
    if (_hasPermission) _listenForSMS();
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'expense_tracker',
      'Expense Notifications',
      channelDescription: 'Notifications for expense tracking',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  void _setupMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      setState(() {
        todayTotal = 0.0;
        transactions.clear();
        _prefs?.setDouble('todayTotal', 0.0);
        _showNotification('Daily Reset',
            'Your expense tracking has been reset for the new day.');
        _setupMidnightReset();
      });
    });
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.sms.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  void _listenForSMS() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        if (message.body != null) _parseMessage(message.body!);
      },
    );
  }

  void _parseMessage(String text) {
    try {
      final regex = RegExp(r'(?:rs\.?|inr)\s*([0-9,]+\.?[0-9]*)', caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        final amount = double.parse(match.group(1)!.replaceAll(',', ''));
        final now = DateTime.now();
        final transaction = {
          'amount': amount,
          'time': now.toIso8601String(),
          'message': text
        };

        setState(() {
          todayTotal += amount;
          transactions.add(Map<String, dynamic>.from(transaction));
        });

        // Save today's total
        _prefs?.setDouble('todayTotal', todayTotal);
        
        // Save transaction to history
        final List<String> savedTransactions = _prefs?.getStringList('transactions') ?? [];
        savedTransactions.add(jsonEncode(transaction));
        _prefs?.setStringList('transactions', savedTransactions);

        _showNotification('New Expense Detected',
            '₹${amount.toStringAsFixed(2)} spent — Daily: ₹${todayTotal.toStringAsFixed(2)}');
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Hero(
              tag: 'app-logo',
              child: CircleAvatar(
                  backgroundColor: Colors.green.shade600,
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white))),
          const SizedBox(width: 12),
          const Text('Expense Tracker'),
        ]),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Total",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Hero(
                              tag: 'today-total',
                              flightShuttleBuilder: (flightContext, animation, flightDirection, fromContext, toContext) {
                                final Hero hero = (flightDirection == HeroFlightDirection.push
                                    ? fromContext.widget as Hero
                                    : toContext.widget as Hero);
                                // combine scale and slight slide for the total text
                                return SlideTransition(
                                  position: animation.drive(Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                                      .chain(CurveTween(curve: Curves.easeOut))),
                                  child: ScaleTransition(
                                    scale: animation.drive(Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.easeOut))),
                                    child: hero.child,
                                  ),
                                );
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: Text('₹${todayTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pushNamed('/history'),
                          icon: const Icon(Icons.history),
                          label: const Text('History'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Shortcuts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ShortcutTile(
                        icon: Icons.add, label: 'Add Expense', onTap: _fakeAddExpense),
                    _ShortcutTile(icon: Icons.pie_chart, label: 'Summary', onTap: () {}),
                    _ShortcutTile(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () => Navigator.of(context).pushNamed('/settings')),
                  ],
                ),

                const SizedBox(height: 20),
                const Text('Recent Transactions',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[transactions.length - 1 - index];
                    return Card(
                      child: ListTile(
                        title: Text('₹${t['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(t['message'] ?? ''),
                        trailing: Text(DateFormat('hh:mm a').format(DateTime.parse(t['time'].toString()))),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text('Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Today'),
                              Text('₹${todayTotal.toStringAsFixed(2)}'),
                            ]),
                        const Divider(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('This week'),
                              Text('₹${_calculateTotal(DateTime.now().subtract(const Duration(days: 7))).toStringAsFixed(2)}'),
                            ]),
                        const Divider(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('This month'),
                              Text('₹${_calculateTotal(DateTime.now().subtract(const Duration(days: 30))).toStringAsFixed(2)}'),
                            ]),
                      ],
                    ),
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

  void _fakeAddExpense() {
    final now = DateTime.now();
        final transaction = {
          'amount': 50.0,
          'time': now.toIso8601String(),
          'message': 'Manual expense'
        };
    setState(() {
      transactions.add(Map<String, dynamic>.from(transaction));
      todayTotal += 50.0;
      _prefs?.setDouble('todayTotal', todayTotal);

      // Save transaction to history
      final List<String> savedTransactions = _prefs?.getStringList('transactions') ?? [];
      savedTransactions.add(jsonEncode(transaction));
      _prefs?.setStringList('transactions', savedTransactions);
    });
  }

  double _calculateTotal(DateTime since) {
    return transactions
        .where((t) {
          try {
            return DateTime.parse(t['time'].toString()).isAfter(since);
          } catch (e) {
            debugPrint('Error parsing date: ${t['time']}');
            return false;
          }
        })
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ShortcutTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icon, size: 28, color: Colors.green.shade700), const SizedBox(height: 8), Text(label)],
            ),
          ),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Abhranil Paul'),
              accountEmail: const Text('😁'),
              currentAccountPicture: Hero(tag: 'app-logo', child: const CircleAvatar(child: Icon(Icons.person))),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => Navigator.of(context).pushReplacementNamed('/home')),
            ListTile(leading: const Icon(Icons.history), title: const Text('History'), onTap: () => Navigator.of(context).pushNamed('/history')),
            ListTile(leading: const Icon(Icons.emoji_events), title: const Text('Medals'), onTap: () {}),
            ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () => Navigator.of(context).pushNamed('/profile')),
            ListTile(leading: const Icon(Icons.bug_report), title: const Text('Demo'), onTap: () => Navigator.of(context).pushNamed('/demo')),
            const Spacer(),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () => Navigator.of(context).pushNamed('/settings')),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<List<Map<String, dynamic>>> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? transactionJsonList = prefs.getStringList('transactions');
    if (transactionJsonList == null) return [];
    
    return transactionJsonList.map((json) => Map<String, dynamic>.from(jsonDecode(json))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No transaction history yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    '₹${t['amount'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy hh:mm a').format(DateTime.parse(t['time'].toString())),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (t['message'] != null)
                        Text(
                          t['message'],
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'app-logo',
              flightShuttleBuilder: (flightContext, animation, flightDirection, fromContext, toContext) {
                final Hero hero = (flightDirection == HeroFlightDirection.push
                    ? fromContext.widget as Hero
                    : toContext.widget as Hero);
                return ScaleTransition(
                  scale: animation.drive(Tween(begin: 0.9, end: 1.1).chain(CurveTween(curve: Curves.easeOut))),
                  child: hero.child,
                );
              },
              child: const CircleAvatar(radius: 64, child: Icon(Icons.person, size: 48)),
            ),
            const SizedBox(height: 16),
            const Text('User profile and settings.'),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('App settings go here.')),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo: Insert Sample Transactions')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Insert 5 sample transactions'),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final prefs = await SharedPreferences.getInstance();
            final now = DateTime.now();
            final samples = [
              {'amount': 120.5, 'time': now.toIso8601String(), 'message': 'Demo: Coffee'},
              {'amount': 550.0, 'time': now.subtract(const Duration(hours: 1)).toIso8601String(), 'message': 'Demo: Lunch'},
              {'amount': 79.0, 'time': now.subtract(const Duration(hours: 6)).toIso8601String(), 'message': 'Demo: Taxi'},
              {'amount': 320.0, 'time': now.subtract(const Duration(days: 1)).toIso8601String(), 'message': 'Demo: Groceries'},
              {'amount': 1500.0, 'time': now.subtract(const Duration(days: 7)).toIso8601String(), 'message': 'Demo: Rent (old)'}
            ];

            final List<String> saved = prefs.getStringList('transactions') ?? [];
            for (final t in samples) {
              saved.add(jsonEncode(t));
            }
            await prefs.setStringList('transactions', saved);

            // update today's total with only today's samples
            double todayTotal = prefs.getDouble('todayTotal') ?? 0.0;
            for (final t in samples) {
              final dt = DateTime.parse(t['time'].toString());
              if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
                todayTotal += (t['amount'] as num).toDouble();
              }
            }
            await prefs.setDouble('todayTotal', todayTotal);

            messenger.showSnackBar(const SnackBar(content: Text('Inserted sample transactions')));
            await Future.delayed(const Duration(milliseconds: 700));
            navigator.pushReplacementNamed('/home');
          },
        ),
      ),
    );
  }
}
