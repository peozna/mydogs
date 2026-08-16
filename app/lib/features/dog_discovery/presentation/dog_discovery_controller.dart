import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dog_api_repository.dart';
import '../domain/dog_image.dart';

class DogDiscoveryController extends AutoDisposeAsyncNotifier<DogImage> {
  bool _isFetching = false;

  @override
  Future<DogImage> build() {
    _isFetching = true;
    return _fetch().whenComplete(() => _isFetching = false);
  }

  Future<DogImage> _fetch() {
    final repository = ref.read(dogApiRepositoryProvider);
    return repository.getRandomDogWithBreed();
  }

  /// Fetches a new random dog. Guards against concurrent invocations so
  /// duplicate taps or simultaneous refresh triggers do not start parallel
  /// requests that race each other.
  Future<void> fetchNewDog() async {
    if (_isFetching) return;
    _isFetching = true;

    // Keep the previous data visible while the refresh is in flight so a
    // failed refresh does not discard already loaded content.
    final previous = state;
    state = AsyncLoading<DogImage>().copyWithPrevious(previous);

    try {
      state = await AsyncValue.guard(() => _fetch());
    } finally {
      _isFetching = false;
    }
  }
}

final dogDiscoveryControllerProvider =
    AutoDisposeAsyncNotifierProvider<DogDiscoveryController, DogImage>(() {
      return DogDiscoveryController();
    });
