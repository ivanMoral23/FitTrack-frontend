import 'package:flutter/material.dart';
import 'exercices_list_tile.dart';

class MuscleGroupCard extends StatelessWidget {
  final String muscle;
  final List<String> exercises;
  final Set<String> selectedExercises;
  final Function(String) onExerciseTap;

  const MuscleGroupCard({
    super.key,
    required this.muscle,
    required this.exercises,
    required this.selectedExercises,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            iconColor: Theme.of(context).colorScheme.primary,
            collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            title: Text(
              muscle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            children: exercises.map((exercise) {
              final isSelected = selectedExercises.contains(exercise);
              
              // Usamos el componente que creamos arriba
              return ExerciseListTile(
                exercise: exercise,
                isSelected: isSelected,
                onTap: () => onExerciseTap(exercise),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
