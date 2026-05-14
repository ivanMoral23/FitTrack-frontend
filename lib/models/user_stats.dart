/// Modelo que encapsula las estadísticas físicas y digitales del usuario
/// y el cálculo del Gravity Index.
class UserStats {
  final int steps;
  final double sleepHours;
  final int screenTimeMinutes;
  final double gravityIndex;
  final String dailyInsight;

  /// Calorías activas quemadas hoy (kcal), obtenidas de Health Connect.
  final int caloriesBurned;

  /// Frecuencia cardíaca en reposo media (bpm), obtenida de Health Connect.
  final int heartRate;

  /// Minutos activos hoy (minutos de actividad física moderada+).
  final int activeMinutes;

  /// Consumo de agua hoy (ml) — seguimiento manual.
  final int waterMl;

  const UserStats({
    required this.steps,
    required this.sleepHours,
    required this.screenTimeMinutes,
    required this.gravityIndex,
    this.dailyInsight = '',
    this.caloriesBurned = 0,
    this.heartRate = 0,
    this.activeMinutes = 0,
    this.waterMl = 0,
  });

  // ---------------------------------------------------------------------------
  // Gravity Index Formula
  // ---------------------------------------------------------------------------
  // Base: 50 puntos
  // +steps/200   → máx +30 (6 000 pasos = +30)
  // +sleepHours*3 → máx +21 (7 h = +21)
  // -screenTimeMinutes/30 → máx -20 (10 h = -20)
  // Resultado acotado en [0, 100]
  // ---------------------------------------------------------------------------
  static double computeGravityIndex({
    required int steps,
    required double sleepHours,
    required int screenTimeMinutes,
  }) {
    double score = 50.0;
    score += (steps / 200).clamp(0, 30);
    score += (sleepHours * 3).clamp(0, 21);
    score -= (screenTimeMinutes / 30).clamp(0, 20);
    return score.clamp(0, 100);
  }

  factory UserStats.withComputed({
    required int steps,
    required double sleepHours,
    required int screenTimeMinutes,
    String dailyInsight = '',
    int caloriesBurned = 0,
    int heartRate = 0,
    int activeMinutes = 0,
    int waterMl = 0,
  }) {
    return UserStats(
      steps: steps,
      sleepHours: sleepHours,
      screenTimeMinutes: screenTimeMinutes,
      gravityIndex: computeGravityIndex(
        steps: steps,
        sleepHours: sleepHours,
        screenTimeMinutes: screenTimeMinutes,
      ),
      dailyInsight: dailyInsight,
      caloriesBurned: caloriesBurned,
      heartRate: heartRate,
      activeMinutes: activeMinutes,
      waterMl: waterMl,
    );
  }

  UserStats copyWith({
    String? dailyInsight,
    int? caloriesBurned,
    int? heartRate,
    int? activeMinutes,
    int? waterMl,
  }) {
    return UserStats(
      steps: steps,
      sleepHours: sleepHours,
      screenTimeMinutes: screenTimeMinutes,
      gravityIndex: gravityIndex,
      dailyInsight: dailyInsight ?? this.dailyInsight,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      heartRate: heartRate ?? this.heartRate,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      waterMl: waterMl ?? this.waterMl,
    );
  }

  Map<String, dynamic> toJson() => {
        'steps': steps,
        'sleep_hours': sleepHours,
        'screen_time_minutes': screenTimeMinutes,
        'gravity_index': gravityIndex,
        'calories_burned': caloriesBurned,
        'heart_rate': heartRate,
        'active_minutes': activeMinutes,
      };

  /// Instancia vacía utilizada mientras se cargan los datos de salud.
  static UserStats zero() => UserStats.withComputed(
        steps: 0,
        sleepHours: 0,
        screenTimeMinutes: 0,
        caloriesBurned: 0,
        heartRate: 0,
        activeMinutes: 0,
        waterMl: 0,
      );
}
