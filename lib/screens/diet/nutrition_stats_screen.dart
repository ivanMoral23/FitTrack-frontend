import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/nutrition_service.dart';
import '../../models/daily_record.dart';
import '../../models/nutrition_profile.dart';
import '../../utils/app_colors.dart';

class NutritionStatsScreen extends StatefulWidget {
  const NutritionStatsScreen({Key? key}) : super(key: key);

  @override
  State<NutritionStatsScreen> createState() => _NutritionStatsScreenState();
}

class _NutritionStatsScreenState extends State<NutritionStatsScreen> {
  late DateTime _weekStart;
  final _isCurrentWeek = ValueNotifier<bool>(true);

  static const _dayAbbrs = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _weekStart = _getMonday(DateTime.now());
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  DateTime _getMonday(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _formatShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  // ── Week navigation ───────────────────────────────────────────────────────

  void _prevWeek() => setState(() {
        _weekStart = _weekStart.subtract(const Duration(days: 7));
        _isCurrentWeek.value = false;
      });

  void _nextWeek() {
    final next = _weekStart.add(const Duration(days: 7));
    final currentMonday = _getMonday(DateTime.now());
    if (next.isAfter(currentMonday)) return;
    setState(() {
      _weekStart = next;
      _isCurrentWeek.value = next.isAtSameMomentAs(currentMonday);
    });
  }

  bool get _canGoNext {
    final currentMonday = _getMonday(DateTime.now());
    return _weekStart.isBefore(currentMonday);
  }

  // ── Export ────────────────────────────────────────────────────────────────

  void _exportWeek(
      List<DailyRecord> records, NutritionProfile profile) {
    final buf = StringBuffer();
    buf.writeln('RESUMEN SEMANAL · ${_formatShort(_weekStart)} - '
        '${_formatShort(_weekStart.add(const Duration(days: 6)))}');
    buf.writeln('─' * 42);

    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      final rec = records.where((r) => r.date == _dateStr(day)).firstOrNull;
      final dayLabel = '${_dayAbbrs[i]} ${_formatShort(day)}';
      if (rec != null) {
        buf.writeln('$dayLabel: ${rec.consumedCalories} kcal'
            ' · P:${rec.consumedProtein}g'
            ' C:${rec.consumedCarbs}g'
            ' G:${rec.consumedFat}g');
      } else {
        buf.writeln('$dayLabel: sin registro');
      }
    }

    buf.writeln('─' * 42);
    if (records.isNotEmpty) {
      final avgCal = records.fold(0, (s, r) => s + r.consumedCalories) ~/
          records.length;
      final avgProt =
          records.fold(0, (s, r) => s + r.consumedProtein) ~/
              records.length;
      final avgCarbs =
          records.fold(0, (s, r) => s + r.consumedCarbs) ~/
              records.length;
      final avgFat =
          records.fold(0, (s, r) => s + r.consumedFat) ~/
              records.length;
      buf.writeln('Media diaria: $avgCal kcal'
          ' · P:${avgProt}g C:${avgCarbs}g G:${avgFat}g');
      buf.writeln('Objetivo: ${profile.targetCalories} kcal/día');
    } else {
      buf.writeln('Sin datos esta semana');
    }

    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resumen copiado al portapapeles'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionService>(
      builder: (context, service, _) {
        final profile = service.userProfile;
        final records = service.getRecordsForWeek(_weekStart);

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            title: Text('Estadísticas',
                style: TextStyle(color: context.colors.textPrimary)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme:
                IconThemeData(color: context.colors.textPrimary),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share,
                    color: AppColors.primaryDark),
                tooltip: 'Exportar resumen',
                onPressed: () => _exportWeek(records, profile),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeekNavigator(),
                const SizedBox(height: 16),
                _buildCalorieChart(records, profile.targetCalories),
                const SizedBox(height: 16),
                _buildWeeklySummary(records, profile),
                const SizedBox(height: 16),
                _buildMacrosSummary(records, profile),
                const SizedBox(height: 16),
                _buildDayByDayList(records, profile.targetCalories),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Week navigator ────────────────────────────────────────────────────────

  Widget _buildWeekNavigator() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left,
                color: context.colors.textPrimary),
            onPressed: _prevWeek,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              '${_formatShort(_weekStart)} – ${_formatShort(weekEnd)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.colors.textPrimary),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: _canGoNext
                    ? context.colors.textPrimary
                    : context.colors.textMuted),
            onPressed: _canGoNext ? _nextWeek : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Calorie bar chart ─────────────────────────────────────────────────────

  Widget _buildCalorieChart(
      List<DailyRecord> records, int target) {
    final groups = <BarChartGroupData>[];
    double maxY = target.toDouble() * 1.2;

    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      final rec =
          records.where((r) => r.date == _dateStr(day)).firstOrNull;
      final consumed = rec?.consumedCalories.toDouble() ?? 0;
      if (consumed > maxY) maxY = consumed * 1.1;

      final Color barColor;
      if (rec == null || consumed == 0) {
        barColor = context.colors.surfaceVariant;
      } else if (consumed > target) {
        barColor = AppColors.error;
      } else if (consumed >= target * 0.8) {
        barColor = AppColors.primary;
      } else {
        barColor = const Color(0xFF64B5F6);
      }

      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: consumed > 0 ? consumed : 0,
            color: barColor,
            width: 22,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Calorías diarias',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.colors.textPrimary),
              ),
              const Spacer(),
              _LegendDot(color: AppColors.primary, label: 'Bueno'),
              const SizedBox(width: 10),
              _LegendDot(
                  color: const Color(0xFF64B5F6), label: 'Bajo'),
              const SizedBox(width: 10),
              _LegendDot(color: AppColors.error, label: 'Exceso'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Objetivo: $target kcal/día',
            style: TextStyle(
                fontSize: 12, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (target / 4).toDouble(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.colors.surfaceVariant,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: (target / 4).toDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${(value / 1000).toStringAsFixed(1)}k',
                          style: TextStyle(
                              fontSize: 10,
                              color: context.colors.textSecondary),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _dayAbbrs[value.toInt()],
                            style: TextStyle(
                                fontSize: 11,
                                color: context.colors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: target.toDouble(),
                      color: AppColors.primary.withOpacity(0.6),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Colors.blueGrey.shade800,
                    getTooltipItem: (group, _, rod, __) {
                      final val = rod.toY.round();
                      if (val == 0) return null;
                      return BarTooltipItem(
                        '$val kcal',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly summary ────────────────────────────────────────────────────────

  Widget _buildWeeklySummary(
      List<DailyRecord> records, NutritionProfile profile) {
    if (records.isEmpty) {
      return _buildEmptyCard(
          'Sin datos esta semana', Icons.bar_chart_outlined);
    }

    final logged = records.length;
    final totalCal =
        records.fold(0, (s, r) => s + r.consumedCalories);
    final avgCal = totalCal ~/ logged;
    final avgAdherence = records
            .fold(0.0, (s, r) => s + r.calorieAdherence) /
        logged;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de la semana',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: context.colors.textPrimary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryChip(
                value: '$logged/7',
                label: 'Días\nregistrados',
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                value: '$avgCal',
                label: 'Media\n(kcal/día)',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                value: '${(avgAdherence * 100).round()}%',
                label: 'Adherencia\nmedia',
                color: avgAdherence >= 0.9
                    ? AppColors.primary
                    : avgAdherence >= 0.7
                        ? AppColors.warning
                        : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Macros summary ────────────────────────────────────────────────────────

  Widget _buildMacrosSummary(
      List<DailyRecord> records, NutritionProfile profile) {
    if (records.isEmpty) return const SizedBox.shrink();

    final days = records.length;
    final totalProt =
        records.fold(0, (s, r) => s + r.consumedProtein);
    final totalCarbs =
        records.fold(0, (s, r) => s + r.consumedCarbs);
    final totalFat = records.fold(0, (s, r) => s + r.consumedFat);

    // Targets scaled to logged days
    final targetProt = profile.targetProtein * days;
    final targetCarbs = profile.targetCarbs * days;
    final targetFat = profile.targetFat * days;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macros acumulados ($days ${days == 1 ? 'día' : 'días'})',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: context.colors.textPrimary),
          ),
          const SizedBox(height: 14),
          _buildMacroBar(
              'Proteína', totalProt, targetProt, AppColors.protein),
          const SizedBox(height: 10),
          _buildMacroBar(
              'Carbohidratos', totalCarbs, targetCarbs, AppColors.carbs),
          const SizedBox(height: 10),
          _buildMacroBar('Grasa', totalFat, targetFat, AppColors.fat),
        ],
      ),
    );
  }

  Widget _buildMacroBar(
      String label, int consumed, int target, Color color) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final over = consumed > target;
    final barColor = over ? AppColors.error : color;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textSecondary)),
            ),
            Text('${consumed}g',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: barColor)),
            Text(' / ${target}g',
                style: TextStyle(
                    fontSize: 12, color: context.colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  // ── Day-by-day list ───────────────────────────────────────────────────────

  Widget _buildDayByDayList(
      List<DailyRecord> records, int targetCal) {
    if (records.isEmpty) return const SizedBox.shrink();

    final sorted = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalle por día',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: context.colors.textPrimary),
        ),
        const SizedBox(height: 10),
        ...sorted.map((r) => _buildDayTile(r, targetCal)),
      ],
    );
  }

  Widget _buildDayTile(DailyRecord rec, int targetCal) {
    final pct = (rec.consumedCalories / targetCal).clamp(0.0, 1.0);
    final over = rec.consumedCalories > targetCal;
    final color = over
        ? AppColors.error
        : pct >= 0.8
            ? AppColors.primary
            : const Color(0xFF64B5F6);

    // Parse date
    final parts = rec.date.split('-');
    final d = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final dayLabel =
        '${_dayAbbrs[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(dayLabel,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.colors.textPrimary)),
              const Spacer(),
              Text(
                '${rec.consumedCalories} kcal',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniMacroLabel('P: ${rec.consumedProtein}g',
                  AppColors.protein),
              _MiniMacroLabel('C: ${rec.consumedCarbs}g',
                  AppColors.carbs),
              _MiniMacroLabel('G: ${rec.consumedFat}g',
                  AppColors.fat),
              Text(
                '${(pct * 100).round()}% objetivo',
                style: TextStyle(
                    fontSize: 11, color: context.colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: context.colors.textMuted),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: context.colors.textSecondary)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryChip(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10, color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MiniMacroLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniMacroLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color));
  }
}
