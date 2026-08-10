ls
import 'breed.dart';

class DogImage {
  const DogImage({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    required this.breeds,
  });

  final String id;
  final String url;
  final int width;
  final int height;
  final List<Breed> breeds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DogImage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode =>
      id.hashCode ^ url.hashCode ^ width.hashCode ^ height.hashCode;
}
