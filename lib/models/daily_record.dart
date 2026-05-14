class DailyRecord {
  final String date; // 'yyyy-MM-dd'
  final int consumedCalories;
  final int consumedProtein;
  final int consumedCarbs;
  final int consumedFat;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;

  const DailyRecord({
    required this.date,
    required this.consumedCalories,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFat,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
  });

  double get calorieAdherence =>
      targetCalories > 0 ? consumedCalories / targetCalories : 0.0;

  Map<String, dynamic> toJson() => {
    'date': date,
    'consumedCalories': consumedCalories,
    'consumedProtein': consumedProtein,
    'consumedCarbs': consumedCarbs,
    'consumedFat': consumedFat,
    'targetCalories': targetCalories,
    'targetProtein': targetProtein,
    'targetCarbs': targetCarbs,
    'targetFat': targetFat,
  };

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
    date: json['date'] as String,
    consumedCalories: (json['consumedCalories'] as num).toInt(),
    consumedProtein: (json['consumedProtein'] as num).toInt(),
    consumedCarbs: (json['consumedCarbs'] as num).toInt(),
    consumedFat: (json['consumedFat'] as num).toInt(),
    targetCalories: (json['targetCalories'] as num).toInt(),
    targetProtein: (json['targetProtein'] as num).toInt(),
    targetCarbs: (json['targetCarbs'] as num).toInt(),
    targetFat: (json['targetFat'] as num).toInt(),
  );
}
