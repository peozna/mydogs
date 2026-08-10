/// Centralized application configuration.
///
/// Reads the TheDogAPI key from `--dart-define=DOG_API_KEY=...` at build time.
/// The key is never committed to source control.
class AppConfig {
  static const _apiKey = String.fromEnvironment('DOG_API_KEY', defaultValue: '');

  /// The TheDogAPI base URL.
  static const baseUrl = 'https://api.thedogapi.com/v1';

  /// Returns `true` if an API key has been provided via `--dart-define`.
  static bool get hasApiKey => _apiKey.isNotEmpty;

  /// Returns the API key, or an empty string if not configured.
  ///
  /// Callers should check [hasApiKey] before using this value.
  static String get apiKey => _apiKey;
}