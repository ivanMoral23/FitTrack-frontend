import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fittrack_flutter/services/workout_service.dart';
import '../../components/training/workouts_completed/exercise_tracker_card.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> routine;

  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late DateTime _startTime;
  Timer? _timer;
  String _elapsedTime = "00:00";

  // Estructura para manejar el estado de las series por cada ejercicio
  // Lista de ejercicios, donde cada ejercicio tiene una lista de series (Map)
  List<List<Map<String, dynamic>>> _exercisesTracker = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startTimer();
    _initTracker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final duration = DateTime.now().difference(_startTime);
      final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      final hours = duration.inHours;

      setState(() {
        if (hours > 0) {
          _elapsedTime = "${hours.toString().padLeft(2, '0')}:$minutes:$seconds";
        } else {
          _elapsedTime = "$minutes:$seconds";
        }
      });
    });
  }

  void _initTracker() {
    final List exercises = widget.routine['exercises'] ?? [];
    for (var ex in exercises) {
      final int sets = ex['sets'] ?? 3;
      final int targetReps = ex['reps'] ?? 10;
      
      List<Map<String, dynamic>> setTracker = [];
      for (int i = 0; i < sets; i++) {
        setTracker.add({
          "reps": targetReps,
          "peso": 0.0,
          "completado": false,
        });
      }
      _exercisesTracker.add(setTracker);
    }
  }

  Future<void> _finishWorkout() async {
    final durationInMinutes = DateTime.now().difference(_startTime).inMinutes;
    double totalVolume = 0;

    final List exercisesData = widget.routine['exercises'] ?? [];
    List<Map<String, dynamic>> payloadExercises = [];

    for (int exIndex = 0; exIndex < _exercisesTracker.length; exIndex++) {
      final originalEx = exercisesData[exIndex];
      final exTracker = _exercisesTracker[exIndex];
      
      List<Map<String, dynamic>> completedSeries = [];
      for (var set in exTracker) {
        if (set['completado'] == true) {
          final reps = set['reps'] ?? 0;
          final peso = set['peso'] ?? 0.0;
          totalVolume += (reps * peso);
          
          completedSeries.add({
            "reps": reps,
            "peso": peso,
            "tiempo": 0,
            "completado": true
          });
        }
      }

        final exIdData = originalEx['exerciseId'];
        final String exId = exIdData is Map ? (exIdData['_id'] ?? exIdData['id']) : exIdData.toString();
        
        if (completedSeries.isNotEmpty) {
          payloadExercises.add({
            "exerciseId": exId,
            "series": completedSeries
          });
        }
    }

    if (payloadExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes completar al menos una serie para guardar el entrenamiento')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final workoutPayload = {
      "nombre_rutina": widget.routine['name'] ?? 'Entrenamiento',
      "duracion_minutos": durationInMinutes,
      "volumen_total": totalVolume,
      "ejercicios_realizados": payloadExercises,
    };

    final isSuccess = await WorkoutService().createSession(workoutPayload);
    
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (isSuccess) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Entrenamiento Finalizado!'), backgroundColor: Colors.green),
      );
      // Volver a la pantalla anterior indicando éxito
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar sesión'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.routine['name'] ?? 'Entrenamiento Activo';
    final List exercises = widget.routine['exercises'] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(
              _elapsedTime, 
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.0,
              )
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.2), height: 1),
        ),
      ),
      body: exercises.isEmpty
          ? const Center(child: Text('Esta rutina no tiene ejercicios.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0).copyWith(bottom: 120),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                return ExerciseTrackerCard(
                  exerciseNode: exercises[index],
                  setsTracker: _exercisesTracker[index],
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isSaving 
          ? const CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FloatingActionButton.extended(
                  onPressed: _finishWorkout,
                  elevation: 4,
                  backgroundColor: Colors.green.shade600,
                  icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
                  label: const Text('Finalizar Entrenamiento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
    );
  }
}
