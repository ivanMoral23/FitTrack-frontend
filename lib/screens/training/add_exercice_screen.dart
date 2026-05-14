import 'package:flutter/material.dart';
// Ajusta estas rutas a tu proyecto
import 'package:fittrack_flutter/components/training/new_workout/add_exercice/confirm_selection_fab.dart';
import 'package:fittrack_flutter/components/training/new_workout/add_exercice/exercice_model.dart';
import 'package:fittrack_flutter/screens/training/exercice_details_screen.dart';
import 'package:fittrack_flutter/services/auth_service.dart';
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart';

import 'dart:convert';

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});
  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  // 1. Iniciamos los músculos con valor "null".
  // Null significa "aún no he hecho la petición a Node.js".
  final Map<String, List<Exercice>?> _exercisesByMuscle = {
    'Pecho': null,
    'Hombro': null,
    'Tríceps': null,
    'Espalda': null,
    'Bíceps': null,
    'Pierna': null,
  };

  final Map<String, Exercice> _selectedExercises = {};

  // Filters state
  String? _filterDifficulty;
  String? _filterMechanics;
  String? _filterPattern;
  String? _filterEquipment;

  int get _activeFiltersCount {
    int c = 0;
    if (_filterDifficulty != null) c++;
    if (_filterMechanics != null) c++;
    if (_filterPattern != null) c++;
    if (_filterEquipment != null) c++;
    return c;
  }

  List<Exercice> _applyFilters(List<Exercice> list) {
    return list.where((ex) {
      if (_filterDifficulty != null && ex.difficulty != _filterDifficulty) return false;
      if (_filterMechanics != null && ex.mechanics != _filterMechanics) return false;
      if (_filterPattern != null && ex.movementPattern != _filterPattern) return false;
      if (_filterEquipment != null && !ex.equipment.contains(_filterEquipment)) return false;
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _filterDifficulty = null;
      _filterMechanics = null;
      _filterPattern = null;
      _filterEquipment = null;
    });
  }
  // Ya no necesitamos un loading global, cargará cada músculo por separado.

  // 2. Esta es la función que llama a tu controlador getByMuscleGroup
  Future<void> _fetchMuscleGroup(String muscle) async {
    // Si ya tiene datos (no es null), no hacemos la petición de nuevo
    if (_exercisesByMuscle[muscle] != null) return;

    try {
      // Ajusta la URL a la ruta real de tu backend.
      // Por ejemplo: /api/exercices/grupo/Pecho
      String? token = await AuthService().getToken();
      final response = await HttpOperations().getRequest(
        'exercices/getByMuscleGroup/$muscle',
        token: token,
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(HttpOperations.decodeBody(response));
        final List<dynamic> exercisesList = decodedData['exercices'];

        // Mapeamos el JSON a nuestra clase Dart
        final List<Exercice> fetchedExercises = exercisesList
            .map((item) => Exercice.fromJson(item))
            .toList();

        if (mounted) {
          setState(() {
            _exercisesByMuscle[muscle] = fetchedExercises;
          });
        }
      } else {
        throw Exception('Error al cargar $muscle');
      }
    } catch (e) {
      print('Error en la petición de $muscle: $e');
      _showSnackBar('Error al cargar ejercicios de $muscle', isAdded: false);
      // Podrías poner una lista vacía para que no se quede cargando infinitamente
      if (mounted) setState(() => _exercisesByMuscle[muscle] = []);
    }
  }

  void _toggleExercise(Exercice exercise) {
    setState(() {
      if (_selectedExercises.containsKey(exercise.id)) {
        _selectedExercises.remove(exercise.id);
        _showSnackBar('Ejercicio eliminado', isAdded: false);
      } else {
        _selectedExercises[exercise.id] = exercise;
        _showSnackBar('Ejercicio añadido', isAdded: true);
      }
    });
  }

  void _showSnackBar(String message, {required bool isAdded}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isAdded ? Colors.green.shade600 : Colors.red.shade400,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget _buildDropdown(String label, String? value, List<String> items, Map<String, String> labels, Function(String?) onChanged) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  ),
                  value: value,
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Cualquiera")),
                    ...items.map((e) => DropdownMenuItem(value: e, child: Text(labels[e] ?? e)))
                  ],
                  onChanged: (val) {
                    setModalState(() => onChanged(val));
                    setState(() => onChanged(val));
                  },
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtros Avanzados', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (_activeFiltersCount > 0)
                        TextButton(
                          onPressed: () {
                            setModalState(() => _clearFilters());
                            setState(() => _clearFilters());
                          },
                          child: const Text("Limpiar"),
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown("Dificultad", _filterDifficulty, ['easy', 'medium', 'hard'], 
                    {'easy':'Principiante', 'medium':'Intermedio', 'hard':'Avanzado'}, (val) => _filterDifficulty = val),
                  _buildDropdown("Mecánica", _filterMechanics, ['compound', 'isolation'], 
                    {'compound':'Compuesto', 'isolation':'Aislado'}, (val) => _filterMechanics = val),
                  _buildDropdown("Patrón de Movimiento", _filterPattern, 
                    ['horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull', 'squat', 'hinge', 'lunge', 'isolation_curl', 'isolation_extension', 'core_stability', 'dynamic', 'other'], 
                    {
                      'horizontal_push':'Empuje Horizontal', 'vertical_push':'Empuje Vertical', 
                      'horizontal_pull':'Tracción Horizontal', 'vertical_pull':'Tracción Vertical', 
                      'squat':'Sentadilla/Rodilla', 'hinge':'Bisagra/Cadera', 'lunge':'Zancada', 
                      'isolation_curl':'Flexión Aislada (Curl)', 'isolation_extension':'Extensión Aislada',
                      'core_stability':'Estabilidad Core', 'dynamic':'Dinámico', 'other':'Otro'
                    }, (val) => _filterPattern = val),
                  _buildDropdown("Equipamiento", _filterEquipment, 
                    ['Barra', 'Mancuernas', 'Polea', 'Máquina', 'Peso Corporal', 'Barra EZ', 'Banco', 'Barra de dominadas'], 
                    {
                      'Barra':'Barra', 'Mancuernas':'Mancuernas', 'Polea':'Polea', 'Máquina':'Máquina', 
                      'Peso Corporal':'Peso Corporal', 'Barra EZ':'Barra EZ', 'Banco':'Banco', 'Barra de dominadas':'Barra Dominadas'
                    }, (val) => _filterEquipment = val),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Aplicar Filtros", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final muscles = _exercisesByMuscle.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Ejercicios'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterModal,
              ),
              if (_activeFiltersCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_activeFiltersCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                )
            ]
          )
        ]
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 80,
        ),
        itemCount: muscles.length,
        itemBuilder: (context, index) {
          final muscle = muscles[index];
          final exercises = _exercisesByMuscle[muscle]; // Puede ser null

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  // 3. LA CLAVE: Cuando el usuario toca el acordeón, disparamos la petición
                  onExpansionChanged: (isExpanded) {
                    if (isExpanded) {
                      _fetchMuscleGroup(muscle);
                    }
                  },
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  title: Text(
                    muscle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 4. Si la lista es null, mostramos un loading. Si no, mostramos los ejercicios filtrados.
                  children: exercises == null
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ]
                      : _applyFilters(exercises).isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Ningún ejercicio coincide con los filtros'),
                          ),
                        ]
                      : _applyFilters(exercises).map((exercise) {
                          final isSelected = _selectedExercises.containsKey(
                            exercise.id,
                          );

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 4,
                            ),
                            title: Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.info_outline,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExerciceDetailsScreen(
                                          exercice: exercise,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isSelected ? Icons.cancel : Icons.add_circle,
                                    color: isSelected
                                        ? Colors.red.shade400
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () => _toggleExercise(exercise),
                                ),
                              ],
                            ),
                            onTap: () => _toggleExercise(exercise),
                          );
                        }).toList(),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: ConfirmSelectionFab(
        selectedCount: _selectedExercises.length,
        onPressed: () =>
            Navigator.pop(context, _selectedExercises.values.toList()),
      ),
    );
  }
}
