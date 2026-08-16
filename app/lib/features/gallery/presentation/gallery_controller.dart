import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gallery_repository.dart';
import '../domain/saved_dog.dart';

class GalleryController extends AutoDisposeAsyncNotifier<List<SavedDog>> {
  bool _isWorking = false;

  @override
  Future<List<SavedDog>> build() {
    return _fetch();
  }

  Future<List<SavedDog>> _fetch() {
    final repository = ref.read(galleryRepositoryProvider);
    return repository.getSavedDogs();
  }

  /// Refreshes the gallery list. Concurrent invocations are ignored so
  /// duplicate taps or overlapping pull-to-refresh gestures do not race.
  Future<void> refresh() async {
    if (_isWorking) return;
    _isWorking = true;
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() => _fetch());
    } finally {
      _isWorking = false;
    }
  }

  /// Deletes the saved dog with the given [id] and reloads the list.
  /// Guards against concurrent delete/refresh operations.
  Future<void> deleteSavedDog(String id) async {
    if (_isWorking) return;
    _isWorking = true;
    state = const AsyncLoading();
    try {
      final repository = ref.read(galleryRepositoryProvider);
      await repository.deleteDog(id);
      state = await AsyncValue.guard(() => _fetch());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    } finally {
      _isWorking = false;
    }
  }
}

final galleryControllerProvider =
    AutoDisposeAsyncNotifierProvider<GalleryController, List<SavedDog>>(() {
      return GalleryController();
    });
