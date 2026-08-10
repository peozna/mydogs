
class Breed {
  const Breed({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Breed &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
