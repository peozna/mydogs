import 'app_exception.dart';

/// Formats errors into consistent, user-friendly messages.
///
/// [AppException] messages are shown as-is. For any other error type a
/// generic fallback is returned so the UI never leaks raw stack traces or
/// implementation details to the user.
String formatErrorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return 'An unexpected error occurred. Please try again.';
}
