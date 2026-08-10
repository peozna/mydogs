import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gallery_repository.dart';
import '../domain/saved_dog.dart';

class GalleryController extends AutoDisposeAsyncNotifier<List<SavedDog>> {
  @override
  Future<List<SavedDog>> build() {
    return _fetch();
  }

  Future<List<SavedDog>> _fetch() {
    final repository = ref.read(galleryRepositoryProvider);
    return repository.getSavedDogs();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> deleteSavedDog(String id) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(galleryRepositoryProvider);
      await repository.deleteDog(id);
      state = await AsyncValue.guard(() => _fetch());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final galleryControllerProvider =
    AutoDisposeAsyncNotifierProvider<GalleryController, List<SavedDog>>(() {
  return GalleryController();
});
