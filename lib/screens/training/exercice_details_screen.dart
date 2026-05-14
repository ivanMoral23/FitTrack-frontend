import 'package:flutter/material.dart';
import 'package:fittrack_flutter/components/training/new_workout/add_exercice/exercice_model.dart';

class ExerciceDetailsScreen extends StatelessWidget {
  final Exercice exercice;

  const ExerciceDetailsScreen({super.key, required this.exercice});

  static const Map<String, String> _difficultyMap = {
    'easy': 'Principiante',
    'medium': 'Intermedio',
    'hard': 'Avanzado',
  };

  static const Map<String, String> _mechanicsMap = {
    'compound': 'Compuesto',
    'isolation': 'Aislado',
  };

  static const Map<String, String> _recordTypeMap = {
    'weight_reps': 'Peso + Repes',
    'time': 'Tiempo',
    'distance': 'Distancia',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del ejercicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercice.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant ?? Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(context, Icons.fitness_center, 'Grupo muscular', exercice.muscleGroup),
                    const Divider(height: 24),
                    _buildInfoRow(context, Icons.speed, 'Dificultad', _difficultyMap[exercice.difficulty] ?? exercice.difficulty),
                    const Divider(height: 24),
                    _buildInfoRow(context, Icons.build, 'Mecánica', _mechanicsMap[exercice.mechanics] ?? exercice.mechanics),
                    const Divider(height: 24),
                    _buildInfoRow(context, Icons.timer, 'Registro', _recordTypeMap[exercice.recordType] ?? exercice.recordType),
                  ],
                ),
              ),
            ),
            if (exercice.instructions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Instrucciones',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      exercice.instructions.join('\n\n'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant ?? Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }
}
