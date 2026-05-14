import 'package:flutter/material.dart';
import 'package:fittrack_flutter/components/training/workouts_completed/workout_summary_card.dart';
import 'package:fittrack_flutter/services/workout_service.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';

class WorkoutsCompleted extends StatefulWidget {
  final bool nested; // when true, the widget will shrinkWrap and not provide its own scrolling
  const WorkoutsCompleted({super.key, this.nested = false});

  @override
  State<WorkoutsCompleted> createState() => _WorkoutsCompletedState();
}

class _WorkoutsCompletedState extends State<WorkoutsCompleted> {
  final WorkoutService _workoutService = WorkoutService();
  late final Future<List<dynamic>> _workoutsFuture = _workoutService.getMySessions();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _workoutsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error al cargar los entrenamientos",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final workouts = snapshot.data ?? [];
        if (workouts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.fitness_center, size: 48, color: context.colors.textMuted),
                const SizedBox(height: 16),
                Text(
                  'Aún no has registrado entrenamientos.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
            ),
          );
        }

        // Sort by date descending
        workouts.sort((a, b) {
          if (a['fecha'] == null || b['fecha'] == null) return 0;
          return DateTime.parse(
            b['fecha'],
          ).compareTo(DateTime.parse(a['fecha']));
        });

        final recentWorkouts = workouts.take(90).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Text(
                'Historial de Entrenamientos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recentWorkouts.length,
              itemBuilder: (context, index) {
                return WorkoutSummaryCard(workoutData: recentWorkouts[index]);
              },
            ),
          ],
        );
      },
    );
  }
}
