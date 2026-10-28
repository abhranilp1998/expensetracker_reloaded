import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/db_instance.dart';
import '../data/repositories/transaction_repository.dart';
import '../domain/summary/summary.dart';
import '../services/theme_service.dart';
import '../services/user_prefs_service.dart';
import '../utils/money.dart';

/// Overridable in tests.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Singleton Drift [AppDatabase] (on-device SQLite).
final databaseProvider = Provider<AppDatabase>((_) => appDatabase);

/// Repository wrapping all transaction/rule reads and writes.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Emits "now" immediately and again at each local midnight.
/// Invalidate on app resume to re-sync after sleep. Replaces the old
/// midnight Timer that wiped state.
final currentDayProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  void schedule() {
    final now = clock();
    controller.add(now);
    final next = DateRange.day(now).end;
    timer = Timer(next.difference(now) + const Duration(seconds: 1), schedule);
  }

  schedule();
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});

DateTime _now(Ref ref) =>
    ref.watch(currentDayProvider).value ?? ref.watch(clockProvider)();

/// [DateRange] for today (local time).
final todayRangeProvider = Provider<DateRange>(
  (ref) => DateRange.day(_now(ref)),
);

/// [DateRange] for the current week.
final weekRangeProvider = Provider<DateRange>(
  (ref) => DateRange.week(_now(ref)),
);

/// [DateRange] for the current calendar month.
final monthRangeProvider = Provider<DateRange>(
  (ref) => DateRange.month(_now(ref)),
);

/// Live stream of transactions within a given [DateRange] (family).
final rangeTransactionsProvider =
    StreamProvider.family<List<TxnRow>, DateRange>(
      (ref, r) =>
          ref.watch(transactionRepositoryProvider).watchRange(r.start, r.end),
    );

/// Today's transactions, derived from [rangeTransactionsProvider].
final todayTransactionsProvider = Provider<AsyncValue<List<TxnRow>>>(
  (ref) => ref.watch(rangeTransactionsProvider(ref.watch(todayRangeProvider))),
);

/// Live stream of every stored transaction.
final allTransactionsProvider = StreamProvider<List<TxnRow>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

Summary _sum(Ref ref, DateRange r) =>
    summarize(ref.watch(rangeTransactionsProvider(r)).value ?? const []);

/// Debit/credit/net [Summary] for today (Home hero card).
final todaySummaryProvider = Provider<Summary>(
  (ref) => _sum(ref, ref.watch(todayRangeProvider)),
);

/// [Summary] for the current week.
final weekSummaryProvider = Provider<Summary>(
  (ref) => _sum(ref, ref.watch(weekRangeProvider)),
);

/// [Summary] for the current month.
final monthSummaryProvider = Provider<Summary>(
  (ref) => _sum(ref, ref.watch(monthRangeProvider)),
);

/// [Summary] across all transactions (Till Now).
final allTimeSummaryProvider = Provider<Summary>(
  (ref) => summarize(ref.watch(allTransactionsProvider).value ?? const []),
);

/// Immutable theme selection: mode + accent colour chosen by the user.
class ThemeState {
  final ThemeMode mode;
  final MaterialColor accent;
  const ThemeState(this.mode, this.accent);
}

/// Loads/persists the user theme and accent; the whole app theme derives from this.
class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() => ThemeState(
    ThemeService.getCurrentTheme(),
    ThemeService.getCurrentAccentColor(),
  );

  Future<void> setTheme(ThemeMode mode) async {
    state = ThemeState(mode, state.accent);
    await ThemeService.setTheme(mode);
  }

  Future<void> setAccentColor(MaterialColor color) async {
    state = ThemeState(state.mode, color);
    final name = ThemeService.availableColors.keys.firstWhere(
      (k) => ThemeService.availableColors[k] == color,
      orElse: () => 'green',
    );
    await ThemeService.setAccentColor(name);
  }
}

/// Exposes [ThemeController]/[ThemeState] to MaterialApp and settings.
final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);

/// Active currency code (bug #4). Every money label goes through [Money],
/// which reads [Money.code]; screens `ref.watch(currencyProvider)` so they
/// rebuild when it changes.
class CurrencyController extends Notifier<String> {
  @override
  String build() => Money.code;

  Future<void> set(String code) async {
    Money.code = code;
    state = code;
    await UserPrefsService.setCurrency(code);
  }
}

final currencyProvider = NotifierProvider<CurrencyController, String>(
  CurrencyController.new,
);

/// Display name, shared by Home greeting, drawer and Profile (bug #5).
class UserNameController extends AsyncNotifier<String> {
  @override
  Future<String> build() => UserPrefsService.getUserName();

  Future<void> set(String name) async {
    await UserPrefsService.setUserName(name);
    state = AsyncData(await UserPrefsService.getUserName());
  }
}

final userNameProvider = AsyncNotifierProvider<UserNameController, String>(
  UserNameController.new,
);

/// Uncertain SMS-derived transactions awaiting user review.
final reviewQueueProvider = StreamProvider<List<TxnRow>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchReviewQueue(),
);

/// Sender/pattern rules learned from user review decisions.
final learnedRulesProvider = StreamProvider<List<RuleRow>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchRules(),
);
