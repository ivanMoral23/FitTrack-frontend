import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fittrack_flutter/components/training/muscle_group_stats_widget.dart';
import 'package:fittrack_flutter/components/training/train_component.dart';
import 'package:fittrack_flutter/components/training/weekly_activity_section.dart';
import 'package:fittrack_flutter/components/training/workouts_completed/workouts_completed.dart';
import 'package:fittrack_flutter/screens/training/select_workout_screen.dart';
import 'package:fittrack_flutter/screens/change_password_screen.dart';
import 'package:fittrack_flutter/screens/diet/user_nutrition_profile_screen.dart';
import 'package:fittrack_flutter/services/auth_service.dart';
import 'package:fittrack_flutter/services/insight_service.dart';
import 'package:fittrack_flutter/services/user_stats_provider.dart';
import 'package:fittrack_flutter/services/workout_service.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';
import 'package:provider/provider.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  int _refreshKey = 0;
  final WorkoutService _workoutService = WorkoutService();
  late Future<List<dynamic>> _workoutsFuture;

  @override
  void initState() {
    super.initState();
    _workoutsFuture = _workoutService.getMySessions();
  }

  void _reloadWorkouts() {
    setState(() {
      _refreshKey++;
      _workoutsFuture = _workoutService.getMySessions();
    });
    // Also refresh Home stats so the HomeScreen reflects the new workout
    if (mounted) {
      context.read<UserStatsProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Cuenta',
            onPressed: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => _TrainingProfileSheet(
                onLogout: () async {
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _TrainBody(
          key: ValueKey('train_$_refreshKey'),
          workoutsFuture: _workoutsFuture,
          onReload: _reloadWorkouts,
          refreshKey: _refreshKey,
        ),
      ),
    );
  }
}

class _TrainBody extends StatelessWidget {
  const _TrainBody({
    super.key,
    required this.workoutsFuture,
    required this.onReload,
    required this.refreshKey,
  });

  final Future<List<dynamic>> workoutsFuture;
  final VoidCallback onReload;
  final int refreshKey;

  void _navigateTo(BuildContext context, String title, Widget body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón principal (Comenzar Entreno)
            Hero(
              tag: 'train_component_hero',
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                   height: 180,
                   child: TrainComponent(
                    text: 'Comenzar Entrenamiento',
                    subtext: 'Recomendado para ti',
                    buttontext: 'Comenzar Entrenamiento',
                    imgPath: 'assets/images/gym.jpg',
                    destinationBuilder: (context) => const SelectWorkoutScreen(),
                    onReturn: onReload,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botones secundarios (Historial y Estadísticas) en Row
            Row(
              children: [
                Expanded(
                  child: _MenuCard(
                    title: 'Historial',
                    icon: Icons.history,
                    color1: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                    color2: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.95),
                    onTap: () => _navigateTo(
                      context,
                      'Historial',
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: WorkoutsCompleted(key: ValueKey(refreshKey), nested: true),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MenuCard(
                    title: 'Estadísticas',
                    icon: Icons.bar_chart,
                    color1: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.85),
                    color2: Colors.indigo.withValues(alpha: 0.95),
                    onTap: () => _navigateTo(
                      context,
                      'Estadísticas',
                      MuscleGroupStatsWidget(key: ValueKey('stats_$refreshKey')),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const _AiRecommendationCard(),

            const SizedBox(height: 28),
            Text(
              'Tu Actividad',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: workoutsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Error al cargar tu actividad.'),
                    )
                  );
                }
                final workouts = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WeeklyActivitySection(workouts: workouts),
                    const SizedBox(height: 20),
                    if (workouts.isEmpty)
                      _buildNeverTrainedBanner(context)
                    else
                      _buildActivityBanner(context, workouts),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeverTrainedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center, color: Colors.orange.shade700, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Aún no has registrado entrenamientos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '¡El mejor momento para empezar es hoy!',
            style: TextStyle(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SelectWorkoutScreen()),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Empezar ahora'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBanner(BuildContext context, List<dynamic> workouts) {
    final latest = workouts.firstWhere(
      (w) => w['fecha'] != null,
      orElse: () => null,
    );
    if (latest == null) return const SizedBox.shrink();

    final lastDate = DateTime.parse(latest['fecha']).toLocal();
    final today = DateTime.now();
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final daysSinceLast = todayDay.difference(lastDay).inDays;

    int streak = 0;
    final Set<DateTime> trainedDays = {};
    for (final w in workouts) {
      if (w['fecha'] != null) {
        final d = DateTime.parse(w['fecha']);
        trainedDays.add(DateTime(d.year, d.month, d.day));
      }
    }
    DateTime check = todayDay;
    if (!trainedDays.contains(check)) {
      check = check.subtract(const Duration(days: 1));
    }
    while (trainedDays.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }

    final String title = streak >= 1
        ? '¡Llevas $streak día${streak > 1 ? 's' : ''} seguido${streak > 1 ? 's' : ''}!'
        : (daysSinceLast == 1
            ? 'Ayer no entrenaste.'
            : 'Llevas $daysSinceLast días sin entrenar.');
    final String subtitle = streak >= 1 ? 'Sigue con esa racha, ¡buen trabajo!' : '¡Vuelve al gimnasio, tú puedes!';
        
    final bgColor = streak >= 1
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.orange.withValues(alpha: 0.12);
    final textColor =
        streak >= 1 ? Colors.green.shade800 : Colors.orange.shade800;
    final borderColor = streak >= 1 ? Colors.green.withValues(alpha: 0.25) : Colors.orange.withValues(alpha: 0.25);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(streak >= 1 ? Icons.local_fire_department : Icons.fitness_center, color: textColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu Card helper (similar look to TrainComponent)
// ---------------------------------------------------------------------------

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Recommendation Card
// ---------------------------------------------------------------------------

class _AiRecommendationCard extends StatefulWidget {
  const _AiRecommendationCard();

  @override
  State<_AiRecommendationCard> createState() => _AiRecommendationCardState();
}

class _AiRecommendationCardState extends State<_AiRecommendationCard> {
  final InsightService _insightService = InsightService();
  bool _isLoading = false;
  String? _recommendation;

  void _fetchRecommendation() async {
    setState(() {
      _isLoading = true;
      _recommendation = null;
    });

    final rec = await _insightService.getMuscleRecommendation();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _recommendation = rec ?? 'Hubo un error al contactar al entrenador de IA. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology_outlined, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrenador de IA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '¿Qué deberías entrenar hoy?',
                        style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_recommendation != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _recommendation!,
                  style: TextStyle(fontSize: 14, height: 1.5, color: context.colors.textPrimary),
                ),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: _recommendation != null ? 8 : 0),
            child: FilledButton.tonalIcon(
              onPressed: _isLoading ? null : _fetchRecommendation,
              icon: _isLoading 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_recommendation != null ? 'Preguntar de nuevo' : 'Obtener sugerencia'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Training profile bottom sheet
// ---------------------------------------------------------------------------

class _TrainingProfileSheet extends StatelessWidget {
  const _TrainingProfileSheet({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cuenta',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: Text('Editar perfil', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: context.colors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserNutritionProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: Text('Cambiar contraseña', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: context.colors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text('Cerrar sesión', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}
