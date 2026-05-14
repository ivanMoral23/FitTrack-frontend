import 'package:flutter/material.dart';
import 'package:fittrack_flutter/services/exercice_service.dart';
import 'package:fittrack_flutter/components/training/new_workout/add_exercice/exercice_model.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';

class CreateExerciceScreen extends StatefulWidget {
  const CreateExerciceScreen({super.key});

  @override
  State<CreateExerciceScreen> createState() => _CreateExerciceScreenState();
}

class _CreateExerciceScreenState extends State<CreateExerciceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();

  static const List<String> _muscleGroups = [
    'Pecho',
    'Hombro',
    'Tríceps',
    'Espalda',
    'Bíceps',
    'Pierna',
  ];

  static const Map<String, String> _difficultyOptions = {
    'easy': 'Principiante',
    'medium': 'Intermedio',
    'hard': 'Avanzado',
  };

  static const Map<String, String> _mechanicsOptions = {
    'compound': 'Compuesto',
    'isolation': 'Aislado',
  };

  static const Map<String, String> _recordTypeOptions = {
    'weight_reps': 'Peso + Repeticiones',
    'time': 'Tiempo',
    'distance': 'Distancia',
  };

  String? _selectedMuscleGroup;
  String _selectedDifficulty = 'medium';
  String _selectedMechanics = 'compound';
  String _selectedRecordType = 'weight_reps';

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final exercice = await ExerciceService().createCustomExercice(
        name: _nameController.text.trim(),
        muscleGroup: _selectedMuscleGroup!,
        difficulty: _selectedDifficulty,
        mechanics: _selectedMechanics,
        recordType: _selectedRecordType,
        instructions: _instructionsController.text,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context, exercice);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo ejercicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del ejercicio *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Grupo muscular
              DropdownButtonFormField<String>(
                value: _selectedMuscleGroup,
                decoration: const InputDecoration(
                  labelText: 'Grupo muscular *',
                  border: OutlineInputBorder(),
                ),
                items: _muscleGroups
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMuscleGroup = v),
                validator: (v) =>
                    v == null ? 'Selecciona un grupo muscular' : null,
              ),
              const SizedBox(height: 16),

              // Dificultad
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Dificultad',
                  border: OutlineInputBorder(),
                ),
                items: _difficultyOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDifficulty = v!),
              ),
              const SizedBox(height: 16),

              // Mecánica
              DropdownButtonFormField<String>(
                value: _selectedMechanics,
                decoration: const InputDecoration(
                  labelText: 'Mecánica',
                  border: OutlineInputBorder(),
                ),
                items: _mechanicsOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMechanics = v!),
              ),
              const SizedBox(height: 16),

              // Tipo de registro
              DropdownButtonFormField<String>(
                value: _selectedRecordType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de registro',
                  border: OutlineInputBorder(),
                ),
                items: _recordTypeOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRecordType = v!),
              ),
              const SizedBox(height: 16),

              // Instrucciones (opcional)
              TextField(
                controller: _instructionsController,
                maxLines: 4,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Instrucciones (opcional)',
                  hintStyle: TextStyle(color: context.colors.textMuted),
                  filled: true,
                  fillColor: context.colors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.colors.textSecondary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Crear ejercicio',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
