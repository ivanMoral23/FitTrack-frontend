import 'dart:convert';

import 'package:health/health.dart';
import 'package:fittrack_flutter/models/user_stats.dart';
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart';
import 'package:fittrack_flutter/services/auth_service.dart';

/// Ponlo en [true] para desarrollar sin dispositivo/permisos reales.
const bool kUseMockData = false;

// ---------------------------------------------------------------------------
// Mock data — valores de ejemplo para testing
// ---------------------------------------------------------------------------
const _mockSteps              = 7500;
const _mockSleepHours         = 6.5;
const _mockScreenTimeMinutes  = 180;
const _mockCaloriesBurned     = 420;
const _mockHeartRate          = 68;
const _mockActiveMinutes      = 35;

/// Servicio que agrega pasos, sueño, calorías y FC del usuario desde
/// Health Connect (Android) / HealthKit (iOS), calcula el Gravity Index
/// y sincroniza con el backend para obtener el daily_insight.
class UserStatsService {
  final AuthService _authService = AuthService();
  final HttpOperations _http = HttpOperations();

  static const List<HealthDataType> _healthTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
    HealthDataType.WATER,
  ];

  // --------------------------------------------------------------------------
  // Punto de entrada principal
  // --------------------------------------------------------------------------

  Future<UserStats> fetchStats() async {
    if (kUseMockData) {
      return _buildStats(
        steps: _mockSteps,
        sleepHours: _mockSleepHours,
        screenTimeMinutes: _mockScreenTimeMinutes,
        caloriesBurned: _mockCaloriesBurned,
        heartRate: _mockHeartRate,
        activeMinutes: _mockActiveMinutes,
        waterMl: 0,
      );
    }

    final health = Health();

    // Necesario inicializar el plugin antes de usarlo (health ^12).
    await health.configure();

    // Solicita permisos; si se deniegan para algún tipo, continuamos con 0.
    // No lanzamos excepción si los permisos son parciales.
    try {
      await health.requestAuthorization(_healthTypes);
    } catch (_) {
      // Si falla el diálogo de permisos (Health Connect no instalado, etc.)
      // intentamos leer igualmente con lo que esté disponible.
    }

    // Leer cada métrica de forma independiente para que un fallo parcial
    // no cancele el resto.
    final steps      = await _safeInt(() => _fetchSteps(health));
    final sleep      = await _safeDouble(() => _fetchSleepHours(health));
    final calories   = await _safeInt(() => _fetchCalories(health));
    final hr         = await _safeInt(() => _fetchHeartRate(health));
    final activeMins = await _safeInt(() => _fetchActiveMinutes(health, calories));
    final water      = await _safeInt(() => _fetchWaterMl(health));

    return _buildStats(
      steps: steps,
      sleepHours: sleep,
      screenTimeMinutes: 0,
      caloriesBurned: calories,
      heartRate: hr,
      activeMinutes: activeMins,
      waterMl: water,
    );
  }

  // --------------------------------------------------------------------------
  // Sincronización con backend
  // --------------------------------------------------------------------------

  Future<UserStats> syncWithBackend(UserStats stats) async {
    final token = await _authService.getToken();
    final response = await _http.postRequest(
      'api/v1/sync-stats',
      stats.toJson(),
      token: token,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(HttpOperations.decodeBody(response)) as Map<String, dynamic>;
      final insight = body['daily_insight'] as String? ?? '';
      return stats.copyWith(dailyInsight: insight);
    }
    throw Exception('Backend respondió con código ${response.statusCode}');
  }

  // --------------------------------------------------------------------------
  // Helpers privados — lectura de cada tipo
  // --------------------------------------------------------------------------

  /// Usa el método dedicado de health:^12 para obtener pasos del día.
  Future<int> _fetchSteps(Health health) async {
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final steps    = await health.getTotalStepsInInterval(midnight, now);
    return steps ?? 0;
  }

  /// Calcula horas de sueño de las últimas 24h usando dateFrom/dateTo
  /// (más fiable que numericValue que varía según plataforma).
  Future<double> _fetchSleepHours(Health health) async {
    final now       = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    final points    = await health.getHealthDataFromTypes(
      startTime: yesterday,
      endTime: now,
      types: [HealthDataType.SLEEP_SESSION],
    );
    if (points.isEmpty) return 0;
    final totalMs = points.fold<int>(
      0,
      (s, p) => s + p.dateTo.difference(p.dateFrom).inMilliseconds,
    );
    return totalMs / 3600000; // ms → horas
  }

  /// Devuelve las kcal activas quemadas hoy.
  /// Intenta primero ACTIVE_ENERGY_BURNED (solo actividad), y si está vacío
  /// usa TOTAL_CALORIES_BURNED (activas + basales) que Google Fit rellena siempre.
  Future<int> _fetchCalories(Health health) async {
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final active = await health.getHealthDataFromTypes(
      startTime: midnight,
      endTime: now,
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
    );
    if (active.isNotEmpty) {
      final total = active.fold<double>(0, (s, p) => s + _numericValue(p));
      if (total > 0) return total.round();
    }

    // Fallback: calorias totales (activas + basales).
    final total = await health.getHealthDataFromTypes(
      startTime: midnight,
      endTime: now,
      types: [HealthDataType.TOTAL_CALORIES_BURNED],
    );
    return total.fold<double>(0, (s, p) => s + _numericValue(p)).round();
  }

  Future<int> _fetchHeartRate(Health health) async {
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final points   = await health.getHealthDataFromTypes(
      startTime: midnight,
      endTime: now,
      types: [HealthDataType.HEART_RATE],
    );
    if (points.isEmpty) return 0;
    final sum = points.fold<double>(0, (s, p) => s + _numericValue(p));
    return (sum / points.length).round();
  }

  /// Lee los minutos activos del día sumando la duración de las sesiones de
  /// ejercicio registradas en Health Connect (WORKOUT), igual que se calcula
  /// el sueño a partir de SLEEP_SESSION.
  /// EXERCISE_TIME no existe en Android/Health Connect — es exclusivo de iOS.
  Future<int> _fetchActiveMinutes(Health health, int caloriesAlreadyFetched) async {
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final points   = await health.getHealthDataFromTypes(
      startTime: midnight,
      endTime: now,
      types: [HealthDataType.WORKOUT],
    );
    if (points.isNotEmpty) {
      final totalMs = points.fold<int>(
        0,
        (s, p) => s + p.dateTo.difference(p.dateFrom).inMilliseconds,
      );
      return (totalMs / 60000).round().clamp(0, 1440); // ms → minutos
    }
    // Fallback: estimar a partir de calorías si no hay sesiones de ejercicio.
    final kcal = caloriesAlreadyFetched > 0
        ? caloriesAlreadyFetched
        : await _fetchCalories(health);
    return (kcal / 5).round().clamp(0, 480);
  }

  /// Agua ingerida hoy en ml. El tipo WATER almacena litros → multiplicamos × 1000.
  Future<int> _fetchWaterMl(Health health) async {
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final points   = await health.getHealthDataFromTypes(
      startTime: midnight,
      endTime: now,
      types: [HealthDataType.WATER],
    );
    if (points.isEmpty) return 0;
    final liters = points.fold<double>(0, (s, p) => s + _numericValue(p));
    return (liters * 1000).round();
  }

  /// Extrae el valor numérico de un [HealthDataPoint] de forma segura.
  /// Evita el cast directo a [NumericHealthValue] que puede fallar en
  /// algunas versiones del plugin o plataformas.
  double _numericValue(HealthDataPoint p) {
    final val = p.value;
    if (val is NumericHealthValue) return val.numericValue.toDouble();
    return 0.0;
  }

  // --------------------------------------------------------------------------
  // Utilidades
  // --------------------------------------------------------------------------

  UserStats _buildStats({
    required int steps,
    required double sleepHours,
    required int screenTimeMinutes,
    required int caloriesBurned,
    required int heartRate,
    required int activeMinutes,
    required int waterMl,
  }) {
    return UserStats.withComputed(
      steps: steps,
      sleepHours: sleepHours,
      screenTimeMinutes: screenTimeMinutes,
      caloriesBurned: caloriesBurned,
      heartRate: heartRate,
      activeMinutes: activeMinutes,
      waterMl: waterMl,
    );
  }

  UserStats _mockStats() => _buildStats(
        steps: _mockSteps,
        sleepHours: _mockSleepHours,
        screenTimeMinutes: _mockScreenTimeMinutes,
        caloriesBurned: _mockCaloriesBurned,
        heartRate: _mockHeartRate,
        activeMinutes: _mockActiveMinutes,
        waterMl: 0,
      );

  /// Ejecuta [fn] y devuelve 0 si lanza alguna excepción (permisos denegados, etc.).
  Future<int> _safeInt(Future<int> Function() fn) async {
    try { return await fn(); } catch (_) { return 0; }
  }

  Future<double> _safeDouble(Future<double> Function() fn) async {
    try { return await fn(); } catch (_) { return 0; }
  }
}

