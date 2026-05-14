class FoodDatabaseItem {
  final String name;
  final String portion;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String category;
  final bool isFromApi;

  const FoodDatabaseItem({
    required this.name,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
    this.isFromApi = false,
  });
}

class FoodDatabase {
  static const List<FoodDatabaseItem> items = [
    // Proteínas
    FoodDatabaseItem(name: 'Pechuga de pollo', portion: '100g', calories: 165, protein: 31, carbs: 0, fat: 4, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Huevo entero', portion: '1 unidad (60g)', calories: 90, protein: 7, carbs: 1, fat: 6, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Claras de huevo', portion: '100g', calories: 52, protein: 11, carbs: 1, fat: 0, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Atún al natural', portion: '100g', calories: 116, protein: 26, carbs: 0, fat: 1, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Salmón', portion: '100g', calories: 208, protein: 20, carbs: 0, fat: 13, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Merluza', portion: '100g', calories: 82, protein: 18, carbs: 0, fat: 1, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Ternera magra', portion: '100g', calories: 158, protein: 26, carbs: 0, fat: 6, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Pavo en lonchas', portion: '100g', calories: 135, protein: 30, carbs: 0, fat: 1, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Yogur griego 0%', portion: '125g', calories: 74, protein: 13, carbs: 5, fat: 0, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Requesón 0%', portion: '100g', calories: 74, protein: 13, carbs: 3, fat: 0, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Batido de proteína (whey)', portion: '30g (1 scoop)', calories: 120, protein: 24, carbs: 3, fat: 2, category: 'Proteínas'),
    FoodDatabaseItem(name: 'Carne picada vacuno (magra)', portion: '100g', calories: 174, protein: 26, carbs: 0, fat: 7, category: 'Proteínas'),
    // Carbohidratos
    FoodDatabaseItem(name: 'Arroz blanco cocido', portion: '100g', calories: 130, protein: 3, carbs: 28, fat: 0, category: 'Carbohidratos'),
    FoodDatabaseItem(name: 'Arroz integral cocido', portion: '100g', calories: 123, protein: 3, carbs: 26, fat: 1, category: 'Carbohidratos'),
    FoodDatabaseItem(name: 'Pasta cocida', portion: '100g', calories: 157, protein: 5, carbs: 30, fat: 1, category: 'Carbohidratos'),
    FoodDatabaseItem(name: 'Avena', portion: '100g', calories: 370, protein: 13, carbs: 65, fat: 7, category: 'Carbohidratos'),
    FoodDatabaseItem(name: 'Pan integral', portion: '1 rebanada (35g)', calories: 87, protein: 4, carbs: 16, fat: 1, category: 'Carbohidratos'),
    FoodDatabaseItem(name: 'Patata cocida', portion: '100g', calories: 86, protein: 2, carbs: 20, fat: 0, category: 'Carbohidratos'),
    FoodDatabaseItem(name: 'Boniato cocido', portion: '100g', calories: 90, protein: 2, carbs: 21, fat: 0, category: 'Carbohidratos'),
    FoodDatabaseItem(name: 'Quinoa cocida', portion: '100g', calories: 120, protein: 4, carbs: 22, fat: 2, category: 'Carbohidratos'),
    // Frutas
    FoodDatabaseItem(name: 'Plátano', portion: '1 unidad (120g)', calories: 110, protein: 1, carbs: 28, fat: 0, category: 'Frutas'),
    FoodDatabaseItem(name: 'Manzana', portion: '1 unidad (150g)', calories: 78, protein: 0, carbs: 21, fat: 0, category: 'Frutas'),
    FoodDatabaseItem(name: 'Naranja', portion: '1 unidad (150g)', calories: 62, protein: 1, carbs: 15, fat: 0, category: 'Frutas'),
    FoodDatabaseItem(name: 'Fresas', portion: '100g', calories: 33, protein: 1, carbs: 8, fat: 0, category: 'Frutas'),
    FoodDatabaseItem(name: 'Uvas', portion: '100g', calories: 69, protein: 1, carbs: 18, fat: 0, category: 'Frutas'),
    // Verduras
    FoodDatabaseItem(name: 'Brócoli', portion: '100g', calories: 34, protein: 3, carbs: 7, fat: 0, category: 'Verduras'),
    FoodDatabaseItem(name: 'Espinacas', portion: '100g', calories: 23, protein: 3, carbs: 4, fat: 0, category: 'Verduras'),
    FoodDatabaseItem(name: 'Tomate', portion: '100g', calories: 18, protein: 1, carbs: 4, fat: 0, category: 'Verduras'),
    FoodDatabaseItem(name: 'Lechuga', portion: '100g', calories: 15, protein: 1, carbs: 3, fat: 0, category: 'Verduras'),
    FoodDatabaseItem(name: 'Pepino', portion: '100g', calories: 16, protein: 1, carbs: 4, fat: 0, category: 'Verduras'),
    FoodDatabaseItem(name: 'Pimiento', portion: '100g', calories: 31, protein: 1, carbs: 7, fat: 0, category: 'Verduras'),
    FoodDatabaseItem(name: 'Zanahoria', portion: '100g', calories: 41, protein: 1, carbs: 10, fat: 0, category: 'Verduras'),
    FoodDatabaseItem(name: 'Espárragos', portion: '100g', calories: 20, protein: 2, carbs: 4, fat: 0, category: 'Verduras'),
    FoodDatabaseItem(name: 'Cebolla', portion: '100g', calories: 40, protein: 1, carbs: 9, fat: 0, category: 'Verduras'),
    // Grasas saludables
    FoodDatabaseItem(name: 'Aguacate', portion: '100g', calories: 160, protein: 2, carbs: 9, fat: 15, category: 'Grasas'),
    FoodDatabaseItem(name: 'Aceite de oliva', portion: '10ml', calories: 90, protein: 0, carbs: 0, fat: 10, category: 'Grasas'),
    FoodDatabaseItem(name: 'Almendras', portion: '30g', calories: 170, protein: 6, carbs: 6, fat: 15, category: 'Grasas'),
    FoodDatabaseItem(name: 'Nueces', portion: '30g', calories: 196, protein: 5, carbs: 4, fat: 19, category: 'Grasas'),
    FoodDatabaseItem(name: 'Crema de cacahuete', portion: '30g', calories: 188, protein: 8, carbs: 6, fat: 15, category: 'Grasas'),
    // Lácteos
    FoodDatabaseItem(name: 'Leche entera', portion: '200ml', calories: 130, protein: 6, carbs: 10, fat: 7, category: 'Lácteos'),
    FoodDatabaseItem(name: 'Leche desnatada', portion: '200ml', calories: 70, protein: 7, carbs: 10, fat: 0, category: 'Lácteos'),
    FoodDatabaseItem(name: 'Queso fresco', portion: '100g', calories: 98, protein: 11, carbs: 3, fat: 4, category: 'Lácteos'),
    FoodDatabaseItem(name: 'Queso cottage', portion: '100g', calories: 103, protein: 12, carbs: 3, fat: 5, category: 'Lácteos'),
  ];

  static List<FoodDatabaseItem> search(String query) {
    if (query.trim().isEmpty) return items;
    final q = query.toLowerCase().trim();
    return items.where((f) {
      return f.name.toLowerCase().contains(q) ||
          f.category.toLowerCase().contains(q);
    }).toList();
  }

  static List<String> get categories =>
      items.map((f) => f.category).toSet().toList();
}
