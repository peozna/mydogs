import '../domain/breed.dart';
import '../domain/dog_image.dart';

class BreedDto {
  const BreedDto({
    required this.id,
    required this.name,
    this.lifeSpan,
    this.temperament,
    this.origin,
    this.description,
    this.breedGroup,
    this.bredFor,
    this.heightImperial,
    this.heightMetric,
    this.weightImperial,
    this.weightMetric,
  });

  final String id;
  final String name;
  final String? lifeSpan;
  final String? temperament;
  final String? origin;
  final String? description;
  final String? breedGroup;
  final String? bredFor;
  final String? heightImperial;
  final String? heightMetric;
  final String? weightImperial;
  final String? weightMetric;

  factory BreedDto.fromJson(Map<String, dynamic> json) {
    String? hImp;
    String? hMet;
    if (json['height'] is Map) {
      final heightMap = json['height'] as Map<dynamic, dynamic>;
      hImp = heightMap['imperial']?.toString();
      hMet = heightMap['metric']?.toString();
    } else {
      hImp =
          json['male_height_inches']?.toString() ??
          json['female_height_inches']?.toString();
      hMet =
          json['male_height_cm']?.toString() ??
          json['female_height_cm']?.toString();
    }

    String? wImp;
    String? wMet;
    if (json['weight'] is Map) {
      final weightMap = json['weight'] as Map<dynamic, dynamic>;
      wImp = weightMap['imperial']?.toString();
      wMet = weightMap['metric']?.toString();
    } else {
      wImp =
          json['male_weight_pounds']?.toString() ??
          json['female_weight_pounds']?.toString();
      wMet =
          json['male_weight_kg']?.toString() ??
          json['female_weight_kg']?.toString();
    }

    return BreedDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      lifeSpan: json['life_span'] as String?,
      temperament: json['temperament'] as String?,
      origin: json['origin'] as String?,
      description: json['description'] as String?,
      breedGroup: json['breed_group'] as String?,
      bredFor: json['bred_for'] as String?,
      heightImperial: hImp,
      heightMetric: hMet,
      weightImperial: wImp,
      weightMetric: wMet,
    );
  }

  Breed toDomain() {
    return Breed(
      id: id,
      name: name,
      lifeSpan: lifeSpan,
      temperament: temperament,
      origin: origin,
      description: description,
      breedGroup: breedGroup,
      bredFor: bredFor,
      heightImperial: heightImperial,
      heightMetric: heightMetric,
      weightImperial: weightImperial,
      weightMetric: weightMetric,
    );
  }
}

class ImageDto {
  const ImageDto({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    this.breeds,
  });

  final String id;
  final String url;
  final int width;
  final int height;
  final List<BreedDto>? breeds;

  factory ImageDto.fromJson(Map<String, dynamic> json) {
    return ImageDto(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      breeds: (json['breeds'] as List<dynamic>?)
          ?.map((e) => BreedDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  DogImage toDomain() {
    return DogImage(
      id: id,
      url: url,
      width: width,
      height: height,
      breeds: breeds?.map((b) => b.toDomain()).toList() ?? const [],
    );
  }
}
