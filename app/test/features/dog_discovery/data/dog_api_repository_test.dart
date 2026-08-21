import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydogs/core/error/app_exception.dart';
import 'package:mydogs/features/dog_discovery/data/dog_api_repository.dart';
import 'package:mydogs/features/dog_discovery/data/dog_dto.dart';

class MockAdapter implements HttpClientAdapter {
  MockAdapter();

  Future<ResponseBody> Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    throw UnimplementedError();
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Dog DTO Parsing Tests', () {
    test('ImageDto with ProBreedDto parses correctly to domain', () {
      final json = {
        'id': 'abc123',
        'url': 'https://example.com/dog.jpg',
        'width': 640,
        'height': 480,
        'breeds': [
          {
            'id': '115',
            'name': 'German Shepherd',
            'life_span': '9-13',
            'temperament': 'Loyal, Intelligent',
            'origin': 'Germany',
            'description': 'Noble working dog',
            'breed_group': 'Herding',
            'bred_for': 'Herding sheep',
            'height': {'imperial': '22-26', 'metric': '56-66'},
            'weight': {'imperial': '50-90', 'metric': '23-41'},
          },
        ],
      };

      final dto = ImageDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.id, 'abc123');
      expect(domain.url, 'https://example.com/dog.jpg');
      expect(domain.width, 640);
      expect(domain.height, 480);
      expect(domain.breeds.length, 1);

      final breed = domain.breeds.first;
      expect(breed.id, '115');
      expect(breed.name, 'German Shepherd');
      expect(breed.lifeSpan, '9-13');
      expect(breed.temperament, 'Loyal, Intelligent');
      expect(breed.origin, 'Germany');
      expect(breed.description, 'Noble working dog');
      expect(breed.breedGroup, 'Herding');
      expect(breed.bredFor, 'Herding sheep');
      expect(breed.heightImperial, '22-26');
      expect(breed.heightMetric, '56-66');
      expect(breed.weightImperial, '50-90');
      expect(breed.weightMetric, '23-41');
    });

    test('DTO parsing tolerates missing optional fields gracefully', () {
      final json = {
        'id': 'abc123',
        'url': 'https://example.com/dog.jpg',
        'width': 640,
        'height': 480,
        'breeds': [
          {
            'id': '115',
            'name': 'German Shepherd',
            // Missing all other optional fields
          },
        ],
      };

      final dto = ImageDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.breeds.first.id, '115');
      expect(domain.breeds.first.name, 'German Shepherd');
      expect(domain.breeds.first.lifeSpan, null);
      expect(domain.breeds.first.temperament, null);
      expect(domain.breeds.first.heightImperial, null);
    });
  });

  group('DogApiRepository Unit Tests', () {
    late Dio dio;
    late MockAdapter mockAdapter;
    late DogApiRepositoryImpl repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.thedogapi.com/v1'));
      mockAdapter = MockAdapter();
      dio.httpClientAdapter = mockAdapter;
      repository = DogApiRepositoryImpl(dio);
    });

    ResponseBody createJsonResponse(dynamic data, {int status = 200}) {
      final jsonString = jsonEncode(data);
      return ResponseBody.fromString(
        jsonString,
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    test('getRandomDogWithBreed succeeds on first attempt', () async {
      final responseData = [
        {
          'id': 'abc123',
          'url': 'https://example.com/dog.jpg',
          'width': 640,
          'height': 480,
          'breeds': [
            {'id': '115', 'name': 'German Shepherd'},
          ],
        },
      ];

      mockAdapter.handler = (options) async {
        expect(options.path, '/images/search');
        expect(options.queryParameters['limit'], 1);
        expect(options.queryParameters['has_breeds'], true);
        expect(options.queryParameters['include_breeds'], true);
        return createJsonResponse(responseData);
      };

      final result = await repository.getRandomDogWithBreed();
      expect(result.id, 'abc123');
      expect(result.breeds.first.name, 'German Shepherd');
    });

    test(
      'getRandomDogWithBreed retries on unusable response and eventually succeeds',
      () async {
        int callCount = 0;
        final emptyBreedResponse = [
          {
            'id': 'no_breed',
            'url': 'https://example.com/no_breed.jpg',
            'width': 640,
            'height': 480,
            'breeds': [], // Invalid, has no breeds
          },
        ];
        final validResponse = [
          {
            'id': 'valid_dog',
            'url': 'https://example.com/valid.jpg',
            'width': 640,
            'height': 480,
            'breeds': [
              {'id': '1', 'name': 'Golden Retriever'},
            ],
          },
        ];

        mockAdapter.handler = (options) async {
          callCount++;
          if (callCount == 1) {
            return createJsonResponse(emptyBreedResponse);
          } else {
            return createJsonResponse(validResponse);
          }
        };

        final result = await repository.getRandomDogWithBreed();
        expect(callCount, 2);
        expect(result.id, 'valid_dog');
        expect(result.breeds.first.name, 'Golden Retriever');
      },
    );

    test(
      'getRandomDogWithBreed throws InvalidResponseException if all retries return unusable response',
      () async {
        final emptyBreedResponse = [
          {
            'id': 'no_breed',
            'url': 'https://example.com/no_breed.jpg',
            'width': 640,
            'height': 480,
            'breeds': [],
          },
        ];

        int callCount = 0;
        mockAdapter.handler = (options) async {
          callCount++;
          return createJsonResponse(emptyBreedResponse);
        };

        await expectLater(
          () => repository.getRandomDogWithBreed(),
          throwsA(
            isA<InvalidResponseException>().having(
              (e) => e.details,
              'details',
              contains('Image had no breed information'),
            ),
          ),
        );
        expect(callCount, 4);
      },
    );

    test(
      'getRandomDogWithBreed throws ApiAuthException on 401 immediately without retrying',
      () async {
        int callCount = 0;
        mockAdapter.handler = (options) async {
          callCount++;
          // We simulate a DioError with 401 response status
          throw DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 401),
            error: const ApiAuthException(),
          );
        };

        await expectLater(
          () => repository.getRandomDogWithBreed(),
          throwsA(isA<ApiAuthException>()),
        );
        expect(callCount, 1); // No retries
      },
    );

    test('getRandomDogWithBreed throws RateLimitException on 429', () async {
      mockAdapter.handler = (options) async {
        throw DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 429),
          error: const RateLimitException(),
        );
      };

      await expectLater(
        () => repository.getRandomDogWithBreed(),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('getRandomDogWithBreed throws ServerException on 500', () async {
      mockAdapter.handler = (options) async {
        throw DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 500),
          error: const ServerException(),
        );
      };

      await expectLater(
        () => repository.getRandomDogWithBreed(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
