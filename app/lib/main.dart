import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/api_key_controller.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Apply a previously saved API key (if any) so the app is usable on launch
  // even when no key was provided at build time.
  final savedKey = prefs.getString(ApiKeyNotifier.prefsKey);
  if (savedKey != null && savedKey.isNotEmpty) {
    AppConfig.overrideApiKey = savedKey;
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyDogsApp(),
    ),
  );
}
