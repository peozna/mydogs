import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/dog_image.dart';
import 'dog_dto.dart';

abstract class DogApiRepository {
  Future<DogImage> getRandomDogWithBreed();
}

class DogApiRepositoryImpl implements DogApiRepository {
  DogApiRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<DogImage> getRandomDogWithBreed() async {
    const maxRetries = 3;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get<List<dynamic>>(
          '/images/search',
          queryParameters: {
            'limit': 1,
            'order': 'RANDOM',
            'has_breeds': true,
            'include_breeds': true,
          },
        );

        final data = response.data;
        if (data == null || data.isEmpty) {
          if (attempt == maxRetries) {
            throw const InvalidResponseException();
          }
          continue;
        }

        final firstItem = data.first;
        if (firstItem is! Map<String, dynamic>) {
          if (attempt == maxRetries) {
            throw const InvalidResponseException();
          }
          continue;
        }

        final dto = ImageDto.fromJson(firstItem);
        // Select the first usable item and require a non-empty url and at least one breed.
        if (dto.url.isNotEmpty &&
            dto.breeds != null &&
            dto.breeds!.isNotEmpty) {
          return dto.toDomain();
        }

        if (attempt == maxRetries) {
          throw const InvalidResponseException();
        }
      } on DioException catch (e) {
        final error = e.error;
        if (error is AppException) {
          // If it's a structural/auth error, propagate immediately.
          if (error is ApiAuthException || error is MissingApiKeyException) {
            throw error;
          }
        }
        if (attempt == maxRetries) {
          if (error is AppException) {
            throw error;
          }
          throw NetworkException(cause: e);
        }
      } catch (e) {
        if (attempt == maxRetries) {
          if (e is AppException) {
            rethrow;
          }
          throw InvalidResponseException(cause: e);
        }
      }
    }

    throw const InvalidResponseException();
  }
}

final dogApiRepositoryProvider = Provider<DogApiRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DogApiRepositoryImpl(dio);
});
