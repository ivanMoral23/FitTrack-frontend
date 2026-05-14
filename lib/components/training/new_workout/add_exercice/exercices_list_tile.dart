import 'package:flutter/material.dart';

class ExerciseListTile extends StatelessWidget {
  final String exercise;
  final bool isSelected;
  final VoidCallback onTap;

  const ExerciseListTile({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      title: Text(
        exercise,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: Icon(
        isSelected ? Icons.cancel : Icons.add_circle,
        color: isSelected ? Colors.red.shade400 : Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap,
    );
  }
}
