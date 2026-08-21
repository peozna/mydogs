import 'dart:convert';

import 'app_exception.dart';

/// Formats errors into consistent, user-friendly messages.
///
/// [AppException] messages are shown as-is, with optional diagnostic
/// [AppException.details] appended so server failures can be debugged.
/// For any other error type a generic fallback is returned so the UI never
/// leaks raw stack traces or request headers (which may contain the API key).
String formatErrorMessage(Object error) {
  if (error is AppException) {
    final details = error.details?.trim();
    if (details != null && details.isNotEmpty) {
      return '${error.message}\n\n$details';
    }
    return error.message;
  }
  return 'An unexpected error occurred. Please try again.';
}

/// Returns a truncated, JSON-friendly description of a response payload.
///
/// Never include request headers here — they may contain the API key.
String describeServerPayload(Object? data, {int maxLength = 400}) {
  if (data == null) return 'null';

  String text;
  try {
    if (data is String) {
      text = data;
    } else if (data is Map || data is List) {
      text = jsonEncode(data);
    } else {
      text = data.toString();
    }
  } catch (_) {
    text = data.toString();
  }

  text = text.trim();
  if (text.isEmpty) return '(empty)';
  if (text.length > maxLength) {
    return '${text.substring(0, maxLength)}…';
  }
  return text;
}
