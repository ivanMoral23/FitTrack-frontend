import './add_exercice/exercice_model.dart';

class SelectedExercise {
  final Exercice exercice;
  int sets;

  SelectedExercise({
    required this.exercice,
    this.sets = 3, // 3 series por defecto
  });
}
