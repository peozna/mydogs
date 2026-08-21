import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../error/error_formatter.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (!AppConfig.hasApiKey) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: const MissingApiKeyException(),
            ),
          );
        }
        options.headers['x-api-key'] = AppConfig.apiKey;
        return handler.next(options);
      },
      onError: (error, handler) {
        final appException = _mapDioErrorToAppException(error);
        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: appException,
            message: appException.message,
          ),
        );
      },
    ),
  );

  return dio;
});

/// Dio instance used for downloading dog images from their CDN URLs.
///
/// This client deliberately does NOT attach the `x-api-key` header, because
/// image URLs point to a third-party CDN and leaking the key there would be
/// a security risk. Only HTTPS URLs are allowed.
final imageDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.uri.scheme != 'https') {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: const ImageDownloadException(
                cause: 'Only HTTPS image URLs are allowed.',
              ),
            ),
          );
        }
        return handler.next(options);
      },
    ),
  );

  return dio;
});

AppException _mapDioErrorToAppException(DioException error) {
  if (error.error is AppException) {
    return error.error as AppException;
  }

  final details = _dioErrorDetails(error);
  final response = error.response;
  if (response != null) {
    final status = response.statusCode;
    if (status == 401 || status == 403) {
      return ApiAuthException(cause: error, details: details);
    } else if (status == 429) {
      return RateLimitException(cause: error, details: details);
    } else if (status != null && status >= 500) {
      return ServerException(cause: error, details: details);
    }
    return InvalidResponseException(cause: error, details: details);
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError) {
    return NetworkException(cause: error, details: details);
  }

  return NetworkException(cause: error, details: details);
}

String _dioErrorDetails(DioException error) {
  final parts = <String>[];
  final status = error.response?.statusCode;
  if (status != null) {
    parts.add('HTTP $status');
  }
  if (error.type != DioExceptionType.unknown &&
      error.type != DioExceptionType.badResponse) {
    parts.add(error.type.name);
  }
  final payload = error.response?.data;
  if (payload != null) {
    parts.add(describeServerPayload(payload));
  } else if (error.message != null && error.message!.trim().isNotEmpty) {
    parts.add(error.message!.trim());
  }
  return parts.join(' — ');
}
