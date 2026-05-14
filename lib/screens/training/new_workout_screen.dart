import 'package:flutter/material.dart';
// Ajusta estas rutas según tu estructura de carpetas:
import 'package:fittrack_flutter/components/training/new_workout/workout_name_field.dart';
import 'package:fittrack_flutter/components/training/new_workout/exercise_header.dart';
import 'package:fittrack_flutter/components/training/new_workout/save_workout_button.dart';
import 'package:fittrack_flutter/components/training/new_workout/selected_exercise_card.dart';
import 'package:fittrack_flutter/components/training/new_workout/selected_exercise.dart';
import 'package:fittrack_flutter/components/training/new_workout/add_exercice/exercice_model.dart';
import 'package:fittrack_flutter/services/routine_service.dart';
import 'package:fittrack_flutter/components/training/new_workout/add_exercice/exercice_model.dart'; // Ajusta la ruta a donde vayas a guardar la nueva vista
import './add_exercice_screen.dart';
import './create_exercice_screen.dart';

class NewWorkoutScreen extends StatefulWidget {
  const NewWorkoutScreen({super.key});

  @override
  State<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends State<NewWorkoutScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<SelectedExercise> _selectedExercises = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExerciseScreen()),
    );

    if (result != null && result is List<Exercice>) {
      setState(() {
        for (var newExercice in result) {
          bool alreadyExists = _selectedExercises.any(
            (ex) => ex.exercice.id == newExercice.id,
          );
          if (!alreadyExists) {
            _selectedExercises.add(SelectedExercise(exercice: newExercice));
          }
        }
      });
    }
  }

  Future<void> _createExercise() async {
    final Exercice? created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateExerciceScreen()),
    );

    if (created != null) {
      setState(() {
        bool alreadyExists = _selectedExercises.any(
          (ex) => ex.exercice.id == created.id,
        );
        if (!alreadyExists) {
          _selectedExercises.add(SelectedExercise(exercice: created));
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ejercicio "${created.name}" creado y añadido'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _removeExercise(int index) =>
      setState(() => _selectedExercises.removeAt(index));

  void _incrementSets(int index) {
    setState(() {
      if (_selectedExercises[index].sets < 10) _selectedExercises[index].sets++;
    });
  }

  void _decrementSets(int index) {
    setState(() {
      if (_selectedExercises[index].sets > 1) _selectedExercises[index].sets--;
    });
  }

  bool _isSaving = false;

  Future<void> _saveWorkout() async {
    final workoutName = _nameController.text;
    if (workoutName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un nombre para la rutina'),
        ),
      );
      return;
    }

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes añadir al menos un ejercicio')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Deducir grupos musculares involucrados
    final Set<String> focuses = {};
    for (var ex in _selectedExercises) {
      focuses.add(ex.exercice.muscleGroup);
    }

    final routinePayload = {
      "name": workoutName,
      "focus": focuses.toList(),
      "exercises": _selectedExercises.map((ex) {
        return {
          "exerciseId": ex.exercice.id,
          "sets": ex.sets,
          "reps": 10, // Opcionalmente configurable en la UI en el futuro
        };
      }).toList(),
    };

    final isSuccess = await RoutineService().createRoutine(routinePayload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rutina guardada correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Volver al inicio con señal de recarga
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar la rutina'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Entrenamiento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tu componente del nombre
            WorkoutNameField(controller: _nameController),
            const SizedBox(height: 24),

            // 2. Tu componente del botón añadir
            ExerciseHeader(onAddPressed: _addExercise),
            const SizedBox(height: 8),

            // 2b. Botón para crear un ejercicio personalizado
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _createExercise,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text(
                  'Crear ejercicio personalizado',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _selectedExercises.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no has añadido ejercicios.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedExercises.length,
                      itemBuilder: (context, index) {
                        // 3. Nuestro nuevo componente para las tarjetas de ejercicios
                        return SelectedExerciseCard(
                          index: index,
                          selectedEx: _selectedExercises[index],
                          onIncrement: () => _incrementSets(index),
                          onDecrement: () => _decrementSets(index),
                          onRemove: () => _removeExercise(index),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),
            // 4. Tu componente para guardar
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : SaveWorkoutButton(onSave: _saveWorkout),
          ],
        ),
      ),
    );
  }
}
