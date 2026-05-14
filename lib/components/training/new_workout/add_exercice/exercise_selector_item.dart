import 'package:flutter/material.dart';
import 'package:fittrack_flutter/components/training/new_workout/add_exercice/exercice_model.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';

class ExerciseSelectorItem extends StatelessWidget {
  final Exercice exercise;
  final bool isSelected;
  final VoidCallback onToggle;

  const ExerciseSelectorItem({
    super.key,
    required this.exercise,
    this.isSelected = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder for an icon or an image based on exercise info
                  Icon(
                    _getIconForMuscle(exercise.muscleGroup),
                    size: 36,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : context.colors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exercise.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMuscle(String muscleGroup) {
    final Map<String, IconData> icons = {
      'Pecho': Icons.fitness_center,
      'Hombro': Icons.accessibility_new,
      'Tríceps': Icons.sports_gymnastics,
      'Espalda': Icons.panorama_wide_angle_select,
      'Bíceps': Icons.sports_mma,
      'Pierna': Icons.directions_run,
    };
    return icons[muscleGroup] ?? Icons.fitness_center;
  }
}
