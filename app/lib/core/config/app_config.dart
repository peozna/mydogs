/// Centralized application configuration.
///
/// Reads the TheDogAPI key from `--dart-define=DOG_API_KEY=...` at build time.
/// The key is never committed to source control.
class AppConfig {
  static const _apiKey = String.fromEnvironment(
    'DOG_API_KEY',
    defaultValue: '',
  );

  static String? _overrideApiKey;

  /// Overrides the compile-time API key at runtime.
  ///
  /// Used both by the in-app settings screen (to apply a user-entered key) and
  /// by tests. Set to `null` to fall back to the compile-time key.
  static set overrideApiKey(String? value) => _overrideApiKey = value;

  /// The TheDogAPI base URL.
  static const baseUrl = 'https://api.thedogapi.com/v1';

  /// Returns `true` if an API key has been provided via `--dart-define` or overridden.
  static bool get hasApiKey => _overrideApiKey != null || _apiKey.isNotEmpty;

  /// Returns the API key, or an empty string if not configured.
  ///
  /// Callers should check [hasApiKey] before using this value.
  static String get apiKey => _overrideApiKey ?? _apiKey;
}
