import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_stats.dart';
import '../../services/user_stats_provider.dart';
import '../../services/insight_service.dart';
import '../../services/workout_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../change_password_screen.dart';
import '../diet/user_nutrition_profile_screen.dart';

// -----------------------------------------------------------------------------
// HomeScreen
// -----------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InsightService _insightService = InsightService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserStatsProvider>().load();
    });
  }

  void _triggerThinking() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Analizando tu estado...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    bool success = await _insightService.triggerManualAgent();
    if (!mounted) return;
    if (success) {
      context.read<UserStatsProvider>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nuevo analisis disponible'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error conectando con el asistente'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserStatsProvider>();
    return Scaffold(
      backgroundColor: context.colors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<UserStatsProvider>().refresh(),
        child: SafeArea(child: _buildContent(context, provider)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserStatsProvider provider) {
    return switch (provider.status) {
      UserStatsStatus.loading || UserStatsStatus.initial => const _LoadingState(),
      UserStatsStatus.error   => const _ErrorState(),
      UserStatsStatus.loaded  => _LoadedState(
          stats: provider.stats,
          healthLoading: provider.healthLoading,
          backendUnavailable: provider.backendUnavailable,
          onTriggerAnalysis: _triggerThinking,
        ),
    };
  }
}

// -----------------------------------------------------------------------------
// Loading & Error
// -----------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_off, size: 52, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los datos',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Comprueba tu conexion y vuelve a intentarlo.',
              style: GoogleFonts.inter(color: context.colors.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<UserStatsProvider>().refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Loaded
// -----------------------------------------------------------------------------

class _LoadedState extends StatelessWidget {
  const _LoadedState({
    required this.stats,
    required this.healthLoading,
    required this.backendUnavailable,
    required this.onTriggerAnalysis,
  });
  final UserStats stats;
  final bool healthLoading;
  final bool backendUnavailable;
  final VoidCallback onTriggerAnalysis;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HomeHeader(onLogout: () async {
            await AuthService().logout();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            }
          }),
          if (backendUnavailable) ...[
            const SizedBox(height: 10),
            const _ConnectivityBanner(),
          ],
          const SizedBox(height: 20),
          // Tarjeta de actividad — muestra skeleton mientras carga Health Connect.
          if (healthLoading)
            _HealthLoadingCard()
          else
            _ActivityOverviewCard(stats: stats),
          const SizedBox(height: 14),
          // Pasos: siempre visible; mientras carga muestra skeleton.
          if (healthLoading)
            _HealthSkeletonCard(label: 'Pasos')
          else if (stats.steps > 0)
            _StepsCard(steps: stats.steps),
          if (!healthLoading && stats.steps > 0) const SizedBox(height: 14),
          // Sueño: solo si hay datos.
          if (healthLoading)
            _HealthSkeletonCard(label: 'Sueño')
          else if (stats.sleepHours > 0) ...[
            _SleepCard(
              sleepHours: stats.sleepHours,
              screenTimeMinutes: stats.screenTimeMinutes,
            ),
            const SizedBox(height: 14),
          ],
          if (healthLoading) const SizedBox(height: 14),
          const _WaterIntakeCard(),
          const SizedBox(height: 14),
          // Frecuencia cardíaca: solo si hay datos.
          if (!healthLoading && stats.heartRate > 0) ...[
            _HeartRateCard(heartRate: stats.heartRate),
            const SizedBox(height: 14),
          ],
          const _WorkoutSnapshotCard(),
          const SizedBox(height: 14),
          // _WellnessCard(gravityIndex: stats.gravityIndex, stats: stats),
          // const SizedBox(height: 14),
          _AiAgentCard(
            insight: stats.dailyInsight,
            onTrigger: onTriggerAnalysis,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Health loading skeletons
// -----------------------------------------------------------------------------

/// Tarjeta de actividad completa con spinner mientras llegan los datos de Health Connect.
class _HealthLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Actividad de hoy',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              const Spacer(),
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('Conectando con Health Connect…',
                style: GoogleFonts.inter(fontSize: 13, color: context.colors.textSecondary)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Tarjeta skeleton genérica para métricas de salud pendientes de carga.
class _HealthSkeletonCard extends StatelessWidget {
  const _HealthSkeletonCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text('Cargando $label…',
              style: GoogleFonts.inter(fontSize: 13, color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onLogout});
  final VoidCallback onLogout;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 13) return 'Buenos dias';
    if (h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _dateStr {
    final now = DateTime.now();
    const weekdays = ['Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo'];
    const months   = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.watch<ThemeProvider>().isDark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dateStr,
                style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.read<ThemeProvider>().toggleTheme(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF252535)
                  : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => _ProfileSheet(onLogout: onLogout),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF252535)
                  : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 24),
          ),
        ),
      ],
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.watch<ThemeProvider>().isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cuenta',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: Text('Editar perfil', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: colors.textPrimary)),
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
            title: Text('Cambiar contraseña', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: colors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              isDark ? 'Modo claro' : 'Modo oscuro',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: colors.textPrimary),
            ),
            onTap: () {
              context.read<ThemeProvider>().toggleTheme();
              Navigator.pop(context);
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

// -----------------------------------------------------------------------------
// Connectivity Banner
// -----------------------------------------------------------------------------

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin conexion al servidor. Mostrando datos locales.',
              style: GoogleFonts.inter(color: Colors.orange.shade800, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Activity Overview Card
// -----------------------------------------------------------------------------

class _ActivityOverviewCard extends StatelessWidget {
  const _ActivityOverviewCard({required this.stats});
  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Actividad de hoy',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
              ),
              const Spacer(),
              _Badge(label: 'En tiempo real', color: AppColors.success),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RingMetric(
                value: (stats.steps / 10000).clamp(0.0, 1.0),
                color: AppColors.steps,
                icon: Icons.directions_walk_rounded,
                label: '${(stats.steps / 1000).toStringAsFixed(1)}k',
                sublabel: 'pasos',
              ),
              _RingMetric(
                value: (stats.caloriesBurned / 600).clamp(0.0, 1.0),
                color: AppColors.calories,
                icon: Icons.local_fire_department_rounded,
                label: '${stats.caloriesBurned}',
                sublabel: 'kcal',
              ),
              _RingMetric(
                value: (stats.activeMinutes / 60).clamp(0.0, 1.0),
                color: AppColors.activeMinutes,
                icon: Icons.timer_outlined,
                label: '${stats.activeMinutes}',
                sublabel: 'min activos',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingMetric extends StatelessWidget {
  const _RingMetric({
    required this.value,
    required this.color,
    required this.icon,
    required this.label,
    required this.sublabel,
  });
  final double value;
  final Color color;
  final IconData icon;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  color: color.withValues(alpha: 0.12),
                ),
              ),
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: color,
                ),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
        Text(sublabel, style: GoogleFonts.inter(fontSize: 11, color: context.colors.textSecondary)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Steps Card
// -----------------------------------------------------------------------------

class _StepsCard extends StatefulWidget {
  const _StepsCard({required this.steps});
  final int steps;
  @override
  State<_StepsCard> createState() => _StepsCardState();
}

class _StepsCardState extends State<_StepsCard> {
  static const _prefKey = 'daily_step_goal';
  int _goal = 10000;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefKey);
    if (saved != null && mounted) setState(() => _goal = saved);
  }

  Future<void> _saveGoal(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, v);
  }

  void _editGoal() {
    final c = TextEditingController(text: _goal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Objetivo diario', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Pasos',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(c.text);
              if (val != null && val > 0) { setState(() => _goal = val); _saveGoal(val); }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress  = (widget.steps / _goal).clamp(0.0, 1.0);
    final pct       = (progress * 100).toStringAsFixed(0);
    final remaining = (_goal - widget.steps).clamp(0, _goal);

    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Pasos hoy', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: _editGoal,
                child: Row(
                  children: [
                    Text('Meta: $_goal', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(child: CircularProgressIndicator(value: 1, strokeWidth: 11, color: AppColors.primary.withValues(alpha: 0.12))),
                    SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 11, strokeCap: StrokeCap.round, color: AppColors.primary)),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${widget.steps}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                        Text('pasos', style: GoogleFonts.inter(fontSize: 11, color: context.colors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$pct%', style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('del objetivo', style: GoogleFonts.inter(fontSize: 13, color: context.colors.textSecondary)),
                    const SizedBox(height: 12),
                    if (progress >= 1)
                      _Badge(label: 'Objetivo alcanzado!', color: AppColors.success)
                    else
                      Text('Faltan $remaining pasos', style: GoogleFonts.inter(fontSize: 13, color: context.colors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: AppColors.primaryLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Sleep Card
// -----------------------------------------------------------------------------

class _SleepCard extends StatelessWidget {
  const _SleepCard({required this.sleepHours, required this.screenTimeMinutes});
  final double sleepHours;
  final int screenTimeMinutes;

  String get _sleepQuality {
    if (sleepHours >= 8) return 'Excelente';
    if (sleepHours >= 7) return 'Bueno';
    if (sleepHours >= 6) return 'Regular';
    if (sleepHours == 0) return 'Sin datos';
    return 'Insuficiente';
  }

  Color get _sleepColor {
    if (sleepHours == 0) return AppColors.textMuted;
    if (sleepHours >= 8) return AppColors.success;
    if (sleepHours >= 7) return AppColors.activeMinutes;
    if (sleepHours >= 6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final screenH = screenTimeMinutes / 60;
    final screenColor = screenH > 6 ? AppColors.error : screenH > 4 ? AppColors.warning : AppColors.success;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.sleep.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bedtime_rounded, color: AppColors.sleep, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Sueno y pantalla', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary)),
              const Spacer(),
              _Badge(label: _sleepQuality, color: _sleepColor),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _MetricTile(
                icon: Icons.bedtime_outlined,
                color: AppColors.sleep,
                label: 'Sueno',
                value: sleepHours == 0 ? 'N/D' : '${sleepHours.toStringAsFixed(1)} h',
                subtitle: 'Recomendado: 7-9 h',
                progress: (sleepHours / 9).clamp(0.0, 1.0),
              )),
              const SizedBox(width: 12),
              Expanded(child: _MetricTile(
                icon: Icons.phone_android_outlined,
                color: screenTimeMinutes == 0 ? AppColors.textMuted : screenColor,
                label: 'Pantalla',
                value: screenTimeMinutes == 0 ? 'N/D' : '${screenH.toStringAsFixed(1)} h',
                subtitle: screenTimeMinutes == 0 ? 'Sin datos' : (screenH > 6 ? 'Uso elevado' : screenH > 4 ? 'Uso moderado' : 'Uso saludable'),
                progress: (screenH / 12).clamp(0.0, 1.0),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sleepHours < 7 && sleepHours > 0
                        ? 'Intenta dormir al menos 7 horas para optimizar la recuperacion muscular.'
                        : 'Un buen descanso mejora el rendimiento deportivo y la recuperacion.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.progress,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: context.colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: context.colors.textSecondary)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Water Intake Card
// -----------------------------------------------------------------------------

class _WaterIntakeCard extends StatefulWidget {
  const _WaterIntakeCard();
  @override
  State<_WaterIntakeCard> createState() => _WaterIntakeCardState();
}

class _WaterIntakeCardState extends State<_WaterIntakeCard> {
  static const _keyMl   = 'water_ml_today';
  static const _keyDate = 'water_date_today';
  static const _goalMl  = 2500;
  static const _glassSize = 250;

  int _currentMl = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_keyDate) ?? '';
    if (savedDate != today) {
      await prefs.setInt(_keyMl, 0);
      await prefs.setString(_keyDate, today);
      if (mounted) setState(() => _currentMl = 0);
    } else {
      final ml = prefs.getInt(_keyMl) ?? 0;
      if (mounted) setState(() => _currentMl = ml);
    }
  }

  Future<void> _add(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = (_currentMl + ml).clamp(0, 5000);
    await prefs.setInt(_keyMl, newVal);
    await prefs.setString(_keyDate, _todayStr());
    setState(() => _currentMl = newVal);
  }

  String _todayStr() { final d = DateTime.now(); return '${d.year}-${d.month}-${d.day}'; }

  @override
  Widget build(BuildContext context) {
    final progress  = (_currentMl / _goalMl).clamp(0.0, 1.0);
    final glasses   = (_currentMl / _glassSize).floor();
    final goalGlasses = (_goalMl / _glassSize).ceil();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.water.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.water_drop_rounded, color: AppColors.water, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Hidratacion', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary)),
              const Spacer(),
              _Badge(
                label: progress >= 1 ? 'Meta!' : '${(_currentMl / 1000).toStringAsFixed(1)}L / ${_goalMl/1000}L',
                color: progress >= 1 ? AppColors.success : AppColors.water,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress, minHeight: 12,
              backgroundColor: AppColors.water.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.water),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(goalGlasses > 10 ? 10 : goalGlasses, (i) {
              final filled = i < glasses;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  filled ? Icons.local_drink_rounded : Icons.local_drink_outlined,
                  color: filled ? AppColors.water : context.colors.textMuted,
                  size: 22,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$glasses vasos', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                    Text('$_currentMl ml consumidos hoy', style: GoogleFonts.inter(fontSize: 12, color: context.colors.textSecondary)),
                  ],
                ),
              ),
              Row(
                children: [
                  _WaterButton(icon: Icons.remove, onTap: () => _add(-_glassSize)),
                  const SizedBox(width: 8),
                  _WaterButton(icon: Icons.add, onTap: () => _add(_glassSize), filled: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({required this.icon, required this.onTap, this.filled = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: filled ? AppColors.water : AppColors.water.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: filled ? Colors.white : AppColors.water, size: 20),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Heart Rate Card
// -----------------------------------------------------------------------------

class _HeartRateCard extends StatelessWidget {
  const _HeartRateCard({required this.heartRate});
  final int heartRate;

  String get _zone {
    if (heartRate < 60) return 'Reposo';
    if (heartRate < 100) return 'Normal';
    if (heartRate < 140) return 'Aerobico';
    return 'Alta intensidad';
  }

  Color get _zoneColor {
    if (heartRate < 60) return AppColors.water;
    if (heartRate < 100) return AppColors.success;
    if (heartRate < 140) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.heartRate.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.favorite_rounded, color: AppColors.heartRate, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Frecuencia cardiaca', style: GoogleFonts.inter(fontSize: 13, color: context.colors.textSecondary)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$heartRate', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text('bpm', style: GoogleFonts.inter(fontSize: 13, color: context.colors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Badge(label: _zone, color: _zoneColor),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Workout Snapshot Card
// -----------------------------------------------------------------------------

class _WorkoutSnapshotCard extends StatefulWidget {
  const _WorkoutSnapshotCard();
  @override
  State<_WorkoutSnapshotCard> createState() => _WorkoutSnapshotCardState();
}

class _WorkoutSnapshotCardState extends State<_WorkoutSnapshotCard> {
  final WorkoutService _service = WorkoutService();
  late final Future<List<dynamic>> _future = _service.getMySessions();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _Card(child: const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.trainingAccent),
          )));
        }
        final workouts = snapshot.data ?? [];
        return _Card(child: _buildContent(workouts));
      },
    );
  }

  Widget _buildContent(List<dynamic> workouts) {
    int streak = 0;
    if (workouts.isNotEmpty) {
      final Set<DateTime> days = {};
      for (final w in workouts) {
        if (w['fecha'] != null) {
          final d = DateTime.parse(w['fecha']);
          days.add(DateTime(d.year, d.month, d.day));
        }
      }
      final today = DateTime.now();
      DateTime check = DateTime(today.year, today.month, today.day);
      if (!days.contains(check)) check = check.subtract(const Duration(days: 1));
      while (days.contains(check)) { streak++; check = check.subtract(const Duration(days: 1)); }
    }

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final thisWeekCount = workouts.where((w) {
      if (w['fecha'] == null) return false;
      final d = DateTime.parse(w['fecha']);
      return !d.isBefore(startOfWeek) && d.isBefore(startOfWeek.add(const Duration(days: 7)));
    }).length;

    double totalVolume = 0;
    for (final s in workouts) {
      for (final ex in (s['ejercicios_realizados'] as List? ?? [])) {
        for (final set in (ex['series'] as List? ?? [])) {
          totalVolume += ((set['reps'] as num?)?.toDouble() ?? 0) * ((set['peso'] as num?)?.toDouble() ?? 0);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.trainingAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.fitness_center_rounded, color: AppColors.trainingAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Mis entrenamientos', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary)),
          ],
        ),
        const SizedBox(height: 16),
        if (workouts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aun no has registrado entrenamientos.\nHoy es el dia para empezar!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: context.colors.textSecondary, fontSize: 13, height: 1.5),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(child: _WorkoutStat(icon: Icons.local_fire_department_rounded, color: streak > 3 ? Colors.deepOrange : Colors.orange, value: '$streak', label: 'dias\nracha')),
              Expanded(child: _WorkoutStat(icon: Icons.calendar_today_rounded, color: AppColors.trainingAccent, value: '$thisWeekCount', label: 'sesiones\nesta semana')),
              Expanded(child: _WorkoutStat(icon: Icons.fitness_center, color: AppColors.primary, value: '${(totalVolume / 1000).toStringAsFixed(1)}k', label: 'kg totales\nlevantados')),
              Expanded(child: _WorkoutStat(icon: Icons.history_rounded, color: AppColors.dietAccent, value: '${workouts.length}', label: 'sesiones\ntotales')),
            ],
          ),
      ],
    );
  }
}

class _WorkoutStat extends StatelessWidget {
  const _WorkoutStat({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: context.colors.textSecondary, height: 1.3), textAlign: TextAlign.center),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Wellness / Gravity Index Card
// -----------------------------------------------------------------------------

class _WellnessCard extends StatelessWidget {
  const _WellnessCard({required this.gravityIndex, required this.stats});
  final double gravityIndex;
  final UserStats stats;

  String get _level {
    if (gravityIndex >= 80) return 'Excelente';
    if (gravityIndex >= 65) return 'Bueno';
    if (gravityIndex >= 50) return 'Regular';
    return 'Bajo';
  }

  Color get _color {
    if (gravityIndex >= 80) return AppColors.success;
    if (gravityIndex >= 65) return AppColors.activeMinutes;
    if (gravityIndex >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.self_improvement_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Indice de bienestar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary)),
                  Text('Gravity Index', style: GoogleFonts.inter(fontSize: 11, color: context.colors.textMuted)),
                ],
              ),
              const Spacer(),
              _Badge(label: _level, color: _color),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(child: CustomPaint(painter: _SemiCirclePainter(value: gravityIndex / 100, color: _color))),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        Text(gravityIndex.toStringAsFixed(0), style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                        Text('/100', style: GoogleFonts.inter(fontSize: 11, color: context.colors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IndexRow(label: 'Pasos', value: stats.steps.toString(), progress: (stats.steps / 10000).clamp(0, 1).toDouble(), color: AppColors.steps),
                    const SizedBox(height: 6),
                    _IndexRow(label: 'Sueno', value: '${stats.sleepHours.toStringAsFixed(1)}h', progress: (stats.sleepHours / 9).clamp(0, 1).toDouble(), color: AppColors.sleep),
                    const SizedBox(height: 6),
                    _IndexRow(label: 'Kcal', value: '${stats.caloriesBurned}', progress: (stats.caloriesBurned / 600).clamp(0, 1).toDouble(), color: AppColors.calories),
                    const SizedBox(height: 6),
                    _IndexRow(label: 'Min', value: '${stats.activeMinutes}', progress: (stats.activeMinutes / 60).clamp(0, 1).toDouble(), color: AppColors.activeMinutes),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndexRow extends StatelessWidget {
  const _IndexRow({required this.label, required this.value, required this.progress, required this.color});
  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.colors.textSecondary))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress, minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
      ],
    );
  }
}

class _SemiCirclePainter extends CustomPainter {
  const _SemiCirclePainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final cy   = size.height * 0.75;
    final r    = size.width * 0.42;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final bg = Paint()..color = color.withValues(alpha: 0.12)..strokeWidth = 10..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fg = Paint()..color = color..strokeWidth = 10..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, bg);
    canvas.drawArc(rect, math.pi, math.pi * value, false, fg);
  }

  @override
  bool shouldRepaint(_SemiCirclePainter old) => old.value != value || old.color != color;
}

// -----------------------------------------------------------------------------
// AI Agent Card
// -----------------------------------------------------------------------------

class _AiAgentCard extends StatefulWidget {
  const _AiAgentCard({required this.insight, required this.onTrigger});
  final String insight;
  final VoidCallback onTrigger;
  @override
  State<_AiAgentCard> createState() => _AiAgentCardState();
}

class _AiAgentCardState extends State<_AiAgentCard> {
  bool _isAnalyzing = false;

  void _handleTrigger() async {
    setState(() => _isAnalyzing = true);
    widget.onTrigger();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isAnalyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasInsight = widget.insight.isNotEmpty;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asistente IA', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary)),
                    Text('Analisis personalizado de salud', style: GoogleFonts.inter(fontSize: 11, color: context.colors.textMuted)),
                  ],
                ),
              ),
              if (!_isAnalyzing)
                IconButton(onPressed: _handleTrigger, icon: const Icon(Icons.refresh_rounded), color: AppColors.primary)
              else
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          if (hasInsight)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Text(widget.insight, style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: context.colors.textPrimary)),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: context.colors.textMuted, size: 40),
                    const SizedBox(height: 12),
                    Text('Aun no hay analisis para hoy.', style: GoogleFonts.inter(color: context.colors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isAnalyzing ? null : _handleTrigger,
              icon: _isAnalyzing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_isAnalyzing ? 'Analizando...' : 'Analizar mi estado ahora'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primaryLight),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Analisis automaticos a las 02:00 AM',
              style: GoogleFonts.inter(fontSize: 10, color: context.colors.textMuted, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared primitives
// -----------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: context.colors.cardDecoration(),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
