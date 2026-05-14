import 'meal.dart';
import 'nutrition_profile.dart'; // To reuse Goal enum if needed

class DietPlan {
  final String id;
  final String name;
  final String description;
  final Goal targetGoal;
  final int totalCalories;
  final int protein;
  final int carbs;
  final int fat;
  final List<Meal> meals;
  final bool isRecommended; // A tag to show "Recommended for you" if it matches user profile

  DietPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.targetGoal,
    required this.totalCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meals,
    this.isRecommended = false,
  });
}
