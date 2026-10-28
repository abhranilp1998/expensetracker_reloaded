import 'package:expensetracker_reloaded/screens/comprehensive_settings_page.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'package:expensetracker_reloaded/utils/app_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// About -> App Version comes from the package, not a hard-coded string.
void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Ledgerly',
      packageName: 'com.abhranil.ledgerly',
      version: '1.0.1',
      buildNumber: '2002',
      buildSignature: '',
    );
  });

  test('label is "versionName (build versionCode)"', () async {
    expect(await appVersionLabel(), '1.0.1 (build 2002)');
  });

  testWidgets('Settings About shows the package version', (t) async {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 1);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    SharedPreferences.setMockInitialValues({});
    await ThemeService.initialize();
    t.view.physicalSize = const Size(800, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ComprehensiveSettingsPage()),
      ),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('App Version'));
    expect(find.text('1.0.1 (build 2002)'), findsOneWidget);
    expect(find.text('1.0.0'), findsNothing);
  });
}
