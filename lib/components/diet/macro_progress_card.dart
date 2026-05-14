import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class MacroProgressCard extends StatelessWidget {
  final int consumedProtein;
  final int targetProtein;
  final int consumedCarbs;
  final int targetCarbs;
  final int consumedFat;
  final int targetFat;

  const MacroProgressCard({
    Key? key,
    required this.consumedProtein,
    required this.targetProtein,
    required this.consumedCarbs,
    required this.targetCarbs,
    required this.consumedFat,
    required this.targetFat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macronutrientes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          _MacroBar(
            label: 'Proteínas',
            consumed: consumedProtein,
            target: targetProtein,
            color: AppColors.protein,
          ),
          const SizedBox(height: 9),
          _MacroBar(
            label: 'Carbohidr.',
            consumed: consumedCarbs,
            target: targetCarbs,
            color: AppColors.carbs,
          ),
          const SizedBox(height: 9),
          _MacroBar(
            label: 'Grasas',
            consumed: consumedFat,
            target: targetFat,
            color: AppColors.fat,
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int consumed;
  final int target;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final bool exceeded = consumed > target && target > 0;

    return Row(
      children: [
        // ── Color dot ──────────────────────────────────────────────
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        // ── Label ──────────────────────────────────────────────────
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // ── Bar ────────────────────────────────────────────────────
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(
                exceeded ? AppColors.warning : color,
              ),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ── Amount ─────────────────────────────────────────────────
        SizedBox(
          width: 64,
          child: Text(
            '${consumed}g / ${target}g',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: exceeded ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
