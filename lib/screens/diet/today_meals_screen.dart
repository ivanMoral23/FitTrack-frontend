import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './add_manual_meal_screen.dart';
import '../../services/nutrition_service.dart';
import '../../models/meal.dart';
import '../../utils/app_colors.dart';
import '../../components/diet/meal_card.dart';

class TodayMealsScreen extends StatelessWidget {
  const TodayMealsScreen({Key? key}) : super(key: key);

  static const _mealTypeOrder = [
    MealType.breakfast,
    MealType.lunch,
    MealType.dinner,
    MealType.snack,
  ];

  static IconData _iconForType(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.lunch:
        return Icons.sunny;
      case MealType.dinner:
        return Icons.nightlight_outlined;
      case MealType.snack:
        return Icons.local_dining;
    }
  }

  static Color _colorForType(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return const Color(0xFFFF9800);
      case MealType.lunch:
        return const Color(0xFF4CAF50);
      case MealType.dinner:
        return const Color(0xFF5C6BC0);
      case MealType.snack:
        return const Color(0xFF26C6DA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Mis Comidas de Hoy',
            style: TextStyle(color: context.colors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Consumer<NutritionService>(
        builder: (context, service, _) {
          final meals = service.todayMeals;

          if (meals.isEmpty) {
            return _buildEmptyState(context);
          }

          final profile = service.userProfile;

          // Group meals by type in display order
          final grouped = <MealType, List<Meal>>{};
          for (final type in _mealTypeOrder) {
            final group = meals.where((m) => m.mealType == type).toList();
            if (group.isNotEmpty) grouped[type] = group;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, service, profile),
                const SizedBox(height: 20),
                ...grouped.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeHeader(context, entry.key, entry.value),
                    const SizedBox(height: 8),
                    ...entry.value.map((meal) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MealCard(
                        meal: meal,
                        onToggleCompletion: () =>
                            service.toggleMealCompletion(meal.id),
                        onDelete: () => service.removeMeal(meal.id),
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddManualMealScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Añadir comida',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, NutritionService service, profile) {
    final consumed = service.consumedCalories;
    final target = profile.targetCalories;
    final remaining = target - consumed;
    final calPct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    final Color calColor;
    if (consumed > target) {
      calColor = AppColors.error;
    } else if (calPct >= 0.8) {
      calColor = AppColors.warning;
    } else {
      calColor = AppColors.primary;
    }

    final completed = service.completedMealsCount;
    final total = service.todayMeals.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen del día',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completed / $total comidas',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Calories section
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$consumed',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: calColor),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/ $target kcal',
                  style: TextStyle(
                      fontSize: 14, color: context.colors.textSecondary),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remaining >= 0
                        ? '$remaining kcal'
                        : '${remaining.abs()} kcal',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: remaining >= 0
                            ? context.colors.textSecondary
                            : AppColors.error),
                  ),
                  Text(
                    remaining >= 0 ? 'restantes' : 'superadas',
                    style: TextStyle(
                        fontSize: 11, color: context.colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: calPct,
              backgroundColor: calColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(calColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Macro bars
          _buildMacroBar(context, 'Proteína', service.consumedProtein,
              profile.targetProtein, AppColors.protein),
          const SizedBox(height: 10),
          _buildMacroBar(context, 'Carbohidratos', service.consumedCarbs,
              profile.targetCarbs, AppColors.carbs),
          const SizedBox(height: 10),
          _buildMacroBar(context,
              'Grasa', service.consumedFat, profile.targetFat, AppColors.fat),
        ],
      ),
    );
  }

  Widget _buildMacroBar(
      BuildContext context, String label, int consumed, int target, Color color) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final over = consumed > target;
    final barColor = over ? AppColors.error : color;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, color: context.colors.textSecondary)),
            ),
            Text(
              '${consumed}g',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: barColor),
            ),
            Text(
              ' / ${target}g',
              style: TextStyle(
                  fontSize: 12, color: context.colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeHeader(BuildContext context, MealType type, List<Meal> meals) {
    final totalCal = meals.fold(0, (s, m) => s + m.totalCalories);
    final completedCal = meals
        .where((m) => m.isCompleted)
        .fold(0, (s, m) => s + m.totalCalories);
    final color = _colorForType(type);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_iconForType(type), color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          type.displayName,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary),
        ),
        const Spacer(),
        Text(
          completedCal > 0
              ? '$completedCal / $totalCal kcal'
              : '$totalCal kcal',
          style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_meals, size: 72, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No hay comidas para hoy',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona un plan de dieta en "Recomendaciones" o añade una comida manualmente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddManualMealScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Añadir comida manual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
