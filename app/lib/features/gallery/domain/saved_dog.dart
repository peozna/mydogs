import '../../dog_discovery/domain/breed.dart';

class SavedDog {
  const SavedDog({
    required this.id,
    required this.localImagePath,
    required this.url,
    required this.width,
    required this.height,
    required this.breeds,
    required this.savedAt,
  });

  final String id;
  final String localImagePath;
  final String url;
  final int width;
  final int height;
  final List<Breed> breeds;
  final DateTime savedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localImagePath': localImagePath,
      'url': url,
      'width': width,
      'height': height,
      'breeds': breeds
          .map((b) => {
                'id': b.id,
                'name': b.name,
                'lifeSpan': b.lifeSpan,
                'temperament': b.temperament,
                'origin': b.origin,
                'description': b.description,
                'breedGroup': b.breedGroup,
                'bredFor': b.bredFor,
                'heightImperial': b.heightImperial,
                'heightMetric': b.heightMetric,
                'weightImperial': b.weightImperial,
                'weightMetric': b.weightMetric,
              })
          .toList(),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedDog.fromJson(Map<String, dynamic> json) {
    return SavedDog(
      id: json['id'] as String,
      localImagePath: json['localImagePath'] as String,
      url: json['url'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      breeds: (json['breeds'] as List<dynamic>?)?.map((b) {
            final map = b as Map<String, dynamic>;
            return Breed(
              id: map['id']?.toString() ?? '',
              name: map['name'] as String? ?? 'Unknown',
              lifeSpan: map['lifeSpan'] as String?,
              temperament: map['temperament'] as String?,
              origin: map['origin'] as String?,
              description: map['description'] as String?,
              breedGroup: map['breedGroup'] as String?,
              bredFor: map['bredFor'] as String?,
              heightImperial: map['heightImperial'] as String?,
              heightMetric: map['heightMetric'] as String?,
              weightImperial: map['weightImperial'] as String?,
              weightMetric: map['weightMetric'] as String?,
            );
          }).toList() ??
          const [],
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedDog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          localImagePath == other.localImagePath &&
          url == other.url &&
          width == other.width &&
          height == other.height &&
          savedAt == other.savedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      localImagePath.hashCode ^
      url.hashCode ^
      width.hashCode ^
      height.hashCode ^
      savedAt.hashCode;
}
