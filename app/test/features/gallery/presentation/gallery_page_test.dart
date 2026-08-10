import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydogs/features/dog_discovery/domain/breed.dart';
import 'package:mydogs/features/gallery/data/gallery_repository.dart';
import 'package:mydogs/features/gallery/domain/saved_dog.dart';
import 'package:mydogs/features/gallery/presentation/gallery_page.dart';
import 'package:mydogs/features/gallery/presentation/saved_dog_detail_page.dart';

class FakeGalleryRepository implements GalleryRepository {
  FakeGalleryRepository({
    List<SavedDog>? initialDogs,
  }) : dogs = initialDogs ?? [];

  final List<SavedDog> dogs;
  final List<String> deletedIds = [];

  @override
  Future<List<SavedDog>> getSavedDogs() async => dogs;

  @override
  Future<void> saveDog(dynamic dogImage) async {}

  @override
  Future<void> deleteDog(String id) async {
    deletedIds.add(id);
    dogs.removeWhere((d) => d.id == id);
  }

  @override
  Future<bool> isSaved(String id) async => dogs.any((d) => d.id == id);
}

void main() {
  group('GalleryPage Widget Tests', () {
    testWidgets('shows empty state when no dogs are saved', (tester) async {
      final fakeRepository = FakeGalleryRepository(initialDogs: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            galleryRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: const MaterialApp(
            home: GalleryPage(),
          ),
        ),
      );

      // Settle loading state
      await tester.pump();

      expect(find.text('No Saved Dogs Yet'), findsOneWidget);
      expect(
        find.text('Tap the heart icon on any dog in the Discovery screen to save them to your offline gallery!'),
        findsOneWidget,
      );
    });

    testWidgets('shows saved dogs in grid', (tester) async {
      final savedDogs = [
        SavedDog(
          id: 'dog_1',
          localImagePath: '/fake/path/dog1.jpg',
          url: 'https://example.com/dog1.jpg',
          width: 100,
          height: 100,
          breeds: [const Breed(id: '1', name: 'Poodle')],
          savedAt: DateTime.now(),
        ),
        SavedDog(
          id: 'dog_2',
          localImagePath: '/fake/path/dog2.jpg',
          url: 'https://example.com/dog2.jpg',
          width: 100,
          height: 100,
          breeds: [const Breed(id: '2', name: 'Beagle')],
          savedAt: DateTime.now(),
        ),
      ];

      final fakeRepository = FakeGalleryRepository(initialDogs: savedDogs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            galleryRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: const MaterialApp(
            home: GalleryPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Poodle'), findsOneWidget);
      expect(find.text('Beagle'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('triggers deletion and updates list on confirmation', (tester) async {
      final savedDogs = [
        SavedDog(
          id: 'dog_1',
          localImagePath: '/fake/path/dog1.jpg',
          url: 'https://example.com/dog1.jpg',
          width: 100,
          height: 100,
          breeds: [const Breed(id: '1', name: 'Poodle')],
          savedAt: DateTime.now(),
        ),
      ];

      final fakeRepository = FakeGalleryRepository(initialDogs: savedDogs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            galleryRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: const MaterialApp(
            home: GalleryPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Poodle'), findsOneWidget);

      // Tap delete on card
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle(); // settle dialog animation

      expect(find.text('Delete Saved Dog'), findsOneWidget);

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pump(); // dismiss dialog
      await tester.pump(); // update grid list

      expect(find.text('Poodle'), findsNothing);
      expect(fakeRepository.deletedIds, contains('dog_1'));
    });
  });

  group('SavedDogDetailPage Widget Tests', () {
    testWidgets('shows detail for a valid saved dog', (tester) async {
      final savedDogs = [
        SavedDog(
          id: 'dog_1',
          localImagePath: '/fake/path/dog1.jpg',
          url: 'https://example.com/dog1.jpg',
          width: 100,
          height: 100,
          breeds: [
            const Breed(
              id: '1',
              name: 'Poodle',
              breedGroup: 'Non-Sporting',
              description: 'Active and smart.',
              temperament: 'Intelligent, Faithful',
              lifeSpan: '12-15 years',
            )
          ],
          savedAt: DateTime.now(),
        ),
      ];

      final fakeRepository = FakeGalleryRepository(initialDogs: savedDogs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            galleryRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: const MaterialApp(
            home: SavedDogDetailPage(id: 'dog_1'),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Poodle'), findsNWidgets(2));
      expect(find.text('Non-Sporting'), findsOneWidget);
      expect(find.text('Active and smart.'), findsOneWidget);
      expect(find.text('Intelligent, Faithful'), findsOneWidget);
      expect(find.text('12-15 years'), findsOneWidget);
      expect(find.text('Storage Snapshot'), findsOneWidget);
    });

    testWidgets('shows missing dog state', (tester) async {
      final fakeRepository = FakeGalleryRepository(initialDogs: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            galleryRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: const MaterialApp(
            home: SavedDogDetailPage(id: 'non_existent'),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Saved dog not found or has been deleted.'), findsOneWidget);
    });
  });
}
