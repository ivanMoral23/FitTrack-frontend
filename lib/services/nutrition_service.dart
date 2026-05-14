import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart';
import 'package:fittrack_flutter/services/auth_service.dart';
import '../models/nutrition_profile.dart';
import '../models/diet_plan.dart';
import '../models/meal.dart';
import '../models/daily_record.dart';
import '../data/mock_nutrition_data.dart';
import '../utils/nutrition_calculator.dart';

class NutritionService extends ChangeNotifier {
  final HttpOperations _http = HttpOperations();
  final AuthService _authService = AuthService();

  static const String _profileKey = 'user_nutrition_profile_local';

  late NutritionProfile _userProfile;
  List<DietPlan> _availableDietPlans = [];
  DietPlan? _currentDietPlan;
  List<Meal> _activeDayMeals = [];
  List<DailyRecord> _history = [];

  bool _isLoading = false;
  bool _prefsLoaded = false;
  bool _profileSetupCompleted = false;
  String? _errorMessage;

  NutritionProfile get userProfile => _userProfile;
  List<DietPlan> get availableDietPlans => _availableDietPlans;
  DietPlan? get currentDietPlan => _currentDietPlan;
  List<Meal> get todayMeals => List.unmodifiable(_activeDayMeals);
  List<DailyRecord> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get prefsLoaded => _prefsLoaded;
  bool get profileSetupCompleted => _profileSetupCompleted;
  String? get errorMessage => _errorMessage;

  NutritionService() {
    _initService();
    _initAsync();
  }

  void _initService() {
    _userProfile = MockNutritionData.currentUser;
    _availableDietPlans = MockNutritionData.dietPlans;
    _currentDietPlan = _availableDietPlans.firstWhere(
      (p) => p.isRecommended,
      orElse: () => _availableDietPlans.first,
    );
    _activeDayMeals = List.from(_currentDietPlan!.meals);
    recalculateProfile();
  }

  Future<void> _initAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profileSetupCompleted =
          prefs.getBool('nutrition_onboarding_done') ?? false;

      // Restore previously saved local profile (all fields)
      final profileJson = prefs.getString(_profileKey);
      if (profileJson != null) {
        final map = jsonDecode(profileJson) as Map<String, dynamic>;
        _userProfile = _userProfile.copyWith(
          weight: (map['weight'] as num?)?.toDouble(),
          height: (map['height'] as num?)?.toDouble(),
          age: (map['age'] as num?)?.toInt(),
          gender: _parseGender(map['gender'] as String?),
          activityLevel: _parseActivityLevel(map['activityLevel'] as String?),
          goal: _parseGoal(map['goal'] as String?),
          preference: _parsePreference(map['preference'] as String?),
          mealsPerDay: map['mealsPerDay'] as int?,
        );
        recalculateProfile();
      }

      final historyJson = prefs.getString('nutrition_history');
      if (historyJson != null) {
        final list = jsonDecode(historyJson) as List<dynamic>;
        _history = list
            .map((e) => DailyRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Fetch real physical data (weight, height, age) from backend
      await _fetchUserProfileFromApi();
    } catch (e) {
      debugPrint('NutritionService._initAsync error: $e');
    } finally {
      _prefsLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfileFromApi() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await _http.getRequest('auth/profile', token: token);
      if (response.statusCode == 200) {
        final data =
            jsonDecode(HttpOperations.decodeBody(response)) as Map<String, dynamic>;
        final apiWeight = (data['weight'] as num?)?.toDouble();
        final apiHeight = (data['height'] as num?)?.toDouble();
        final apiAge = (data['age'] as num?)?.toInt();

        if (apiWeight != null || apiHeight != null || apiAge != null) {
          _userProfile = _userProfile.copyWith(
            weight: apiWeight,
            height: apiHeight,
            age: apiAge,
          );
          recalculateProfile();
        }
      }
    } catch (e) {
      debugPrint('NutritionService._fetchUserProfileFromApi error: $e');
    }
  }

  Future<void> _saveProfileLocally(NutritionProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _profileKey,
        jsonEncode({
          'weight': profile.weight,
          'height': profile.height,
          'age': profile.age,
          'gender': profile.gender.name,
          'activityLevel': profile.activityLevel.name,
          'goal': profile.goal.name,
          'preference': profile.preference.name,
          'mealsPerDay': profile.mealsPerDay,
        }),
      );
    } catch (e) {
      debugPrint('NutritionService._saveProfileLocally error: $e');
    }
  }

  Gender _parseGender(String? s) {
    switch (s) {
      case 'male': return Gender.male;
      case 'female': return Gender.female;
      default: return Gender.other;
    }
  }

  ActivityLevel _parseActivityLevel(String? s) {
    switch (s) {
      case 'sedentary': return ActivityLevel.sedentary;
      case 'light': return ActivityLevel.light;
      case 'moderate': return ActivityLevel.moderate;
      case 'active': return ActivityLevel.active;
      case 'veryActive': return ActivityLevel.veryActive;
      default: return ActivityLevel.moderate;
    }
  }

  Goal _parseGoal(String? s) {
    switch (s) {
      case 'loseFat': return Goal.loseFat;
      case 'maintain': return Goal.maintain;
      default: return Goal.buildMuscle;
    }
  }

  DietaryPreference _parsePreference(String? s) {
    switch (s) {
      case 'highProtein': return DietaryPreference.highProtein;
      case 'vegetarian': return DietaryPreference.vegetarian;
      case 'lowCarb': return DietaryPreference.lowCarb;
      default: return DietaryPreference.standard;
    }
  }

  Future<void> markOnboardingDone() async {
    _profileSetupCompleted = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nutrition_onboarding_done', true);
    } catch (e) {
      debugPrint('markOnboardingDone error: $e');
    }
  }

  Future<void> saveTodayRecord() async {
    final today = _todayDateString();
    final record = DailyRecord(
      date: today,
      consumedCalories: consumedCalories,
      consumedProtein: consumedProtein,
      consumedCarbs: consumedCarbs,
      consumedFat: consumedFat,
      targetCalories: _userProfile.targetCalories,
      targetProtein: _userProfile.targetProtein,
      targetCarbs: _userProfile.targetCarbs,
      targetFat: _userProfile.targetFat,
    );

    final idx = _history.indexWhere((r) => r.date == today);
    if (idx >= 0) {
      _history[idx] = record;
    } else {
      _history = [..._history, record];
    }
    if (_history.length > 90) {
      _history = _history.sublist(_history.length - 90);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_history.map((r) => r.toJson()).toList());
      await prefs.setString('nutrition_history', json);
    } catch (e) {
      debugPrint('saveTodayRecord error: $e');
    }
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  DailyRecord? getRecordForDate(String date) {
    try {
      return _history.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  List<DailyRecord> getRecordsForWeek(DateTime weekStart) {
    final dates = List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    });
    return _history.where((r) => dates.contains(r.date)).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateUserProfile(NutritionProfile updatedProfile) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      String? token = await _authService.getToken();
      if (token == null) throw Exception('No session');

      // Solo enviamos los datos físicos que tenemos en NutritionProfile
      final body = {
        'weight': updatedProfile.weight,
        'height': updatedProfile.height,
        'age': updatedProfile.age,
      };

      final response = await _http.putRequest('auth/update-profile', body, token: token);

      if (response.statusCode == 200) {
        _userProfile = updatedProfile;
        recalculateProfile();
        _saveProfileLocally(_userProfile);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'No se pudo sincronizar. Datos guardados localmente.';
      _userProfile = updatedProfile;
      recalculateProfile();
      _saveProfileLocally(_userProfile);
    } finally {
      _setLoading(false);
    }
  }

  void recalculateProfile() {
    final maintenance = NutritionCalculator.calculateMaintenanceCalories(
      weight: _userProfile.weight,
      height: _userProfile.height,
      age: _userProfile.age,
      gender: _userProfile.gender,
      activityLevel: _userProfile.activityLevel,
    );

    final target = NutritionCalculator.calculateTargetCalories(
      maintenance,
      _userProfile.goal,
    );

    final macros = NutritionCalculator.calculateMacros(
      target,
      _userProfile.weight,
      _userProfile.preference,
    );

    _userProfile = _userProfile.copyWith(
      targetCalories: target,
      targetProtein: macros['protein']!,
      targetFat: macros['fat']!,
      targetCarbs: macros['carbs']!,
    );

    notifyListeners();
  }

  Future<void> selectDietPlan(String planId) async {
    _setLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentDietPlan = _availableDietPlans.firstWhere((p) => p.id == planId);
      _activeDayMeals = List.from(_currentDietPlan!.meals);
    } catch (e) {
      _errorMessage = 'No se pudo seleccionar el plan.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleMealCompletion(String mealId) async {
    final index = _activeDayMeals.indexWhere((m) => m.id == mealId);
    if (index == -1) return;

    final meal = _activeDayMeals[index];
    _activeDayMeals[index] = meal.copyWith(isCompleted: !meal.isCompleted);
    notifyListeners();
    saveTodayRecord();
  }

  void addCustomMeal(Meal meal) {
    _activeDayMeals = [..._activeDayMeals, meal];
    notifyListeners();
    saveTodayRecord();
  }

  void removeMeal(String mealId) {
    _activeDayMeals = _activeDayMeals.where((m) => m.id != mealId).toList();
    notifyListeners();
    saveTodayRecord();
  }

  int get consumedCalories =>
      todayMeals.where((m) => m.isCompleted).fold(0, (s, m) => s + m.totalCalories);

  int get consumedProtein =>
      todayMeals.where((m) => m.isCompleted).fold(0, (s, m) => s + m.totalProtein);

  int get consumedCarbs =>
      todayMeals.where((m) => m.isCompleted).fold(0, (s, m) => s + m.totalCarbs);

  int get consumedFat =>
      todayMeals.where((m) => m.isCompleted).fold(0, (s, m) => s + m.totalFat);

  int get completedMealsCount => todayMeals.where((m) => m.isCompleted).length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
