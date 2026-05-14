
class Exercice {
  final String id;
  final String name;
  final String muscleGroup;
  final String difficulty;
  final String recordType;
  final String mechanics;
  final String movementPattern;
  final List<String> equipment;
  final List<String> instructions;

  Exercice({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.difficulty,
    required this.recordType,
    required this.mechanics,
    required this.movementPattern,
    required this.equipment,
    required this.instructions,
  });

  factory Exercice.fromJson(Map<String, dynamic> json) {
    return Exercice(
      id: json['_id'] ?? '', // Atrapamos el _id que genera MongoDB
      name: json['name'] ?? 'Sin nombre',
      muscleGroup: json['muscle_group'] ?? 'Otros',
      difficulty: json['difficulty'] ?? 'medium',
      recordType: json['recordType'] ?? 'weight_reps',
      mechanics: json['mechanics'] ?? 'compound',
      movementPattern: json['movement_pattern'] ?? 'other',
      equipment: (json['equipment'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      instructions: (json['instructions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
