import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dog_api_repository.dart';
import '../domain/dog_image.dart';

class DogDiscoveryController extends AutoDisposeAsyncNotifier<DogImage> {
  @override
  Future<DogImage> build() {
    return _fetch();
  }

  Future<DogImage> _fetch() {
    final repository = ref.read(dogApiRepositoryProvider);
    return repository.getRandomDogWithBreed();
  }

  Future<void> fetchNewDog() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final dogDiscoveryControllerProvider =
    AutoDisposeAsyncNotifierProvider<DogDiscoveryController, DogImage>(() {
  return DogDiscoveryController();
});
