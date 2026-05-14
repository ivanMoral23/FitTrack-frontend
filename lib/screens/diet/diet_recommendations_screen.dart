import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/nutrition_service.dart';
import '../../utils/app_colors.dart';
import '../../components/diet/diet_plan_card.dart';
import 'diet_detail_screen.dart';

class DietRecommendationsScreen extends StatelessWidget {
  const DietRecommendationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Planes de Dieta',
            style: TextStyle(color: context.colors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Consumer<NutritionService>(
        builder: (context, service, _) {
          final plans = service.availableDietPlans;
          final activePlanId = service.currentDietPlan?.id;

          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book, size: 64, color: context.colors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No hay planes disponibles',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vuelve más tarde o contacta con tu entrenador.',
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final isActive = plan.id == activePlanId;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text(
                            'Plan activo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  DietPlanCard(
                    plan: plan,
                    isActive: isActive,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DietDetailScreen(dietPlan: plan),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
