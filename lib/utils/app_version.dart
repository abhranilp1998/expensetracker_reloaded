import 'package:package_info_plus/package_info_plus.dart';

/// "versionName (build versionCode)" read from the installed package, e.g.
/// "1.0.1 (build 2002)" for the arm64 split APK (Flutter adds 2000 per ABI).
Future<String> appVersionLabel() async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (build ${info.buildNumber})';
}
