import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/screens/main_shell.dart';
import 'package:expensetracker_reloaded/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Codex 9/10: tapping a "tap to review" notification must open Review.
void main() {
  const pages = [
    Text('home-body'),
    Text('activity-body'),
    Text('review-body'),
    Text('settings-body'),
  ];

  Future<ProviderContainer> pumpShell(WidgetTester t) async {
    final container = ProviderContainer(
      overrides: [
        reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MainShell(pagesOverride: pages)),
      ),
    );
    await t.pumpAndSettle();
    return container;
  }

  tearDown(() => NotificationService.pendingPayload.value = null);

  testWidgets('tap while running switches to the Review tab', (t) async {
    final c = await pumpShell(t);
    expect(c.read(shellTabProvider), MainShell.homeIndex);
    NotificationService.handleResponse(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: NotificationService.reviewPayload,
      ),
    );
    await t.pumpAndSettle();
    expect(c.read(shellTabProvider), MainShell.reviewIndex);
    expect(NotificationService.pendingPayload.value, isNull);
  });

  testWidgets('cold start payload opens Review once the shell shows', (
    t,
  ) async {
    NotificationService.pendingPayload.value =
        NotificationService.reviewPayload;
    final c = await pumpShell(t);
    expect(c.read(shellTabProvider), MainShell.reviewIndex);
  });

  testWidgets('notifications without a payload do nothing', (t) async {
    final c = await pumpShell(t);
    NotificationService.handleResponse(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      ),
    );
    await t.pumpAndSettle();
    expect(c.read(shellTabProvider), MainShell.homeIndex);
  });
}
