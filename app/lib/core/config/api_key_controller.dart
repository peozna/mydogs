import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

/// Provides the [SharedPreferences] instance.
///
/// Must be overridden with a concrete instance in `main()` (and in tests that
/// exercise saving/clearing the key) — see [main].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  );
});

/// Holds the currently effective TheDogAPI key and persists user-entered keys.
///
/// Resolution order for the effective key:
/// 1. A key the user entered in the in-app settings screen (persisted).
/// 2. The compile-time `--dart-define=DOG_API_KEY` value, if any.
///
/// The persisted key is loaded in `main()` and applied to [AppConfig] before
/// the first build, so [build] simply mirrors the effective [AppConfig] value.
class ApiKeyNotifier extends Notifier<String?> {
  /// The [SharedPreferences] key under which the API key is stored.
  static const prefsKey = 'dog_api_key';

  @override
  String? build() => AppConfig.hasApiKey ? AppConfig.apiKey : null;

  /// Persists [key] and makes it the effective API key. Passing a blank value
  /// clears the stored key and falls back to the compile-time key (if any).
  Future<void> save(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(prefsKey, trimmed);
    AppConfig.overrideApiKey = trimmed;
    state = trimmed;
  }

  /// Removes any user-entered key, falling back to the compile-time key.
  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(prefsKey);
    AppConfig.overrideApiKey = null;
    state = AppConfig.apiKey.isNotEmpty ? AppConfig.apiKey : null;
  }
}

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String?>(
  ApiKeyNotifier.new,
);

/// `true` when an API key is available from any source.
final hasApiKeyProvider = Provider<bool>((ref) {
  final key = ref.watch(apiKeyProvider);
  return key != null && key.isNotEmpty;
});
