import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../prefs/app_prefs.dart';
import 'service_locator.dart';

final appDatabaseProvider = Provider<AppDatabase>((_) => getIt<AppDatabase>());
final appPrefsProvider = Provider<AppPrefs>((_) => getIt<AppPrefs>());
