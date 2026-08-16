import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydogs/core/error/app_exception.dart';
import 'package:mydogs/features/dog_discovery/domain/breed.dart';
import 'package:mydogs/features/dog_discovery/domain/dog_image.dart';
import 'package:mydogs/features/gallery/data/gallery_repository.dart';
import 'package:mydogs/features/gallery/data/local_gallery_storage.dart';
import 'package:mydogs/features/gallery/domain/saved_dog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ThrowingBreed extends Breed {
  const _ThrowingBreed() : super(id: '', name: '');

  @override
  String get id => throw Exception('Simulated metadata write failure');
}

class FakeLocalGalleryStorage implements LocalGalleryStorage {
  FakeLocalGalleryStorage({this.onSaveImage, this.onDeleteImage});

  Future<String> Function(String imageId, String url)? onSaveImage;
  Future<void> Function(String path)? onDeleteImage;

  @override
  Future<String> saveImage(String imageId, String url) async {
    if (onSaveImage != null) {
      return onSaveImage!(imageId, url);
    }
    return '/fake/path/dog_$imageId.jpg';
  }

  @override
  Future<void> deleteImage(String path) async {
    if (onDeleteImage != null) {
      await onDeleteImage!(path);
    }
  }
}

void main() {
  group('GalleryRepository Unit Tests', () {
    late FakeLocalGalleryStorage fakeStorage;
    late GalleryRepositoryImpl repository;
    const key = 'saved_dogs_list';

    setUp(() {
      fakeStorage = FakeLocalGalleryStorage();
      repository = GalleryRepositoryImpl(fakeStorage);
    });

    test(
      'saveDog downloads the image and saves metadata successfully',
      () async {
        SharedPreferences.setMockInitialValues({});

        final dogImage = DogImage(
          id: 'golden_123',
          url: 'https://example.com/golden.jpg',
          width: 600,
          height: 400,
          breeds: [const Breed(id: '1', name: 'Golden Retriever')],
        );

        String? savedImageId;
        String? savedUrl;
        fakeStorage.onSaveImage = (imageId, url) async {
          savedImageId = imageId;
          savedUrl = url;
          return '/fake/path/dog_$imageId.jpg';
        };

        await repository.saveDog(dogImage);

        expect(savedImageId, 'golden_123');
        expect(savedUrl, 'https://example.com/golden.jpg');

        final savedList = await repository.getSavedDogs();
        expect(savedList.length, 1);
        expect(savedList.first.id, 'golden_123');
        expect(savedList.first.localImagePath, '/fake/path/dog_golden_123.jpg');
        expect(savedList.first.breeds.first.name, 'Golden Retriever');

        final isSaved = await repository.isSaved('golden_123');
        expect(isSaved, true);
      },
    );

    test('saveDog prevents duplicate entries', () async {
      SharedPreferences.setMockInitialValues({});

      final dogImage = DogImage(
        id: 'golden_123',
        url: 'https://example.com/golden.jpg',
        width: 600,
        height: 400,
        breeds: [const Breed(id: '1', name: 'Golden Retriever')],
      );

      int saveCount = 0;
      fakeStorage.onSaveImage = (imageId, url) async {
        saveCount++;
        return '/fake/path/dog_$imageId.jpg';
      };

      await repository.saveDog(dogImage);
      await repository.saveDog(dogImage); // Duplicate try

      expect(saveCount, 1); // Should only trigger file save once

      final savedList = await repository.getSavedDogs();
      expect(savedList.length, 1);
    });

    test(
      'saveDog cleans up local file if SharedPreferences write fails',
      () async {
        SharedPreferences.setMockInitialValues({});

        final dogImage = DogImage(
          id: 'error_123',
          url: 'https://example.com/error.jpg',
          width: 600,
          height: 400,
          breeds: [const _ThrowingBreed()],
        );

        bool deletedFile = false;
        fakeStorage.onSaveImage = (imageId, url) async {
          return '/fake/path/to_be_cleaned.jpg';
        };
        fakeStorage.onDeleteImage = (path) async {
          if (path == '/fake/path/to_be_cleaned.jpg') {
            deletedFile = true;
          }
        };

        await expectLater(
          () => repository.saveDog(dogImage),
          throwsA(isA<StorageException>()),
        );

        expect(deletedFile, true); // Local file must be cleaned up!
      },
    );

    test(
      'deleteDog deletes local file and removes metadata from SharedPreferences',
      () async {
        final savedDog = SavedDog(
          id: 'husky_123',
          localImagePath: '/fake/path/dog_husky_123.jpg',
          url: 'https://example.com/husky.jpg',
          width: 500,
          height: 500,
          breeds: [const Breed(id: '2', name: 'Siberian Husky')],
          savedAt: DateTime.now(),
        );

        SharedPreferences.setMockInitialValues({
          key: [jsonEncode(savedDog.toJson())],
        });

        String? deletedPath;
        fakeStorage.onDeleteImage = (path) async {
          deletedPath = path;
        };

        await repository.deleteDog('husky_123');

        expect(deletedPath, '/fake/path/dog_husky_123.jpg');

        final savedList = await repository.getSavedDogs();
        expect(savedList.isEmpty, true);

        final isSaved = await repository.isSaved('husky_123');
        expect(isSaved, false);
      },
    );

    test(
      'deleteDog cleans metadata even if local file deletion fails (missing file)',
      () async {
        final savedDog = SavedDog(
          id: 'husky_123',
          localImagePath: '/fake/path/dog_husky_123.jpg',
          url: 'https://example.com/husky.jpg',
          width: 500,
          height: 500,
          breeds: [const Breed(id: '2', name: 'Siberian Husky')],
          savedAt: DateTime.now(),
        );

        SharedPreferences.setMockInitialValues({
          key: [jsonEncode(savedDog.toJson())],
        });

        fakeStorage.onDeleteImage = (path) async {
          throw Exception('File not found');
        };

        // Deleting should not fail overall
        await repository.deleteDog('husky_123');

        final savedList = await repository.getSavedDogs();
        expect(savedList.isEmpty, true); // Metadata still removed!
      },
    );
  });
}
