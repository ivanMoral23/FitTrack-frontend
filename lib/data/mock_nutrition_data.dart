import '../models/nutrition_profile.dart';
import '../models/diet_plan.dart';
import '../models/meal.dart';
import '../models/food_item.dart';

class MockNutritionData {
  static final NutritionProfile currentUser = NutritionProfile(
    id: 'u1',
    weight: 75.0,
    height: 180.0,
    age: 25,
    gender: Gender.male,
    activityLevel: ActivityLevel.moderate,
    goal: Goal.buildMuscle,
    preference: DietaryPreference.standard,
    mealsPerDay: 4,
    targetCalories: 2800,
    targetProtein: 160,
    targetCarbs: 350,
    targetFat: 84,
  );

  static final List<DietPlan> dietPlans = [
    DietPlan(
      id: 'd1',
      name: 'Definición 1800 kcal',
      description:
          'Dieta baja en calorías orientada a perder grasa sin perder masa muscular.',
      targetGoal: Goal.loseFat,
      totalCalories: 1800,
      protein: 150,
      carbs: 150,
      fat: 66,
      meals: _createDefinicionMeals(),
    ),
    DietPlan(
      id: 'd2',
      name: 'Volumen limpio 2800 kcal',
      description:
          'Ideal para ganar masa muscular minimizando la ganancia de grasa.',
      targetGoal: Goal.buildMuscle,
      totalCalories: 2800,
      protein: 180,
      carbs: 350,
      fat: 75,
      isRecommended: true,
      meals: _createVolumenMeals(),
    ),
    DietPlan(
      id: 'd3',
      name: 'Mantenimiento equilibrado 2200 kcal',
      description:
          'Dieta balanceada para mantener peso y tener energía para entrenar.',
      targetGoal: Goal.maintain,
      totalCalories: 2200,
      protein: 140,
      carbs: 250,
      fat: 70,
      meals: _createMantenimientoMeals(),
    ),
    DietPlan(
      id: 'd4',
      name: 'Alta proteína 2400 kcal',
      description:
          'Especialmente diseñada para hipertrofia y recuperación rápida.',
      targetGoal: Goal.buildMuscle,
      totalCalories: 2400,
      protein: 200,
      carbs: 250,
      fat: 65,
      meals: _createAltaProteinaMeals(),
    ),
  ];

  static List<Meal> _createDefinicionMeals() {
    return const [
      Meal(
        id: 'd1_m1',
        name: 'Desayuno',
        mealType: MealType.breakfast,
        items: [
          FoodItem(id: 'd1_f1', name: 'Claras de huevo', portion: '200g', calories: 104, protein: 22, carbs: 1, fat: 0),
          FoodItem(id: 'd1_f2', name: 'Avena integral', portion: '40g', calories: 148, protein: 5, carbs: 26, fat: 3),
        ],
      ),
      Meal(
        id: 'd1_m2',
        name: 'Almuerzo',
        mealType: MealType.lunch,
        items: [
          FoodItem(id: 'd1_f3', name: 'Pechuga de pollo a la plancha', portion: '150g', calories: 247, protein: 46, carbs: 0, fat: 5),
          FoodItem(id: 'd1_f4', name: 'Arroz integral', portion: '80g', calories: 90, protein: 2, carbs: 19, fat: 0),
          FoodItem(id: 'd1_f5', name: 'Brócoli', portion: '150g', calories: 51, protein: 4, carbs: 10, fat: 1),
        ],
      ),
      Meal(
        id: 'd1_m3',
        name: 'Merienda',
        mealType: MealType.snack,
        items: [
          FoodItem(id: 'd1_f6', name: 'Yogur griego 0%', portion: '1 unidad', calories: 59, protein: 10, carbs: 4, fat: 0),
          FoodItem(id: 'd1_f7', name: 'Almendras', portion: '15g', calories: 86, protein: 3, carbs: 3, fat: 7),
        ],
      ),
      Meal(
        id: 'd1_m4',
        name: 'Cena',
        mealType: MealType.dinner,
        items: [
          FoodItem(id: 'd1_f8', name: 'Merluza al horno', portion: '200g', calories: 164, protein: 35, carbs: 0, fat: 2),
          FoodItem(id: 'd1_f9', name: 'Espárragos trigueros', portion: '100g', calories: 20, protein: 2, carbs: 4, fat: 0),
          FoodItem(id: 'd1_f10', name: 'Ensalada variada', portion: '100g', calories: 25, protein: 1, carbs: 5, fat: 0),
        ],
      ),
    ];
  }

  static List<Meal> _createVolumenMeals() {
    return const [
      Meal(
        id: 'd2_m1',
        name: 'Desayuno Fuerte',
        mealType: MealType.breakfast,
        items: [
          FoodItem(id: 'd2_f1', name: 'Huevos enteros', portion: '3 unidades', calories: 230, protein: 19, carbs: 1, fat: 15),
          FoodItem(id: 'd2_f2', name: 'Avena', portion: '100g', calories: 370, protein: 13, carbs: 65, fat: 7),
          FoodItem(id: 'd2_f3', name: 'Plátano', portion: '1 unidad', calories: 105, protein: 1, carbs: 27, fat: 0),
        ],
      ),
      Meal(
        id: 'd2_m2',
        name: 'Almuerzo',
        mealType: MealType.lunch,
        items: [
          FoodItem(id: 'd2_f4', name: 'Pasta integral', portion: '120g (crudo)', calories: 420, protein: 15, carbs: 85, fat: 2),
          FoodItem(id: 'd2_f5', name: 'Carne picada de vacuno (magra)', portion: '150g', calories: 250, protein: 40, carbs: 0, fat: 10),
          FoodItem(id: 'd2_f6', name: 'Tomate y cebolla', portion: '100g', calories: 35, protein: 1, carbs: 8, fat: 0),
        ],
      ),
      Meal(
        id: 'd2_m3',
        name: 'Pre-Entreno',
        mealType: MealType.snack,
        items: [
          FoodItem(id: 'd2_f7', name: 'Crema de cacahuete', portion: '30g', calories: 180, protein: 8, carbs: 6, fat: 15),
          FoodItem(id: 'd2_f8', name: 'Pan integral', portion: '2 rebanadas', calories: 160, protein: 8, carbs: 30, fat: 2),
        ],
      ),
      Meal(
        id: 'd2_m4',
        name: 'Cena Post-entreno',
        mealType: MealType.dinner,
        items: [
          FoodItem(id: 'd2_f9', name: 'Salmón a la plancha', portion: '200g', calories: 400, protein: 40, carbs: 0, fat: 25),
          FoodItem(id: 'd2_f10', name: 'Patata cocida', portion: '250g', calories: 215, protein: 4, carbs: 50, fat: 0),
          FoodItem(id: 'd2_f11', name: 'Verduras al vapor', portion: '150g', calories: 45, protein: 3, carbs: 9, fat: 0),
        ],
      ),
    ];
  }

  static List<Meal> _createMantenimientoMeals() {
    return const [
      Meal(
        id: 'd3_m1',
        name: 'Desayuno',
        mealType: MealType.breakfast,
        items: [
          FoodItem(id: 'd3_f1', name: 'Tostadas integrales', portion: '2 rebanadas', calories: 160, protein: 6, carbs: 30, fat: 2),
          FoodItem(id: 'd3_f2', name: 'Aguacate', portion: '½ unidad', calories: 120, protein: 1, carbs: 6, fat: 11),
          FoodItem(id: 'd3_f3', name: 'Huevo revuelto', portion: '2 unidades', calories: 154, protein: 12, carbs: 1, fat: 10),
        ],
      ),
      Meal(
        id: 'd3_m2',
        name: 'Almuerzo',
        mealType: MealType.lunch,
        items: [
          FoodItem(id: 'd3_f4', name: 'Arroz blanco', portion: '100g (crudo)', calories: 360, protein: 7, carbs: 79, fat: 1),
          FoodItem(id: 'd3_f5', name: 'Pechuga de pollo', portion: '120g', calories: 198, protein: 37, carbs: 0, fat: 4),
          FoodItem(id: 'd3_f6', name: 'Ensalada con aceite de oliva', portion: '150g + 10ml', calories: 110, protein: 2, carbs: 8, fat: 9),
        ],
      ),
      Meal(
        id: 'd3_m3',
        name: 'Merienda',
        mealType: MealType.snack,
        items: [
          FoodItem(id: 'd3_f7', name: 'Batido de proteína', portion: '1 scoop', calories: 120, protein: 25, carbs: 3, fat: 1),
          FoodItem(id: 'd3_f8', name: 'Plátano', portion: '1 unidad', calories: 105, protein: 1, carbs: 27, fat: 0),
        ],
      ),
      Meal(
        id: 'd3_m4',
        name: 'Cena',
        mealType: MealType.dinner,
        items: [
          FoodItem(id: 'd3_f9', name: 'Merluza al vapor', portion: '180g', calories: 148, protein: 31, carbs: 0, fat: 2),
          FoodItem(id: 'd3_f10', name: 'Quinoa cocida', portion: '150g', calories: 180, protein: 7, carbs: 32, fat: 3),
          FoodItem(id: 'd3_f11', name: 'Verduras al vapor', portion: '150g', calories: 45, protein: 3, carbs: 9, fat: 0),
        ],
      ),
      Meal(
        id: 'd3_m5',
        name: 'Snack Nocturno',
        mealType: MealType.snack,
        items: [
          FoodItem(id: 'd3_f12', name: 'Yogur griego 0%', portion: '1 unidad', calories: 59, protein: 10, carbs: 4, fat: 0),
          FoodItem(id: 'd3_f13', name: 'Nueces', portion: '20g', calories: 130, protein: 3, carbs: 3, fat: 13),
        ],
      ),
    ];
  }

  static List<Meal> _createAltaProteinaMeals() {
    return const [
      Meal(
        id: 'd4_m1',
        name: 'Desayuno Alto Proteico',
        mealType: MealType.breakfast,
        items: [
          FoodItem(id: 'd4_f1', name: 'Claras de huevo', portion: '250g', calories: 130, protein: 27, carbs: 2, fat: 0),
          FoodItem(id: 'd4_f2', name: 'Pavo en lonchas', portion: '80g', calories: 88, protein: 18, carbs: 0, fat: 1),
          FoodItem(id: 'd4_f3', name: 'Avena con leche desnatada', portion: '60g + 200ml', calories: 285, protein: 15, carbs: 48, fat: 4),
        ],
      ),
      Meal(
        id: 'd4_m2',
        name: 'Almuerzo',
        mealType: MealType.lunch,
        items: [
          FoodItem(id: 'd4_f4', name: 'Pechuga de pollo a la plancha', portion: '200g', calories: 330, protein: 62, carbs: 0, fat: 7),
          FoodItem(id: 'd4_f5', name: 'Boniato cocido', portion: '200g', calories: 180, protein: 4, carbs: 42, fat: 0),
          FoodItem(id: 'd4_f6', name: 'Brócoli', portion: '150g', calories: 51, protein: 4, carbs: 10, fat: 1),
        ],
      ),
      Meal(
        id: 'd4_m3',
        name: 'Post-Entreno',
        mealType: MealType.snack,
        items: [
          FoodItem(id: 'd4_f7', name: 'Batido de whey protein', portion: '2 scoops', calories: 240, protein: 50, carbs: 6, fat: 2),
          FoodItem(id: 'd4_f8', name: 'Plátano', portion: '1 unidad', calories: 105, protein: 1, carbs: 27, fat: 0),
        ],
      ),
      Meal(
        id: 'd4_m4',
        name: 'Cena',
        mealType: MealType.dinner,
        items: [
          FoodItem(id: 'd4_f9', name: 'Atún al natural', portion: '2 latas (240g)', calories: 264, protein: 58, carbs: 0, fat: 2),
          FoodItem(id: 'd4_f10', name: 'Arroz integral', portion: '100g (crudo)', calories: 350, protein: 8, carbs: 73, fat: 3),
          FoodItem(id: 'd4_f11', name: 'Espinacas salteadas', portion: '100g', calories: 23, protein: 3, carbs: 4, fat: 0),
        ],
      ),
    ];
  }
}
