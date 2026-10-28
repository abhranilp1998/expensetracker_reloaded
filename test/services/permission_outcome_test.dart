import 'package:expensetracker_reloaded/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PermissionOutcome covers restricted-settings path', () {
    expect(PermissionOutcome.values, contains(PermissionOutcome.granted));
    expect(
      PermissionOutcome.values,
      contains(PermissionOutcome.needsRestrictedSettings),
    );
  });

  test('AppPermission maps to SMS + notifications only', () {
    expect(AppPermission.values.map((e) => e.name).toList(), [
      'sms',
      'notifications',
    ]);
  });
}
