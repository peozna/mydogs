import 'package:flutter_test/flutter_test.dart';
import 'package:mydogs/core/error/app_exception.dart';
import 'package:mydogs/core/error/error_formatter.dart';

void main() {
  group('formatErrorMessage', () {
    test('returns the message for AppException types', () {
      expect(
        formatErrorMessage(const NetworkException()),
        'Network error. Check your connection and try again.',
      );
      expect(
        formatErrorMessage(const ApiAuthException()),
        'Authentication failed. Check that your API key is valid.',
      );
      expect(
        formatErrorMessage(const RateLimitException()),
        'Too many requests. Please wait a moment and try again.',
      );
      expect(
        formatErrorMessage(const ServerException()),
        'The server is having issues. Please try again later.',
      );
      expect(
        formatErrorMessage(const StorageException()),
        'Failed to save or read local data.',
      );
      expect(
        formatErrorMessage(const ImageDownloadException()),
        'Failed to download the image.',
      );
      expect(
        formatErrorMessage(const InvalidResponseException()),
        'Received an invalid response from the server.',
      );
      expect(
        formatErrorMessage(
          const InvalidResponseException(
            details: 'HTTP 400 — {"message":"Invalid API Key"}',
          ),
        ),
        'Received an invalid response from the server.\n\n'
        'HTTP 400 — {"message":"Invalid API Key"}',
      );
    });

    test('returns generic fallback for non-AppException errors', () {
      expect(
        formatErrorMessage(Exception('Something went wrong')),
        'An unexpected error occurred. Please try again.',
      );
      expect(
        formatErrorMessage(StateError('bad state')),
        'An unexpected error occurred. Please try again.',
      );
      expect(
        formatErrorMessage('plain string error'),
        'An unexpected error occurred. Please try again.',
      );
    });

    test('describeServerPayload serializes and truncates payloads', () {
      expect(describeServerPayload(null), 'null');
      expect(describeServerPayload('  '), '(empty)');
      expect(
        describeServerPayload({'message': 'Invalid API Key'}),
        '{"message":"Invalid API Key"}',
      );
      expect(
        describeServerPayload('x' * 10, maxLength: 4),
        'xxxx…',
      );
    });
  });
}
