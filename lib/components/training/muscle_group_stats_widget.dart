import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fittrack_flutter/services/workout_service.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';

/// Widget that shows comprehensive training statistics from the user's workout history.
class MuscleGroupStatsWidget extends StatefulWidget {
  const MuscleGroupStatsWidget({super.key});

  @override
  State<MuscleGroupStatsWidget> createState() => _MuscleGroupStatsWidgetState();
}

class _MuscleGroupStatsWidgetState extends State<MuscleGroupStatsWidget>
    with SingleTickerProviderStateMixin {
  final WorkoutService _workoutService = WorkoutService();
  late final Future<List<dynamic>> _future = _workoutService.getMySessions();
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.trainingAccent));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Error al cargar estadísticas'));
        }

        final workouts = snapshot.data!;
        if (workouts.isEmpty) return _buildEmpty();

        final muscleStats = _buildMuscleStats(workouts);
        if (muscleStats.isEmpty) return _buildEmpty();

        final sortedMuscle = muscleStats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final totalSeries = sortedMuscle.fold<int>(0, (s, e) => s + e.value);

        final summary   = _buildSummary(workouts);
        final volumeData = _buildVolumeTimeline(workouts);
        final prs        = _buildPersonalRecords(workouts);
        final oneRMs     = _buildOneRMs(workouts);

        return Column(
          children: [
            // ── Summary header ──────────────────────────────────────────────
            _buildSummaryHeader(summary),

            // ── Tabs ────────────────────────────────────────────────────────
            Container(
              color: context.colors.background,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.trainingAccent,
                unselectedLabelColor: context.colors.textSecondary,
                indicatorColor: AppColors.trainingAccent,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                tabs: const [
                  Tab(text: 'Músculos'),
                  Tab(text: 'Volumen'),
                  Tab(text: 'Récords'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1 – Muscle distribution
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Distribución por Grupo Muscular'),
                        Text('$totalSeries series totales',
                            style: GoogleFonts.inter(fontSize: 12, color: context.colors.textSecondary)),
                        const SizedBox(height: 20),
                        _buildPieChart(context, sortedMuscle, totalSeries),
                        const SizedBox(height: 20),
                        _buildBarChart(context, sortedMuscle),
                        const SizedBox(height: 20),
                        _buildLegend(context, sortedMuscle, totalSeries),
                      ],
                    ),
                  ),

                  // Tab 2 – Volume over time
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Volumen por Sesión'),
                        Text('Peso total levantado (kg) por sesión',
                            style: GoogleFonts.inter(fontSize: 12, color: context.colors.textSecondary)),
                        const SizedBox(height: 20),
                        _buildVolumeChart(context, volumeData),
                        const SizedBox(height: 20),
                        _buildWeeklyVolumeSummary(workouts),
                      ],
                    ),
                  ),

                  // Tab 3 – Personal Records + 1RM
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Récords Personales'),
                        Text('Peso máximo registrado por ejercicio',
                            style: GoogleFonts.inter(fontSize: 12, color: context.colors.textSecondary)),
                        const SizedBox(height: 16),
                        _buildPRTable(context, prs),
                        const SizedBox(height: 24),
                        _sectionTitle('1RM Estimado'),
                        Text('Fórmula Epley: peso × (1 + reps/30)',
                            style: GoogleFonts.inter(fontSize: 12, color: context.colors.textSecondary)),
                        const SizedBox(height: 16),
                        _buildOneRMTable(context, oneRMs),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Data processing
  // ───────────────────────────────────────────────────────────────────────────

  Map<String, int> _buildMuscleStats(List<dynamic> workouts) {
    final Map<String, int> result = {};
    for (final session in workouts) {
      for (final ex in (session['ejercicios_realizados'] as List? ?? [])) {
        final group = ((ex['exerciseId']?['muscle_group'] as String?) ?? 'Otros').trim();
        result[group] = (result[group] ?? 0) + (ex['series'] as List? ?? []).length;
      }
    }
    return result;
  }

  Map<String, dynamic> _buildSummary(List<dynamic> workouts) {
    int totalSessions = workouts.length;
    double totalVolume = 0;
    int totalReps = 0;
    int totalSets = 0;

    for (final s in workouts) {
      for (final ex in (s['ejercicios_realizados'] as List? ?? [])) {
        for (final set in (ex['series'] as List? ?? [])) {
          final reps  = (set['reps']  as num? ?? 0).toInt();
          final weight = (set['peso'] as num? ?? 0).toDouble();
          totalSets++;
          totalReps   += reps;
          totalVolume += reps * weight;
        }
      }
    }

    return {
      'sessions': totalSessions,
      'volumeKg': totalVolume,
      'reps': totalReps,
      'sets': totalSets,
    };
  }

  List<Map<String, dynamic>> _buildVolumeTimeline(List<dynamic> workouts) {
    final sorted = List.of(workouts)..sort((a, b) {
      final da = DateTime.tryParse(a['fecha'] ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b['fecha'] ?? '') ?? DateTime(0);
      return da.compareTo(db);
    });

    return sorted.map((s) {
      double vol = 0;
      for (final ex in (s['ejercicios_realizados'] as List? ?? [])) {
        for (final set in (ex['series'] as List? ?? [])) {
          vol += (set['reps'] as num? ?? 0) * (set['peso'] as num? ?? 0);
        }
      }
      return {'fecha': s['fecha'] as String? ?? '', 'volume': vol};
    }).toList();
  }

  Map<String, double> _buildPersonalRecords(List<dynamic> workouts) {
    final Map<String, double> prs = {};
    for (final s in workouts) {
      for (final ex in (s['ejercicios_realizados'] as List? ?? [])) {
        final name = (ex['exerciseId']?['nombre'] as String?) ?? 'Ejercicio';
        for (final set in (ex['series'] as List? ?? [])) {
          final w = (set['peso'] as num? ?? 0).toDouble();
          if (w > (prs[name] ?? 0)) prs[name] = w;
        }
      }
    }
    final sorted = prs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(10));
  }

  Map<String, double> _buildOneRMs(List<dynamic> workouts) {
    final Map<String, double> best = {};
    for (final s in workouts) {
      for (final ex in (s['ejercicios_realizados'] as List? ?? [])) {
        final name = (ex['exerciseId']?['nombre'] as String?) ?? 'Ejercicio';
        for (final set in (ex['series'] as List? ?? [])) {
          final reps   = (set['reps']  as num? ?? 0).toDouble();
          final weight = (set['peso'] as num? ?? 0).toDouble();
          if (reps <= 0 || weight <= 0) continue;
          final orm = weight * (1 + reps / 30); // Epley
          if (orm > (best[name] ?? 0)) best[name] = orm;
        }
      }
    }
    final sorted = best.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(10));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Summary header
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryHeader(Map<String, dynamic> summary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: context.colors.cardDecoration(),
      child: Row(
        children: [
          Expanded(child: _SummaryItem(
            icon: Icons.event_note_rounded,
            color: AppColors.trainingAccent,
            value: '${summary['sessions']}',
            label: 'Sesiones',
          )),
          Expanded(child: _SummaryItem(
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
            value: '${((summary['volumeKg'] as double) / 1000).toStringAsFixed(1)}k',
            label: 'Kg totales',
          )),
          Expanded(child: _SummaryItem(
            icon: Icons.repeat_rounded,
            color: AppColors.dietAccent,
            value: '${summary['reps']}',
            label: 'Reps totales',
          )),
          Expanded(child: _SummaryItem(
            icon: Icons.layers_rounded,
            color: AppColors.calories,
            value: '${summary['sets']}',
            label: 'Series totales',
          )),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Pie chart
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildPieChart(BuildContext context, List<MapEntry<String, int>> sorted, int total) {
    final colors = _paletteFor(sorted.length);
    final pieChart = SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: List.generate(sorted.length, (i) {
            final pct = sorted[i].value / total * 100;
            return PieChartSectionData(
              value: sorted[i].value.toDouble(),
              color: colors[i],
              radius: 55,
              title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }),
        ),
      ),
    );

    final legend = Wrap(
      spacing: 12,
      runSpacing: 6,
      children: List.generate(sorted.length > 6 ? 6 : sorted.length, (i) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(sorted[i].key, style: GoogleFonts.inter(fontSize: 12)),
        ],
      )),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // On wide screens use a side-by-side Row; on narrow screens stack vertically
        if (constraints.maxWidth >= 400) {
          return Row(
            children: [
              Expanded(flex: 2, child: pieChart),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: legend),
            ],
          );
        } else {
          return Column(
            children: [
              pieChart,
              const SizedBox(height: 16),
              legend,
            ],
          );
        }
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Bar chart (muscle distribution)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBarChart(BuildContext context, List<MapEntry<String, int>> sorted) {
    final colors  = _paletteFor(sorted.length);
    final maxVal  = sorted.first.value.toDouble();
    return _StatCard(
      title: 'Distribución de series',
      child: Column(
        children: List.generate(sorted.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 96, child: Text(sorted[i].key, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sorted[i].value / maxVal,
                      minHeight: 10,
                      backgroundColor: context.colors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(colors[i]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${sorted[i].value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Legend
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildLegend(BuildContext context, List<MapEntry<String, int>> sorted, int total) {
    final colors = _paletteFor(sorted.length);
    return _StatCard(
      title: 'Detalle',
      child: Column(
        children: List.generate(sorted.length, (i) {
          final pct = (sorted[i].value / total * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(sorted[i].key, style: GoogleFonts.inter(fontSize: 13))),
                Text('${sorted[i].value} series', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('$pct%', style: GoogleFonts.inter(fontSize: 12, color: context.colors.textSecondary)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Volume line chart
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildVolumeChart(BuildContext context, List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final last = data.length > 12 ? data.sublist(data.length - 12) : data;
    final maxY = last.map((e) => e['volume'] as double).reduce((a, b) => a > b ? a : b);

    final spots = List.generate(last.length,
        (i) => FlSpot(i.toDouble(), (last[i]['volume'] as double)));

    return _StatCard(
      title: 'Volumen por sesión (últimas ${last.length} sesiones)',
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.15,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(color: context.colors.surfaceVariant, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, _) => Text(
                    v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                    style: GoogleFonts.inter(fontSize: 10, color: context.colors.textSecondary),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: last.length > 6 ? 2 : 1,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= last.length) return const SizedBox.shrink();
                    final dateStr = last[idx]['fecha'] as String? ?? '';
                    if (dateStr.length < 10) return const SizedBox.shrink();
                    final d = DateTime.tryParse(dateStr);
                    if (d == null) return const SizedBox.shrink();
                    return Text('${d.day}/${d.month}',
                        style: GoogleFonts.inter(fontSize: 9, color: context.colors.textSecondary));
                  },
                ),
              ),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.trainingAccent,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.trainingAccent,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.trainingAccent.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyVolumeSummary(List<dynamic> workouts) {
    final now = DateTime.now();
    double thisWeek = 0, lastWeek = 0;
    final startThis = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final startLast = startThis.subtract(const Duration(days: 7));

    for (final s in workouts) {
      final d = DateTime.tryParse(s['fecha'] ?? '');
      if (d == null) continue;
      double vol = 0;
      for (final ex in (s['ejercicios_realizados'] as List? ?? [])) {
        for (final set in (ex['series'] as List? ?? [])) {
          vol += (set['reps'] as num? ?? 0) * (set['peso'] as num? ?? 0);
        }
      }
      if (!d.isBefore(startThis)) thisWeek += vol;
      else if (!d.isBefore(startLast) && d.isBefore(startThis)) lastWeek += vol;
    }

    final diff = thisWeek - lastWeek;
    final trend = lastWeek == 0 ? null : diff / lastWeek * 100;

    return _StatCard(
      title: 'Comparación semanal de volumen',
      child: Row(
        children: [
          Expanded(child: _WeekCompItem(label: 'Esta semana', valueKg: thisWeek, color: AppColors.trainingAccent)),
          const SizedBox(width: 12),
          Expanded(child: _WeekCompItem(label: 'Semana pasada', valueKg: lastWeek, color: context.colors.textSecondary)),
          if (trend != null) ...[
            const SizedBox(width: 12),
            Column(
              children: [
                Icon(
                  trend >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: trend >= 0 ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                Text(
                  '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: trend >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PR table
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildPRTable(BuildContext context, Map<String, double> prs) {
    if (prs.isEmpty) {
      return Center(child: Text('Sin datos de peso registrados.',
          style: GoogleFonts.inter(color: context.colors.textSecondary)));
    }
    return _StatCard(
      title: 'Máximo peso levantado',
      child: Column(
        children: prs.entries.toList().asMap().entries.map((entry) {
          final i     = entry.key;
          final name  = entry.value.key;
          final maxW  = entry.value.value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: i > 0 ? Border(top: BorderSide(color: context.colors.surfaceVariant)) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                         : i == 1 ? context.colors.surfaceVariant
                         : const Color(0xFFCD7F32).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                            color: i == 0 ? const Color(0xFFB7950B)
                                 : i == 1 ? context.colors.textSecondary
                                 : const Color(0xFF7D6608))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 13, color: context.colors.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.trainingAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${maxW.toStringAsFixed(1)} kg',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.trainingAccent)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1RM table
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildOneRMTable(BuildContext context, Map<String, double> orms) {
    if (orms.isEmpty) {
      return Center(child: Text('Sin datos suficientes para estimar 1RM.',
          style: GoogleFonts.inter(color: context.colors.textSecondary)));
    }
    return _StatCard(
      title: '1RM estimado',
      child: Column(
        children: orms.entries.toList().asMap().entries.map((entry) {
          final i   = entry.key;
          final name = entry.value.key;
          final orm  = entry.value.value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: i > 0 ? Border(top: BorderSide(color: context.colors.surfaceVariant)) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 13, color: context.colors.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${orm.toStringAsFixed(1)} kg',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Empty state
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Completa tu primer entrenamiento\npara ver estadísticas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Builder(
    builder: (context) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
    ),
  );

  List<Color> _paletteFor(int count) {
    const seed = AppColors.trainingAccent;
    final base = HSLColor.fromColor(seed);
    return List.generate(count, (i) {
      final hue = (base.hue + i * (360 / (count == 1 ? 1 : count))) % 360;
      return HSLColor.fromAHSL(1, hue, 0.65, 0.50).toColor();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared stat widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.colors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textPrimary)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: context.colors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}

class _WeekCompItem extends StatelessWidget {
  const _WeekCompItem({required this.label, required this.valueKg, required this.color});
  final String label;
  final double valueKg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.colors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          valueKg >= 1000 ? '${(valueKg / 1000).toStringAsFixed(1)}k kg' : '${valueKg.toStringAsFixed(0)} kg',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

