import 'package:flutter/material.dart';

class WorkoutDay extends StatefulWidget {
  final String? day;
  final bool completed;
  const WorkoutDay({super.key, this.day, this.completed = false});

  @override
  State<WorkoutDay> createState() => _WorkoutDayState();
}

class _WorkoutDayState extends State<WorkoutDay> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${widget.day}'),
          const SizedBox(height: 8),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: widget.completed ? Colors.green : Colors.grey, // Cambia el color según el estado del día
              shape: BoxShape.rectangle,
            ),
            child: widget.completed ? const Icon(Icons.check, color: Colors.white, size: 16) : null, // Icono de check
          ),
        ],
      ),
    );
  }
}
