import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/db_instance.dart';
import '../data/repositories/transaction_repository.dart';
import '../domain/summary/summary.dart';
import '../services/theme_service.dart';

/// Overridable in tests.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final databaseProvider = Provider<AppDatabase>((_) => appDatabase);

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

final todayRangeProvider = Provider<DateRange>(
  (ref) => DateRange.day(_now(ref)),
);
final weekRangeProvider = Provider<DateRange>(
  (ref) => DateRange.week(_now(ref)),
);
final monthRangeProvider = Provider<DateRange>(
  (ref) => DateRange.month(_now(ref)),
);

final rangeTransactionsProvider =
    StreamProvider.family<List<TxnRow>, DateRange>(
      (ref, r) =>
          ref.watch(transactionRepositoryProvider).watchRange(r.start, r.end),
    );

final todayTransactionsProvider = Provider<AsyncValue<List<TxnRow>>>(
  (ref) => ref.watch(rangeTransactionsProvider(ref.watch(todayRangeProvider))),
);

final allTransactionsProvider = StreamProvider<List<TxnRow>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

Summary _sum(Ref ref, DateRange r) =>
    summarize(ref.watch(rangeTransactionsProvider(r)).value ?? const []);

final todaySummaryProvider = Provider<Summary>(
  (ref) => _sum(ref, ref.watch(todayRangeProvider)),
);
final weekSummaryProvider = Provider<Summary>(
  (ref) => _sum(ref, ref.watch(weekRangeProvider)),
);
final monthSummaryProvider = Provider<Summary>(
  (ref) => _sum(ref, ref.watch(monthRangeProvider)),
);
final allTimeSummaryProvider = Provider<Summary>(
  (ref) => summarize(ref.watch(allTransactionsProvider).value ?? const []),
);

class ThemeState {
  final ThemeMode mode;
  final MaterialColor accent;
  const ThemeState(this.mode, this.accent);
}

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

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);

final reviewQueueProvider = StreamProvider<List<TxnRow>>(
    (ref) => ref.watch(transactionRepositoryProvider).watchReviewQueue());

final learnedRulesProvider = StreamProvider<List<RuleRow>>(
    (ref) => ref.watch(transactionRepositoryProvider).watchRules());
