class FoodItem {
  final String id;
  final String name;
  final String portion;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const FoodItem({
    required this.id,
    required this.name,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'portion': portion,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'] as String,
    name: json['name'] as String,
    portion: json['portion'] as String,
    calories: json['calories'] as int,
    protein: json['protein'] as int,
    carbs: json['carbs'] as int,
    fat: json['fat'] as int,
  );
}
