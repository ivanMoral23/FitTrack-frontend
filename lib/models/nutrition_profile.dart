enum Gender { male, female, other }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }
enum Goal { loseFat, maintain, buildMuscle }
enum DietaryPreference { standard, highProtein, vegetarian, lowCarb }

extension GenderDisplay on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Hombre';
      case Gender.female:
        return 'Mujer';
      case Gender.other:
        return 'Otro';
    }
  }
}

extension ActivityLevelDisplay on ActivityLevel {
  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentario (sin ejercicio)';
      case ActivityLevel.light:
        return 'Ligero (1–3 días/semana)';
      case ActivityLevel.moderate:
        return 'Moderado (3–5 días/semana)';
      case ActivityLevel.active:
        return 'Activo (6–7 días/semana)';
      case ActivityLevel.veryActive:
        return 'Muy Activo (2 veces/día)';
    }
  }
}

extension GoalDisplay on Goal {
  String get displayName {
    switch (this) {
      case Goal.loseFat:
        return 'Perder Grasa';
      case Goal.maintain:
        return 'Mantener Peso';
      case Goal.buildMuscle:
        return 'Ganar Masa Muscular';
    }
  }

  String get emoji {
    switch (this) {
      case Goal.loseFat:
        return '⬇️';
      case Goal.maintain:
        return '⚖️';
      case Goal.buildMuscle:
        return '⬆️';
    }
  }
}

extension DietaryPreferenceDisplay on DietaryPreference {
  String get displayName {
    switch (this) {
      case DietaryPreference.standard:
        return 'Estándar';
      case DietaryPreference.highProtein:
        return 'Alta Proteína';
      case DietaryPreference.vegetarian:
        return 'Vegetariano';
      case DietaryPreference.lowCarb:
        return 'Bajo en Carbohidratos';
    }
  }
}

class NutritionProfile {
  String id;
  double weight; // in kg
  double height; // in cm
  int age;
  Gender gender;
  ActivityLevel activityLevel;
  Goal goal;
  DietaryPreference preference;
  int mealsPerDay;

  int targetCalories;
  int targetProtein;
  int targetCarbs;
  int targetFat;

  NutritionProfile({
    required this.id,
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.preference,
    required this.mealsPerDay,
    this.targetCalories = 0,
    this.targetProtein = 0,
    this.targetCarbs = 0,
    this.targetFat = 0,
  });

  NutritionProfile copyWith({
    String? id,
    double? weight,
    double? height,
    int? age,
    Gender? gender,
    ActivityLevel? activityLevel,
    Goal? goal,
    DietaryPreference? preference,
    int? mealsPerDay,
    int? targetCalories,
    int? targetProtein,
    int? targetCarbs,
    int? targetFat,
  }) {
    return NutritionProfile(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      preference: preference ?? this.preference,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
    );
  }
}
