import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydogs/core/config/app_config.dart';
import 'package:mydogs/core/error/app_exception.dart';
import 'package:mydogs/features/dog_discovery/data/dog_api_repository.dart';
import 'package:mydogs/features/dog_discovery/domain/breed.dart';
import 'package:mydogs/features/dog_discovery/domain/dog_image.dart';
import 'package:mydogs/features/dog_discovery/presentation/dog_discovery_controller.dart';
import 'package:mydogs/features/dog_discovery/presentation/dog_discovery_page.dart';

class FakeDogApiRepository implements DogApiRepository {
  FakeDogApiRepository({
    this.onGetRandomDogWithBreed,
  });

  Future<DogImage> Function()? onGetRandomDogWithBreed;

  @override
  Future<DogImage> getRandomDogWithBreed() async {
    if (onGetRandomDogWithBreed != null) {
      return onGetRandomDogWithBreed!();
    }
    throw UnimplementedError();
  }
}

void main() {
  setUp(() {
    AppConfig.overrideApiKey = 'dummy-key';
  });

  tearDown(() {
    AppConfig.overrideApiKey = null;
  });

  group('DogDiscoveryController Unit Tests', () {
    test('initial state is AsyncLoading, then transitions to AsyncData on success', () async {
      final dogImage = DogImage(
        id: '123',
        url: 'https://example.com/dog.jpg',
        width: 100,
        height: 100,
        breeds: [
          const Breed(id: '1', name: 'German Shepherd'),
        ],
      );

      final fakeRepository = FakeDogApiRepository(
        onGetRandomDogWithBreed: () async => dogImage,
      );

      final container = ProviderContainer(
        overrides: [
          dogApiRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      // Verify that the initial build returns a future that resolves to dogImage
      expect(container.read(dogDiscoveryControllerProvider), const AsyncLoading<DogImage>());

      final result = await container.read(dogDiscoveryControllerProvider.future);
      expect(result, dogImage);
      expect(container.read(dogDiscoveryControllerProvider).value, dogImage);
    });

    test('transitions to AsyncError when repository throws AppException', () async {
      final fakeRepository = FakeDogApiRepository(
        onGetRandomDogWithBreed: () async => throw const ApiAuthException(),
      );

      final container = ProviderContainer(
        overrides: [
          dogApiRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(dogDiscoveryControllerProvider), const AsyncLoading<DogImage>());

      try {
        await container.read(dogDiscoveryControllerProvider.future);
        fail('Should have thrown an error');
      } catch (e) {
        expect(e, isA<ApiAuthException>());
      }

      expect(container.read(dogDiscoveryControllerProvider).hasError, true);
      expect(container.read(dogDiscoveryControllerProvider).error, isA<ApiAuthException>());
    });
  });

  group('DogDiscoveryPage Widget Tests', () {
    testWidgets('shows ConfigurationError when no API key configured', (tester) async {
      AppConfig.overrideApiKey = null;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DogDiscoveryPage(),
          ),
        ),
      );

      expect(find.text('API Key Required'), findsOneWidget);
    });

    testWidgets('shows loading state during fetch', (tester) async {
      final completer = Completer<DogImage>();
      final fakeRepository = FakeDogApiRepository(
        onGetRandomDogWithBreed: () => completer.future,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dogApiRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: const MaterialApp(
            home: DogDiscoveryPage(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching a cute dog...'), findsOneWidget);
    });

    testWidgets('shows success state with breed info when fetch succeeds', (tester) async {
      final dogImage = DogImage(
        id: '123',
        url: 'https://example.com/dog.jpg',
        width: 100,
        height: 100,
        breeds: [
          const Breed(
            id: '1',
            name: 'German Shepherd',
            breedGroup: 'Herding',
            description: 'Intelligent working dog.',
            temperament: 'Loyal, Obedient',
            lifeSpan: '10-13 years',
            origin: 'Germany',
          ),
        ],
      );

      final fakeRepository = FakeDogApiRepository(
        onGetRandomDogWithBreed: () async => dogImage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dogApiRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: const MaterialApp(
            home: DogDiscoveryPage(),
          ),
        ),
      );

      // Wait for build future and state transition
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('German Shepherd'), findsOneWidget);
      expect(find.text('Herding'), findsOneWidget);
      expect(find.text('Intelligent working dog.'), findsOneWidget);
      expect(find.text('Loyal, Obedient'), findsOneWidget);
      expect(find.text('10-13 years'), findsOneWidget);
      expect(find.text('Germany'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows error state and retries when fetch fails', (tester) async {
      int callCount = 0;
      final dogImage = DogImage(
        id: '123',
        url: 'https://example.com/dog.jpg',
        width: 100,
        height: 100,
        breeds: [
          const Breed(id: '1', name: 'German Shepherd'),
        ],
      );

      final fakeRepository = FakeDogApiRepository(
        onGetRandomDogWithBreed: () async {
          callCount++;
          if (callCount == 1) {
            throw const NetworkException();
          }
          return dogImage;
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dogApiRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: const MaterialApp(
            home: DogDiscoveryPage(),
          ),
        ),
      );

      // Initial frame triggers build which throws error
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error Occurred'), findsOneWidget);
      expect(find.text('Network error. Check your connection and try again.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      // Tap Retry
      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should now show success state
      expect(find.text('German Shepherd'), findsOneWidget);
      expect(callCount, 2);
    });
  });
}
