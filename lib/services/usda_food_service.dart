import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart';
import '../data/food_database.dart';
import '../globals/global_variables.dart';

class UsdaFoodService {
  static Future<List<FoodDatabaseItem>> search(String query) async {
    final uri = Uri.parse(
      '$baseUrl/api/food/search?query=${Uri.encodeComponent(query)}',
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final body = json.decode(HttpOperations.decodeBody(response));

    // Support both a list response and a USDA-proxied {"foods": [...]} response
    final List<dynamic> foods;
    if (body is List) {
      foods = body;
    } else if (body is Map<String, dynamic>) {
      foods = body['foods'] as List<dynamic>? ?? [];
    } else {
      foods = [];
    }

    return foods
        .map((f) => _parseFood(f as Map<String, dynamic>))
        .where((f) => f.calories > 0)
        .toList();
  }

  static FoodDatabaseItem _parseFood(Map<String, dynamic> food) {
    // Normalized backend format
    if (food.containsKey('calories') || food.containsKey('kcal')) {
      final name = food['name'] as String? ?? 'Desconocido';
      return FoodDatabaseItem(
        name: _toTitleCase(name),
        portion: food['portion'] as String? ?? '100g',
        calories: _parseInt(food['calories'] ?? food['kcal']),
        protein: _parseInt(food['protein']),
        carbs: _parseInt(food['carbs'] ?? food['carbohydrates']),
        fat: _parseInt(food['fat']),
        category: 'API',
        isFromApi: true,
      );
    }

    // USDA proxied format
    final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];
    int calories = 0, protein = 0, carbs = 0, fat = 0;
    for (final n in nutrients) {
      final id = n['nutrientId'] as int?;
      final value = (n['value'] as num?)?.toDouble() ?? 0.0;
      switch (id) {
        case 1008: calories = value.round();
        case 1003: protein = value.round();
        case 1005: carbs = value.round();
        case 1004: fat = value.round();
      }
    }

    final rawName = food['description'] as String? ?? 'Desconocido';
    return FoodDatabaseItem(
      name: _toTitleCase(rawName),
      portion: '100g',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      category: 'API',
      isFromApi: true,
    );
  }

  static int _parseInt(dynamic v) => (v is num) ? v.round() : int.tryParse('$v') ?? 0;

  static String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s.toLowerCase().split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
