import 'package:flutter/material.dart';
import 'package:fittrack_flutter/services/routine_service.dart';
import 'package:fittrack_flutter/screens/training/active_workout_screen.dart';
import 'package:fittrack_flutter/screens/training/new_workout_screen.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';


class SelectWorkoutScreen extends StatefulWidget {
  const SelectWorkoutScreen({super.key});

  @override
  State<SelectWorkoutScreen> createState() => _SelectWorkoutScreenState();
}

class _SelectWorkoutScreenState extends State<SelectWorkoutScreen> {
  final RoutineService _routineService = RoutineService();

  late Future<List<dynamic>> _myRoutinesFuture;
  late Future<List<dynamic>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _myRoutinesFuture = _routineService.getMyRoutines();
      _recommendationsFuture = _routineService.getRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Rutina'), elevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewWorkoutScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        label: const Text('Crear Rutina'),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 1. Recomendaciones (Carousel Horizontal)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recomendaciones para ti',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: FutureBuilder<List<dynamic>>(
                  future: _recommendationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final lists = snapshot.data ?? [];
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: lists.length + 1,
                      itemBuilder: (context, index) {
                        if (index == lists.length) {
                          return _AiRoutineCarouselCard(onRoutineCreated: _loadData);
                        }
                        return _buildRecommendationCard(lists[index]);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // 2. Mis Rutinas (Lista Vertical)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Mis Rutinas Guardadas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<dynamic>>(
                future: _myRoutinesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final myRoutines = snapshot.data ?? [];
                  if (myRoutines.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 48,
                              color: context.colors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aún no has creado ninguna rutina',
                              style: TextStyle(color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: myRoutines.length,
                    itemBuilder: (context, index) {
                      return _buildMyRoutineCard(myRoutines[index]);
                    },
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(dynamic routine) {
    final name = routine['name'] ?? 'Rutina Recomendada';
    final List focuses = routine['focus'] ?? [];
    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveWorkoutScreen(routine: routine),
              ),
            );
            if (result == true && context.mounted) {
              Navigator.pop(context, true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const Spacer(),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (focuses.isNotEmpty)
                  Text(
                    focuses.join(', '),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyRoutineCard(dynamic routine) {
    final name = routine['name'] ?? 'Mi Rutina';
    final List exercises = routine['exercises'] ?? [];
    final List focuses = routine['focus'] ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveWorkoutScreen(routine: routine),
            ),
          );
          if (result == true && context.mounted) {
            Navigator.pop(context, true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercises.length} Ejercicios • ${focuses.isNotEmpty ? focuses.join(', ') : 'Cuerpo Completo'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textMuted),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Eliminar rutina',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar rutina'),
                      content: Text('¿Seguro que quieres eliminar "$name"? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    final ok = await _routineService.deleteRoutine(routine['_id'] ?? '');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Rutina eliminada.' : 'No se pudo eliminar la rutina.'),
                        ),
                      );
                      if (ok) _loadData();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Routine Carousel Card
// ---------------------------------------------------------------------------

class _AiRoutineCarouselCard extends StatefulWidget {
  final VoidCallback onRoutineCreated;
  const _AiRoutineCarouselCard({required this.onRoutineCreated});

  @override
  State<_AiRoutineCarouselCard> createState() => _AiRoutineCarouselCardState();
}

class _AiRoutineCarouselCardState extends State<_AiRoutineCarouselCard> {
  final RoutineService _routineService = RoutineService();
  String _selectedDifficulty = 'Intermedio';
  bool _isLoading = false;

  static const _difficulties = ['Principiante', 'Intermedio', 'Avanzado'];

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    final routine = await _routineService.generateAiRoutine(_selectedDifficulty);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (routine != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Rutina "${routine['name']}" creada con éxito!')),
      );
      widget.onRoutineCreated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar la rutina. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      // 12px ListView padding + 4px card margin on each side = 32px total
      width: screenWidth - 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C35A0), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                SizedBox(width: 8),
                Text(
                  'Crear Rutina IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _difficulties.map((d) {
                final selected = d == _selectedDifficulty;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDifficulty = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        color: selected
                            ? const Color(0xFF5C35A0)
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5C35A0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fitness_center, size: 16),
                label: Text(
                  _isLoading ? 'Generando...' : 'Generar',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
