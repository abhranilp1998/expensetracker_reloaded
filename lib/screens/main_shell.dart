import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/routes/predictive_back.dart';
import 'package:expensetracker_reloaded/screens/comprehensive_settings_page.dart';
import 'package:expensetracker_reloaded/screens/history_page.dart';
import 'package:expensetracker_reloaded/screens/home_dashboard.dart';
import 'package:expensetracker_reloaded/screens/review_queue_page.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';
import 'package:expensetracker_reloaded/services/notification_service.dart';

/// Bottom tabs: Home, Activity, Review, Settings. Side drawer lives on each tab.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.pagesOverride});

  /// Home is always index 0 and is where every launch lands
  /// (unless the app was opened from a "tap to review" notification).
  static const int homeIndex = 0;
  static const int reviewIndex = 2;

  /// Test hook: replaces the four tab bodies.
  @visibleForTesting
  final List<Widget>? pagesOverride;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Back-swipe progress for the shell itself (0 = idle, 1 = fully pulled).
  /// Drives the tab -> Home peek and the Home "leaving" peek.
  late final AnimationController _peek = AnimationController(vsync: this);

  /// Tab the current swipe started on; null when no swipe is running.
  int? _swipeTab;
  late final Animation<double> _tabPeek = ReverseAnimation(_peek);
  late final Animation<double> _homePeek = Tween<double>(
    begin: 1,
    end: 0.5,
  ).animate(_peek);

  /// Keeps each tab's state while it moves between onstage and offstage.
  final List<GlobalKey> _tabKeys = List.generate(
    4,
    (i) => GlobalKey(debugLabel: 'tab-$i'),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.pendingPayload.addListener(_onNotificationTap);
    // Cold start: the payload was stored before this widget existed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNotificationTap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _peek.dispose();
    NotificationService.pendingPayload.removeListener(_onNotificationTap);
    super.dispose();
  }

  /// Routes a tapped notification: "tap to review" opens the Review tab,
  /// closing any pages stacked above the shell.
  void _onNotificationTap() {
    if (!mounted) return;
    final payload = NotificationService.pendingPayload.value;
    if (payload != NotificationService.reviewPayload) return;
    NotificationService.pendingPayload.value = null;
    final shellRoute = ModalRoute.of(context);
    if (shellRoute != null) {
      Navigator.of(context).popUntil((r) => r == shellRoute);
    }
    ref.read(shellTabProvider.notifier).select(MainShell.reviewIndex);
  }

  // ---- Predictive back for the shell (Android 14+) -------------------------
  // The tabs live in one route, so the Navigator has nothing to animate. The
  // shell listens to the system swipe itself:
  //  * on Activity/Review/Settings the tab shrinks and Home shows behind it;
  //    letting go early springs back, a full pull lands on Home.
  //  * on Home the page shrinks like the system back-to-home preview; a full
  //    pull asks "Leaving already?" (Stay / Quit).
  // Without a swipe (Back button, Android 13, reduce motion) the PopScope
  // below handles Back the same way, just without the peek.

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent || reduceMotion(context)) {
      return false;
    }
    setState(() {
      _swipeTab = ref.read(shellTabProvider);
    });
    _peek.value = backEvent.progress;
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (_swipeTab != null) _peek.value = backEvent.progress;
  }

  @override
  void handleCancelBackGesture() {
    if (_swipeTab == null) return;
    _peek
        .animateBack(0, duration: const Duration(milliseconds: 200))
        .whenComplete(() {
          if (mounted) setState(() => _swipeTab = null);
        });
  }

  @override
  void handleCommitBackGesture() {
    final tab = _swipeTab;
    if (tab == null) return;
    if (tab != MainShell.homeIndex) {
      _peek
          .animateTo(1, duration: const Duration(milliseconds: 180))
          .whenComplete(() {
            if (!mounted) return;
            ref.read(shellTabProvider.notifier).select(MainShell.homeIndex);
            _peek.value = 0;
            setState(() => _swipeTab = null);
          });
      return;
    }
    _peek
        .animateBack(0, duration: const Duration(milliseconds: 200))
        .whenComplete(() async {
          if (!mounted) return;
          setState(() => _swipeTab = null);
          if (await confirmLeaveApp(context)) {
            await SystemNavigator.pop();
          }
        });
  }

  /// The four tab bodies stacked; only the current one is onstage, plus Home
  /// underneath while a tab is being swiped back.
  Widget _tabStack(List<Widget> pages, int index) {
    final swipe = _swipeTab;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < pages.length; i++)
          Offstage(
            offstage:
                !(i == index || (swipe != null && i == MainShell.homeIndex)),
            child: TickerMode(
              enabled: i == index,
              child: Builder(
                builder: (context) {
                  final page = KeyedSubtree(key: _tabKeys[i], child: pages[i]);
                  final moving = swipe != null && i == index;
                  // The user's selected animation style, played in reverse
                  // as the finger pulls (Home only goes halfway: a peek).
                  final anim = !moving
                      ? kAlwaysCompleteAnimation
                      : i == MainShell.homeIndex
                      ? _homePeek
                      : _tabPeek;
                  return buildMotion(
                    AnimationVariants.currentType,
                    anim,
                    kAlwaysDismissedAnimation,
                    page,
                    // Finger-driven: linear, no overshoot.
                    gesture: () => true,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(reviewQueueProvider).value?.length ?? 0;
    final index = ref.watch(shellTabProvider);
    final tabs = ref.read(shellTabProvider.notifier);

    // Back (bug #7): on Activity/Review/Settings go to Home; on Home let the
    // system handle it (leave the app).
    // Back on Home asks before leaving (Stay is the default).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (index != MainShell.homeIndex) {
          tabs.select(MainShell.homeIndex);
          return;
        }
        if (await confirmLeaveApp(context)) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: _tabStack(
          widget.pagesOverride ??
              const [
                HomeDashboard(),
                HistoryPage(asTab: true),
                ReviewQueuePage(asTab: true),
                ComprehensiveSettingsPage(asTab: true),
              ],
          index,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            Haptics.tap();
            tabs.select(i);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pending > 0,
                label: Text(pending > 99 ? '99+' : '$pending'),
                child: const Icon(Icons.rule_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pending > 0,
                label: Text(pending > 99 ? '99+' : '$pending'),
                child: const Icon(Icons.rule),
              ),
              label: 'Review',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks "Leaving already?" on Back from Home. Returns true only for Quit;
/// dismissing the dialog or tapping Stay keeps the app open.
Future<bool> confirmLeaveApp(BuildContext context) async {
  final quit = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Leaving already?'),
      content: const Text('More insights await.'),
      actions: [
        TextButton(
          key: const Key('leave-quit'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Quit'),
        ),
        FilledButton(
          key: const Key('leave-stay'),
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Stay'),
        ),
      ],
    ),
  );
  return quit ?? false;
}
