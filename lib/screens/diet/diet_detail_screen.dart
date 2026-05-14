import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/diet_plan.dart';
import '../../services/nutrition_service.dart';
import '../../utils/app_colors.dart';
import '../../components/diet/meal_card.dart';
import '../../components/diet/section_header.dart';

class DietDetailScreen extends StatelessWidget {
  final DietPlan dietPlan;

  const DietDetailScreen({Key? key, required this.dietPlan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Detalle de Dieta', style: TextStyle(color: context.colors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        actions: [
          Consumer<NutritionService>(
            builder: (context, service, child) {
              final isCurrent = service.currentDietPlan?.id == dietPlan.id;
              if (isCurrent) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text('DIETA ACTUAL', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                tooltip: 'Seleccionar como actual',
                onPressed: () {
                  service.selectDietPlan(dietPlan.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dieta seleccionada como actual.'), backgroundColor: AppColors.success),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información general
            Text(
              dietPlan.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              dietPlan.description,
              style: TextStyle(fontSize: 16, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 16),
            
            // Chips Resumen
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('${dietPlan.totalCalories} kcal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.warning,
                ),
                Chip(
                  label: Text('${dietPlan.protein}g P', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.protein,
                ),
                Chip(
                  label: Text('${dietPlan.carbs}g C', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.carbs,
                ),
                Chip(
                  label: Text('${dietPlan.fat}g G', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.fat,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const SectionHeader(title: 'Comidas del Día'),
            
            // Listado de comidas (solo visualización)
            ...dietPlan.meals.map((meal) {
              return MealCard(
                meal: meal,
                // No se pasa onToggleCompletion porque en detalle solo vemos
                // o pasamos null
              );
            }).toList(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
