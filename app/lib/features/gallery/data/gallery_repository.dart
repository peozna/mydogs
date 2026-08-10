import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/error/app_exception.dart';
import '../../dog_discovery/domain/dog_image.dart';
import '../domain/saved_dog.dart';
import 'local_gallery_storage.dart';

abstract class GalleryRepository {
  Future<List<SavedDog>> getSavedDogs();
  Future<void> saveDog(DogImage dogImage);
  Future<void> deleteDog(String id);
  Future<bool> isSaved(String id);
}

class GalleryRepositoryImpl implements GalleryRepository {
  GalleryRepositoryImpl(this._storage);

  final LocalGalleryStorage _storage;
  static const _key = 'saved_dogs_list';

  @override
  Future<List<SavedDog>> getSavedDogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key);
      if (list == null) return const [];

      return list.map((item) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        return SavedDog.fromJson(json);
      }).toList();
    } catch (e) {
      throw StorageException(cause: e);
    }
  }

  @override
  Future<void> saveDog(DogImage dogImage) async {
    final saved = await isSaved(dogImage.id);
    if (saved) return; // Duplicate detection

    String? localPath;
    try {
      // 1. Download image bytes and write to app-private directory
      localPath = await _storage.saveImage(dogImage.id, dogImage.url);

      // 2. Construct SavedDog record
      final savedDog = SavedDog(
        id: dogImage.id,
        localImagePath: localPath,
        url: dogImage.url,
        width: dogImage.width,
        height: dogImage.height,
        breeds: dogImage.breeds,
        savedAt: DateTime.now(),
      );

      // 3. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(_key) ?? [];
      currentList.add(jsonEncode(savedDog.toJson()));

      final success = await prefs.setStringList(_key, currentList);
      if (!success) {
        throw const StorageException(cause: 'Failed to save string list to SharedPreferences.');
      }
    } catch (e) {
      // Cleanup written file if metadata persistence fails
      if (localPath != null) {
        try {
          await _storage.deleteImage(localPath);
        } catch (_) {}
      }
      if (e is AppException) rethrow;
      throw StorageException(cause: e);
    }
  }

  @override
  Future<void> deleteDog(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(_key);
      if (currentList == null) return;

      SavedDog? targetDog;
      final newList = <String>[];

      for (final item in currentList) {
        final json = jsonDecode(item) as Map<String, dynamic>;
        final dog = SavedDog.fromJson(json);
        if (dog.id == id) {
          targetDog = dog;
        } else {
          newList.add(item);
        }
      }

      if (targetDog != null) {
        // Attempt to remove corresponding file. Missing file should not prevent metadata cleanup.
        try {
          await _storage.deleteImage(targetDog.localImagePath);
        } catch (_) {}

        final success = await prefs.setStringList(_key, newList);
        if (!success) {
          throw const StorageException(cause: 'Failed to write updated list to SharedPreferences.');
        }
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw StorageException(cause: e);
    }
  }

  @override
  Future<bool> isSaved(String id) async {
    try {
      final list = await getSavedDogs();
      return list.any((dog) => dog.id == id);
    } catch (_) {
      return false;
    }
  }
}

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  final storage = ref.watch(localGalleryStorageProvider);
  return GalleryRepositoryImpl(storage);
});
