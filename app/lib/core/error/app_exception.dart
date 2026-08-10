/// Domain-friendly exception hierarchy for the MyDogs app.
///
/// All exceptions inherit from [AppException] so the UI can catch a single
/// type and present a user-friendly message with an optional retry action.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Human-readable message suitable for display in the UI.
  final String message;

  /// The underlying error that caused this exception, if any.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the API key is missing or invalid.
class MissingApiKeyException extends AppException {
  const MissingApiKeyException()
      : super(
          'No API key configured. Launch the app with '
          '--dart-define=DOG_API_KEY=your-key.',
        );
}

/// Thrown when the API returns an authentication error (HTTP 401/403).
class ApiAuthException extends AppException {
  const ApiAuthException({super.cause})
      : super('Authentication failed. Check that your API key is valid.');
}

/// Thrown when the API rate-limits requests (HTTP 429).
class RateLimitException extends AppException {
  const RateLimitException({super.cause})
      : super('Too many requests. Please wait a moment and try again.');
}

/// Thrown when the API returns a server error (HTTP 5xx).
class ServerException extends AppException {
  const ServerException({super.cause})
      : super('The server is having issues. Please try again later.');
}

/// Thrown when a network connectivity error occurs.
class NetworkException extends AppException {
  const NetworkException({super.cause})
      : super('Network error. Check your connection and try again.');
}

/// Thrown when the API response is invalid or incomplete.
class InvalidResponseException extends AppException {
  const InvalidResponseException({super.cause})
      : super('Received an invalid response from the server.');
}

/// Thrown when an image download fails.
class ImageDownloadException extends AppException {
  const ImageDownloadException({super.cause})
      : super('Failed to download the image.');
}

/// Thrown when a local file or metadata operation fails.
class StorageException extends AppException {
  const StorageException({super.cause})
      : super('Failed to save or read local data.');
}