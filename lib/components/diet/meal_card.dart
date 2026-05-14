import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../utils/app_colors.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onToggleCompletion;
  final VoidCallback? onDelete;

  const MealCard({
    Key? key,
    required this.meal,
    this.onToggleCompletion,
    this.onDelete,
  }) : super(key: key);

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar comida'),
        content: Text('¿Seguro que quieres eliminar "${meal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete!();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = meal.isCompleted;
    final colors = context.colors;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isCompleted ? 0.65 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isCompleted ? 0 : 2,
        color: isCompleted ? AppColors.primaryLight.withOpacity(0.3) : colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  if (onToggleCompletion != null)
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Checkbox(
                        value: isCompleted,
                        onChanged: (_) => onToggleCompletion!(),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      meal.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? colors.textSecondary : colors.textPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: colors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${meal.totalCalories} kcal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? colors.textSecondary : AppColors.secondary,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.grey,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDelete(context),
                      tooltip: 'Eliminar comida',
                    ),
                ],
              ),
              const Divider(height: 16),
              ...meal.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: colors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.name} (${item.portion})',
                          style: TextStyle(
                            fontSize: 13,
                            color: isCompleted ? colors.textSecondary : colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${item.calories} kcal  •  ${item.protein}P ${item.carbs}C ${item.fat}G',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (meal.items.length > 1) ...[
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMacroChip('${meal.totalProtein}g P', AppColors.protein),
                    const SizedBox(width: 6),
                    _buildMacroChip('${meal.totalCarbs}g C', AppColors.carbs),
                    const SizedBox(width: 6),
                    _buildMacroChip('${meal.totalFat}g G', AppColors.fat),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
