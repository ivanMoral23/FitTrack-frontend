import 'package:flutter/material.dart';

class ExerciseHeader extends StatelessWidget {
  final VoidCallback onAddPressed;

  const ExerciseHeader({super.key, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    // Solo devolvemos el SizedBox con ancho infinito y el botón
    return SizedBox(
      width: double.infinity, 
      child: FilledButton.tonalIcon(
        onPressed: onAddPressed,
        icon: const Icon(Icons.add),
        label: const Text(
          'Añadir Ejercicio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
