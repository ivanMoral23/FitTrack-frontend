import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/nutrition_service.dart';
import '../../models/daily_record.dart';
import '../../utils/app_colors.dart';

enum _HistoryFilter { week, month, all }

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.week;

  static const _dayAbbrs = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _monthNames = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<DailyRecord> _filtered(List<DailyRecord> all) {
    final now = DateTime.now();
    List<DailyRecord> result;

    switch (_filter) {
      case _HistoryFilter.week:
        final monday = _getMonday(now);
        final dates = List.generate(7, (i) {
          final d = monday.add(Duration(days: i));
          return _dateStr(d);
        });
        result = all.where((r) => dates.contains(r.date)).toList();
        break;
      case _HistoryFilter.month:
        result = all.where((r) {
          final parts = r.date.split('-');
          return int.parse(parts[0]) == now.year &&
              int.parse(parts[1]) == now.month;
        }).toList();
        break;
      case _HistoryFilter.all:
        result = List.from(all);
        break;
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  DateTime _getMonday(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _formatLabel(String dateStr) {
    final parts = dateStr.split('-');
    final d = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final dayAbbr = _dayAbbrs[d.weekday - 1];
    final monthName = _monthNames[d.month - 1];
    return '$dayAbbr ${d.day} $monthName ${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Historial de Comidas',
            style: TextStyle(color: context.colors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Consumer<NutritionService>(
        builder: (context, service, _) {
          final records = _filtered(service.history.toList());

          return Column(
            children: [
              _buildFilterBar(),
              if (records.isNotEmpty) _buildSummaryRow(records),
              Expanded(
                child: records.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: records.length,
                        itemBuilder: (ctx, i) => _buildDayCard(
                            records[i],
                            service.userProfile.targetCalories),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _HistoryFilter.values.map((f) {
          final selected = _filter == f;
          final labels = {
            _HistoryFilter.week: 'Esta semana',
            _HistoryFilter.month: 'Este mes',
            _HistoryFilter.all: 'Todo',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : context.colors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[f]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : context.colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Summary row ───────────────────────────────────────────────────────────

  Widget _buildSummaryRow(List<DailyRecord> records) {
    final totalCal =
        records.fold(0, (s, r) => s + r.consumedCalories);
    final avgCal = records.isEmpty ? 0 : totalCal ~/ records.length;
    final avgAdherence = records.isEmpty
        ? 0.0
        : records.fold(0.0, (s, r) => s + r.calorieAdherence) /
            records.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      color: context.colors.surface,
      child: Row(
        children: [
          _SummaryPill('${records.length} días', 'registrados',
              AppColors.primary),
          const SizedBox(width: 10),
          _SummaryPill('$avgCal kcal', 'media diaria',
              AppColors.secondary),
          const SizedBox(width: 10),
          _SummaryPill('${(avgAdherence * 100).round()}%', 'adherencia',
              avgAdherence >= 0.85
                  ? AppColors.primary
                  : avgAdherence >= 0.65
                      ? AppColors.warning
                      : AppColors.error),
        ],
      ),
    );
  }

  // ── Day card ──────────────────────────────────────────────────────────────

  Widget _buildDayCard(DailyRecord rec, int targetCal) {
    final pct = targetCal > 0
        ? (rec.consumedCalories / targetCal).clamp(0.0, 1.0)
        : 0.0;
    final over = rec.consumedCalories > targetCal;

    final Color color;
    if (over) {
      color = AppColors.error;
    } else if (pct >= 0.8) {
      color = AppColors.primary;
    } else if (pct >= 0.5) {
      color = AppColors.warning;
    } else {
      color = const Color(0xFF64B5F6);
    }

    final label = _formatLabel(rec.date);
    final remaining = targetCal - rec.consumedCalories;
    final today = _dateStr(DateTime.now());
    final isToday = rec.date == today;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isToday
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Hoy',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.colors.textPrimary),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${rec.consumedCalories} kcal',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color),
                    ),
                    Text(
                      remaining >= 0
                          ? '$remaining restantes'
                          : '${remaining.abs()} superadas',
                      style: TextStyle(
                          fontSize: 11,
                          color: remaining >= 0
                              ? context.colors.textSecondary
                              : AppColors.error),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Calorie bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),

            // Macros row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MacroItem('Proteína', rec.consumedProtein,
                    rec.targetProtein, AppColors.protein),
                _MacroItem('Carbohid.', rec.consumedCarbs,
                    rec.targetCarbs, AppColors.carbs),
                _MacroItem('Grasa', rec.consumedFat,
                    rec.targetFat, AppColors.fat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = switch (_filter) {
      _HistoryFilter.week =>
        'Sin registros esta semana.\nEmpieza a registrar tus comidas desde "Mis Comidas de Hoy".',
      _HistoryFilter.month =>
        'Sin registros este mes.',
      _HistoryFilter.all =>
        'No hay historial todavía.\nLos días que registres comidas aparecerán aquí.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.colors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SummaryPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryPill(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final int consumed;
  final int target;
  final Color color;

  const _MacroItem(this.label, this.consumed, this.target, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${consumed}g',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: consumed > target ? AppColors.error : color),
        ),
        Text(
          '$label / ${target}g',
          style: TextStyle(
              fontSize: 10, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}
