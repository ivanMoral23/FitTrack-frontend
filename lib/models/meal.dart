import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeDisplay on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Desayuno';
      case MealType.lunch:
        return 'Almuerzo';
      case MealType.dinner:
        return 'Cena';
      case MealType.snack:
        return 'Snack / Merienda';
    }
  }
}

class Meal {
  final String id;
  final String name;
  final List<FoodItem> items;
  final bool isCompleted;
  final MealType mealType;

  const Meal({
    required this.id,
    required this.name,
    required this.items,
    this.isCompleted = false,
    this.mealType = MealType.snack,
  });

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  int get totalProtein => items.fold(0, (sum, item) => sum + item.protein);
  int get totalCarbs => items.fold(0, (sum, item) => sum + item.carbs);
  int get totalFat => items.fold(0, (sum, item) => sum + item.fat);

  Meal copyWith({
    String? id,
    String? name,
    List<FoodItem>? items,
    bool? isCompleted,
    MealType? mealType,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      isCompleted: isCompleted ?? this.isCompleted,
      mealType: mealType ?? this.mealType,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isCompleted': isCompleted,
    'mealType': mealType.index,
    'items': items.map((i) => i.toJson()).toList(),
  };
}
