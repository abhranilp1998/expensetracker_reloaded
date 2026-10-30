import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Back during startup is ignored, app does not exit', (t) async {
    final calls = <MethodCall>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    await t.pumpWidget(
      MaterialApp(
        onGenerateRoute: (s) => s.name == '/'
            ? MaterialPageRoute<void>(builder: (_) => const BootstrapGate())
            : MaterialPageRoute<void>(builder: (_) => const SizedBox()),
      ),
    );
    final handled = await t.binding.handlePopRoute();
    await t.pump();
    expect(handled, isTrue);
    expect(calls.where((m) => m.method == 'SystemNavigator.pop'), isEmpty);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
