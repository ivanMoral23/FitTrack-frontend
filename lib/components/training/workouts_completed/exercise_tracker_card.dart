import 'package:flutter/material.dart';
import 'set_tracker_row.dart';

class ExerciseTrackerCard extends StatefulWidget {
  final Map<String, dynamic> exerciseNode;
  final List<Map<String, dynamic>> setsTracker;

  const ExerciseTrackerCard({
    super.key,
    required this.exerciseNode,
    required this.setsTracker,
  });

  @override
  State<ExerciseTrackerCard> createState() => _ExerciseTrackerCardState();
}

class _ExerciseTrackerCardState extends State<ExerciseTrackerCard> {
  @override
  Widget build(BuildContext context) {
    final exModel = widget.exerciseNode['exerciseId'];
    final name = exModel != null && exModel is Map ? exModel['name'] : 'Ejercicio';

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del ejercicio
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
            // Títulos de cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32, child: Text('SET', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                const SizedBox(width: 12),
                const Expanded(child: Text('KG', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                const SizedBox(width: 12),
                const Expanded(child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                const SizedBox(width: 12),
                const SizedBox(width: 44, child: Icon(Icons.check, size: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            // Lista de series
            ...List.generate(widget.setsTracker.length, (setIndex) {
              final set = widget.setsTracker[setIndex];
              return SetTrackerRow(
                setIndex: setIndex,
                reps: set['reps'] ?? 0,
                weight: set['peso'] ?? 0.0,
                isCompleted: set['completado'] ?? false,
                onRepsChanged: (val) {
                  set['reps'] = val;
                },
                onWeightChanged: (val) {
                  set['peso'] = val;
                },
                onCompletionToggled: (val) {
                  setState(() {
                    set['completado'] = val;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
