import 'package:flutter/material.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';

/// Muestra los días activos de la semana actual y la racha de días consecutivos.
/// Recibe la lista de sesiones ya obtenidas del backend.
class WeeklyActivitySection extends StatelessWidget {
  const WeeklyActivitySection({super.key, required this.workouts});

  final List<dynamic> workouts;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int currentWeekday = now.weekday;
    final DateTime startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (currentWeekday - 1),
    );

    final Set<int> activeWeekdays = {};
    for (final w in workouts) {
      if (w['fecha'] != null) {
        final DateTime wDate = DateTime.parse(w['fecha']);
        if (!wDate.isBefore(startOfWeek) &&
            wDate.isBefore(startOfWeek.add(const Duration(days: 7)))) {
          activeWeekdays.add(wDate.weekday);
        }
      }
    }

    final List<String> days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Días activos esta semana',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              _buildStreakBadge(context, workouts),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final int dayNumber = index + 1;
              final bool isActive = activeWeekdays.contains(dayNumber);
              final bool isToday = currentWeekday == dayNumber;

              final Color boxColor = isActive
                  ? Theme.of(context).colorScheme.primary
                  : context.colors.surfaceVariant;

              return Column(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? boxColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isActive
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : isActive
                              ? null
                              : Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: isActive
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  int _calculateStreak(List<dynamic> workouts) {
    if (workouts.isEmpty) return 0;
    final Set<DateTime> trainedDays = {};
    for (final w in workouts) {
      if (w['fecha'] != null) {
        final DateTime d = DateTime.parse(w['fecha']);
        trainedDays.add(DateTime(d.year, d.month, d.day));
      }
    }

    final DateTime today = DateTime.now();
    final DateTime todayDay = DateTime(today.year, today.month, today.day);

    DateTime check = todayDay;
    if (!trainedDays.contains(check)) {
      check = check.subtract(const Duration(days: 1));
      if (!trainedDays.contains(check)) return 0;
    }

    int streak = 0;
    while (trainedDays.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Widget _buildStreakBadge(BuildContext context, List<dynamic> workouts) {
    final int streak = _calculateStreak(workouts);
    if (streak == 0) return const SizedBox.shrink();

    final Color fireColor = streak <= 2
        ? Colors.amber.shade600
        : streak <= 4
            ? Colors.orange
            : streak <= 6
                ? Colors.deepOrange
                : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fireColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fireColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: fireColor, size: 20),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: fireColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
