import '../models/nutrition_profile.dart';

class NutritionCalculator {
  static const int _minCaloriesMale = 1500;
  static const int _minCaloriesFemale = 1200;

  // Mifflin-St Jeor Equation
  static int calculateMaintenanceCalories({
    required double weight,
    required double height,
    required int age,
    required Gender gender,
    required ActivityLevel activityLevel,
  }) {
    double bmr;
    if (gender == Gender.male) {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else if (gender == Gender.female) {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      // Average of male and female formulas for Gender.other
      final male = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      final female = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      bmr = (male + female) / 2;
    }

    double multiplier;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        multiplier = 1.2;
        break;
      case ActivityLevel.light:
        multiplier = 1.375;
        break;
      case ActivityLevel.moderate:
        multiplier = 1.55;
        break;
      case ActivityLevel.active:
        multiplier = 1.725;
        break;
      case ActivityLevel.veryActive:
        multiplier = 1.9;
        break;
    }

    return (bmr * multiplier).round();
  }

  static int calculateTargetCalories(int maintenance, Goal goal) {
    switch (goal) {
      case Goal.loseFat:
        return maintenance - 500;
      case Goal.buildMuscle:
        return maintenance + 300;
      case Goal.maintain:
        return maintenance;
    }
  }

  static Map<String, int> calculateMacros(
    int calories,
    double weight,
    DietaryPreference preference,
  ) {
    // Apply minimum calorie floor before calculating macros
    final effectiveCalories = calories.clamp(_minCaloriesFemale, 999999);

    double proteinGrams = weight * 2.0;
    double fatGrams = weight * 1.0;

    switch (preference) {
      case DietaryPreference.highProtein:
        proteinGrams = weight * 2.5;
        break;
      case DietaryPreference.lowCarb:
        proteinGrams = weight * 2.2;
        fatGrams = weight * 1.5;
        break;
      case DietaryPreference.vegetarian:
        proteinGrams = weight * 1.8;
        fatGrams = weight * 1.2;
        break;
      case DietaryPreference.standard:
        break;
    }

    int proteinCals = (proteinGrams * 4).round();
    int fatCals = (fatGrams * 9).round();

    // Reserve at least 10% of calories for carbs to avoid zero/negative carbs
    final maxProteinFatCals = (effectiveCalories * 0.90).round();
    if (proteinCals + fatCals > maxProteinFatCals) {
      final scale = maxProteinFatCals / (proteinCals + fatCals);
      proteinGrams *= scale;
      fatGrams *= scale;
      proteinCals = (proteinGrams * 4).round();
      fatCals = (fatGrams * 9).round();
    }

    final carbCals = effectiveCalories - proteinCals - fatCals;
    final carbGrams = (carbCals / 4.0).round();

    return {
      'protein': proteinGrams.round().clamp(0, 9999),
      'fat': fatGrams.round().clamp(0, 9999),
      'carbs': carbGrams.clamp(0, 9999),
    };
  }

  // Returns true if calories are below safe minimum for the given gender
  static bool isBelowMinimum(int calories, Gender gender) {
    final min = gender == Gender.male ? _minCaloriesMale : _minCaloriesFemale;
    return calories < min;
  }

  static int getMinimumCalories(Gender gender) {
    return gender == Gender.male ? _minCaloriesMale : _minCaloriesFemale;
  }
}
