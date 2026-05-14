import 'package:flutter/material.dart';
import 'package:fittrack_flutter/components/training/workouts_completed/minicomponents/stat_badge.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';
import 'package:intl/intl.dart';

class WorkoutSummaryCard extends StatelessWidget {
  final dynamic workoutData;

  const WorkoutSummaryCard({super.key, required this.workoutData});

  @override
  Widget build(BuildContext context) {
    final String name = workoutData['nombre_rutina'] ?? 'Entrenamiento';
    final int minutes = workoutData['duracion_minutos'] ?? 0;
    DateTime date = DateTime.now();
    if (workoutData['fecha'] != null) {
      date = DateTime.parse(workoutData['fecha']).toLocal();
    }
    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    final List exercises = workoutData['ejercicios_realizados'] ?? [];
    int totalSets = 0;
    for (var ex in exercises) {
      final series = ex['series'] as List? ?? [];
      totalSets += series.length;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatBadge(
                icon: Icons.timer,
                label: 'Tiempo',
                value: '$minutes min',
                baseColor: Colors.orange,
              ),
              StatBadge(
                icon: Icons.format_list_numbered,
                label: 'Series',
                value: '$totalSets',
                baseColor: Colors.green,
              ),
            ],
          ),
          if (exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(
              'Ejercicios (${exercises.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exerciseData = exercises[index]['exerciseId'];
                  if (exerciseData == null) return const SizedBox.shrink();
                  final exName = exerciseData['name'] ?? 'Ejercicio';
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        exName,
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
