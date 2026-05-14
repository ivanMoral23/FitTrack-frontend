import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class NutritionSummaryCard extends StatelessWidget {
  final int consumedCalories;
  final int targetCalories;

  const NutritionSummaryCard({
    Key? key,
    required this.consumedCalories,
    required this.targetCalories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final double progress =
        targetCalories > 0 ? (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;
    final int remaining = targetCalories - consumedCalories;
    final bool isExceeded = remaining < 0;
    final bool isNearGoal = !isExceeded && remaining <= (targetCalories * 0.1);

    final Color ringColor = isExceeded
        ? AppColors.error
        : isNearGoal
            ? AppColors.warning
            : AppColors.primary;

    final String statusLabel = isExceeded
        ? '+${remaining.abs()} kcal excedidas'
        : isNearGoal
            ? '$remaining kcal restantes — ¡casi!'
            : '$remaining kcal restantes';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: colors.shadowOpacity),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Text side ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calorías de hoy',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$consumedCalories',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: ' / $targetCalories',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Ring ───────────────────────────────────────────────
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: ringColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ringColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Progress bar ─────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ringColor.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(
                isExceeded
                    ? Icons.warning_amber_rounded
                    : isNearGoal
                        ? Icons.check_circle_outline_rounded
                        : Icons.local_fire_department_outlined,
                size: 14,
                color: isExceeded
                    ? AppColors.error
                    : isNearGoal
                        ? AppColors.warning
                        : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: isExceeded
                      ? AppColors.error
                      : isNearGoal
                          ? AppColors.warning
                          : colors.textSecondary,
                  fontWeight: isExceeded || isNearGoal
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
