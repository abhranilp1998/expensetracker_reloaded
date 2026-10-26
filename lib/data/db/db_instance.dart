import 'app_database.dart';

/// One AppDatabase per isolate. The UI isolate and the background SMS isolate
/// each get their own instance pointed at the same file.
AppDatabase? _instance;
AppDatabase get appDatabase => _instance ??= AppDatabase();
