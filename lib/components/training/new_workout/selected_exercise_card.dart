import 'package:flutter/material.dart';
import './selected_exercise.dart';

class SelectedExerciseCard extends StatelessWidget {
  final int index;
  final SelectedExercise selectedEx;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const SelectedExerciseCard({
    super.key,
    required this.index,
    required this.selectedEx,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${index + 1}', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer
            )
          ),
        ),
        title: Text(
          selectedEx.exercice.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            const Text('Series:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Theme.of(context).colorScheme.primary,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              onPressed: onDecrement,
            ),
            Text(
              '${selectedEx.sets}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Theme.of(context).colorScheme.primary,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              onPressed: onIncrement,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
