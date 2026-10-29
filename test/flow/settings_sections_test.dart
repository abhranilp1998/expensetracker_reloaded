import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetracker_reloaded/screens/comprehensive_settings_page.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';

void main() {
  testWidgets('Settings has all sections and jump chips reach them',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.initialize();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: ComprehensiveSettingsPage(asTab: true)),
    ));
    await tester.pump(const Duration(seconds: 1));

    for (final chip in ['Appearance', 'SMS & Permissions', 'Learned rules', 'About']) {
      expect(find.widgetWithText(ActionChip, chip), findsOneWidget);
    }
    for (final title in ['SMS & Permissions', 'Learned rules', 'About']) {
      await tester.tap(find.widgetWithText(ActionChip, title));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(title, skipOffstage: true), findsWidgets);
    }
    expect(find.text('Manage learned rules'), findsOneWidget);
  });
}
