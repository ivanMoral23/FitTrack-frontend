import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/nutrition_service.dart';
import '../../services/auth_service.dart';
import '../../models/nutrition_profile.dart';
import '../../utils/app_colors.dart';
import '../../components/diet/nutrition_summary_card.dart';
import '../../components/diet/macro_progress_card.dart';

import 'user_nutrition_profile_screen.dart';
import 'diet_recommendations_screen.dart';
import 'today_meals_screen.dart';
import 'nutrition_calculator_screen.dart';
import 'nutrition_stats_screen.dart';
import 'meal_history_screen.dart';
import '../change_password_screen.dart';

class NutritionHomeScreen extends StatefulWidget {
  const NutritionHomeScreen({Key? key}) : super(key: key);

  @override
  State<NutritionHomeScreen> createState() => _NutritionHomeScreenState();
}

class _NutritionHomeScreenState extends State<NutritionHomeScreen> {
  // ── Helpers ───────────────────────────────────────────────────────────────

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool _noLogsFor3Days(NutritionService service) {
    if (!service.prefsLoaded || service.history.isEmpty) return false;
    final today = DateTime.now();
    // Only alert if the user has history older than 3 days (established habit)
    final cutoffDate = _dateStr(today.subtract(const Duration(days: 3)));
    if (!service.history.any((r) => r.date.compareTo(cutoffDate) <= 0)) return false;
    for (int i = 1; i <= 3; i++) {
      final d = today.subtract(Duration(days: i));
      if (service.history.any((r) => r.date == _dateStr(d))) return false;
    }
    return true;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _shortDate {
    final now = DateTime.now();
    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionService>(
      builder: (context, service, _) {
        if (!service.prefsLoaded) {
          return Scaffold(
            backgroundColor: context.colors.background,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final profile = service.userProfile;

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            title: Text(
              'Nutrición',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            backgroundColor: context.colors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline,
                    color: AppColors.primaryDark),
                tooltip: 'Cuenta',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => _DietProfileSheet(
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────
                _buildHeader(profile),
                const SizedBox(height: 14),

                // ── Alerts ────────────────────────────────────────
                _buildAlerts(service),

                // ── Calorie hero card ─────────────────────────────
                NutritionSummaryCard(
                  consumedCalories: service.consumedCalories,
                  targetCalories: profile.targetCalories,
                ),
                const SizedBox(height: 10),

                // ── Macros compact card ───────────────────────────
                MacroProgressCard(
                  consumedProtein: service.consumedProtein,
                  targetProtein: profile.targetProtein,
                  consumedCarbs: service.consumedCarbs,
                  targetCarbs: profile.targetCarbs,
                  consumedFat: service.consumedFat,
                  targetFat: profile.targetFat,
                ),
                const SizedBox(height: 10),

                // ── Active plan banner ────────────────────────────
                if (service.currentDietPlan != null)
                  _buildActivePlanBanner(context, service),

                const SizedBox(height: 16),

                // ── Quick actions ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Acceso rápido',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      _shortDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildQuickActionsRow(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(NutritionProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'Tu plan nutricional',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
        // Goal chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(profile.goal.emoji,
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                profile.goal.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Alerts ────────────────────────────────────────────────────────────────

  Widget _buildAlerts(NutritionService service) {
    final alerts = <_AlertData>[];
    final consumed = service.consumedCalories;
    final target = service.userProfile.targetCalories;
    final hour = DateTime.now().hour;

    if (target > 0 && consumed > target) {
      alerts.add(_AlertData(
        icon: Icons.warning_amber_rounded,
        message: 'Has superado tu objetivo — ${consumed - target} kcal de más.',
        color: AppColors.error,
      ));
    } else if (hour >= 18 && target > 0 && consumed < target * 0.5) {
      final pct = (consumed / target * 100).round();
      alerts.add(_AlertData(
        icon: Icons.access_time_rounded,
        message: '${hour}h y solo llevas el $pct% de calorías. ¡Recuerda comer!',
        color: AppColors.warning,
      ));
    }

    if (_noLogsFor3Days(service)) {
      alerts.add(_AlertData(
        icon: Icons.emoji_emotions_outlined,
        message: '¡3 días sin registrar comidas! Retoma el hábito hoy.',
        color: AppColors.carbs,
      ));
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: alerts.map((a) => _AlertBanner(data: a)).toList(),
      ),
    );
  }

  // ── Active plan banner ────────────────────────────────────────────────────

  Widget _buildActivePlanBanner(BuildContext context, NutritionService service) {
    final plan = service.currentDietPlan!;
    final completed = service.completedMealsCount;
    final total = service.todayMeals.length;
    final double mealProgress = total > 0 ? completed / total : 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TodayMealsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.88),
              AppColors.primaryDark.withOpacity(0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_menu,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan activo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mealProgress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  '$completed/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'comidas',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white60, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Quick actions (horizontal scroll) ────────────────────────────────────

  Widget _buildQuickActionsRow(BuildContext context) {
    final items = [
      _ActionItem(
        icon: Icons.today_rounded,
        title: 'Mis Comidas',
        color: AppColors.primary,
        screen: const TodayMealsScreen(),
      ),
      _ActionItem(
        icon: Icons.menu_book_rounded,
        title: 'Planes Dieta',
        color: AppColors.secondary,
        screen: const DietRecommendationsScreen(),
      ),
      _ActionItem(
        icon: Icons.bar_chart_rounded,
        title: 'Estadísticas',
        color: const Color(0xFF7E57C2),
        screen: const NutritionStatsScreen(),
      ),
      _ActionItem(
        icon: Icons.history_rounded,
        title: 'Historial',
        color: const Color(0xFF26A69A),
        screen: const MealHistoryScreen(),
      ),
      _ActionItem(
        icon: Icons.calculate_rounded,
        title: 'Calculadora',
        color: AppColors.carbs,
        screen: const NutritionCalculatorScreen(),
      ),
      _ActionItem(
        icon: Icons.manage_accounts_rounded,
        title: 'Mi Perfil',
        color: AppColors.protein,
        screen: const UserNutritionProfileScreen(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = constraints.maxWidth / items.length;
        // Icon container scales with available space, clamped for readability
        final double circleSize = (itemWidth * 0.68).clamp(38.0, 62.0);
        final double iconSize = (circleSize * 0.50).clamp(20.0, 30.0);
        final double fontSize = (itemWidth * 0.145).clamp(9.0, 12.5);

        return Row(
          children: items
              .map((item) => Expanded(
                    child: _buildActionChip(
                      context,
                      item,
                      circleSize: circleSize,
                      iconSize: iconSize,
                      fontSize: fontSize,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildActionChip(
    BuildContext context,
    _ActionItem item, {
    double circleSize = 54,
    double iconSize = 26,
    double fontSize = 10,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => item.screen)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.11),
              shape: BoxShape.circle,
              border: Border.all(
                color: item.color.withOpacity(0.20),
                width: 1.2,
              ),
            ),
            child: Icon(item.icon, size: iconSize, color: item.color),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _AlertData {
  final IconData icon;
  final String message;
  final Color color;
  const _AlertData({required this.icon, required this.message, required this.color});
}

class _AlertBanner extends StatelessWidget {
  final _AlertData data;
  const _AlertBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: data.color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.message,
              style: TextStyle(
                fontSize: 12,
                color: data.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final Color color;
  final Widget screen;
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.screen,
  });
}

// ── Diet profile bottom sheet ─────────────────────────────────────────────────

class _DietProfileSheet extends StatelessWidget {
  const _DietProfileSheet({required this.onLogout});
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
