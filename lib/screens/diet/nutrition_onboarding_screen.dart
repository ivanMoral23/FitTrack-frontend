import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_profile.dart';
import '../../services/nutrition_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/nutrition_calculator.dart';

class NutritionOnboardingScreen extends StatefulWidget {
  const NutritionOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<NutritionOnboardingScreen> createState() =>
      _NutritionOnboardingScreenState();
}

class _NutritionOnboardingScreenState
    extends State<NutritionOnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 0 – physical data
  final _step0Key = GlobalKey<FormState>();
  double _weight = 70;
  double _height = 170;
  int _age = 25;
  Gender _gender = Gender.male;

  // Step 1 – goal
  Goal _goal = Goal.maintain;

  // Step 2 – activity level
  ActivityLevel _activityLevel = ActivityLevel.moderate;

  // Step 3 – summary / dietary preference
  DietaryPreference _preference = DietaryPreference.standard;
  bool _saving = false;

  // ── Computed summary values ───────────────────────────────────────────────

  int get _maintenance => NutritionCalculator.calculateMaintenanceCalories(
        weight: _weight,
        height: _height,
        age: _age,
        gender: _gender,
        activityLevel: _activityLevel,
      );

  int get _targetCalories =>
      NutritionCalculator.calculateTargetCalories(_maintenance, _goal);

  Map<String, int> get _macros =>
      NutritionCalculator.calculateMacros(_targetCalories, _weight, _preference);

  // ── Navigation ────────────────────────────────────────────────────────────

  void _next() {
    if (_currentPage == 0 && !_step0Key.currentState!.validate()) return;
    if (_currentPage == 0) _step0Key.currentState!.save();

    if (_currentPage < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final service = context.read<NutritionService>();

    final profile = NutritionProfile(
      id: service.userProfile.id,
      weight: _weight,
      height: _height,
      age: _age,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      preference: _preference,
      mealsPerDay: service.userProfile.mealsPerDay,
    );

    await service.updateUserProfile(profile);
    await service.markOnboardingDone();

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0(),
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i <= _currentPage
                        ? AppColors.primary
                        : AppColors.primaryLight,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'Paso ${_currentPage + 1} de 4',
            style: TextStyle(
                fontSize: 12, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Navigation buttons ────────────────────────────────────────────────────

  Widget _buildNavButtons() {
    final isLast = _currentPage == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _back,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.primaryLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Atrás'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving ? null : (isLast ? _finish : _next),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isLast ? 'Guardar y empezar' : 'Siguiente',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Physical data ─────────────────────────────────────────────────

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Cuéntanos sobre ti',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Necesitamos estos datos para calcular tus objetivos nutricionales.',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 24),
          Form(
            key: _step0Key,
            child: Column(
              children: [
                // Gender
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Género',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: Gender.values.map((g) {
                    final selected = _gender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = g),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : context.colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            g.displayName,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        label: 'Peso (kg)',
                        initial: _weight.toString(),
                        suffix: 'kg',
                        onSaved: (v) => _weight = double.parse(v!),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null) return 'Número inválido';
                          if (n < 20 || n > 500) return '20–500 kg';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        label: 'Altura (cm)',
                        initial: _height.toString(),
                        suffix: 'cm',
                        onSaved: (v) => _height = double.parse(v!),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null) return 'Número inválido';
                          if (n < 100 || n > 280) return '100–280 cm';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  label: 'Edad',
                  initial: _age.toString(),
                  suffix: 'años',
                  isInt: true,
                  onSaved: (v) => _age = int.parse(v!),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Número inválido';
                    if (n < 14 || n > 100) return '14–100 años';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Goal ──────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final goals = [
      (Goal.loseFat, Icons.trending_down, 'Perder grasa', 'Déficit calórico controlado', const Color(0xFFE53935)),
      (Goal.maintain, Icons.balance, 'Mantener peso', 'Mantenimiento energético', const Color(0xFF1E88E5)),
      (Goal.buildMuscle, Icons.trending_up, 'Ganar músculo', 'Superávit calórico limpio', const Color(0xFF43A047)),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '¿Cuál es tu objetivo?',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Esto ajustará tus calorías y macros recomendados.',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 24),
          ...goals.map((entry) {
            final (goal, icon, title, subtitle, color) = entry;
            final selected = _goal == goal;
            return GestureDetector(
              onTap: () => setState(() => _goal = goal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.08)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? color : context.colors.surfaceVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? color
                                      : context.colors.textPrimary)),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textSecondary)),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, color: color, size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 2: Activity level ────────────────────────────────────────────────

  Widget _buildStep2() {
    final levels = [
      (ActivityLevel.sedentary, Icons.chair_outlined, 'Sedentario', 'Sin ejercicio o mínimo'),
      (ActivityLevel.light, Icons.directions_walk, 'Ligero', '1–3 días/semana'),
      (ActivityLevel.moderate, Icons.directions_bike, 'Moderado', '3–5 días/semana'),
      (ActivityLevel.active, Icons.fitness_center, 'Activo', '6–7 días/semana'),
      (ActivityLevel.veryActive, Icons.flash_on, 'Muy activo', '2 sesiones diarias'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '¿Cuánto te mueves?',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'El nivel de actividad es clave para calcular tu gasto calórico.',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 24),
          ...levels.map((entry) {
            final (level, icon, title, subtitle) = entry;
            final selected = _activityLevel == level;
            return GestureDetector(
              onTap: () => setState(() => _activityLevel = level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withOpacity(0.08)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : context.colors.surfaceVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        color: selected
                            ? AppColors.primary
                            : context.colors.textSecondary,
                        size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? AppColors.primary
                                      : context.colors.textPrimary)),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textSecondary)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 3: Summary ───────────────────────────────────────────────────────

  Widget _buildStep3() {
    final target = _targetCalories;
    final macros = _macros;
    final protein = macros['protein'] ?? 0;
    final carbs = macros['carbs'] ?? 0;
    final fat = macros['fat'] ?? 0;
    final belowMin =
        NutritionCalculator.isBelowMinimum(target, _gender);
    final goalAdjustment = _goal == Goal.loseFat
        ? '-500 kcal déficit'
        : _goal == Goal.buildMuscle
            ? '+300 kcal superávit'
            : 'mantenimiento';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Tu plan nutricional',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Basado en tus datos, estos son tus objetivos recomendados.',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Calorie card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.85),
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Calorías objetivo',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    Text(goalAdjustment,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$target kcal/día',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mantenimiento: $_maintenance kcal',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          if (belowMin) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resultado por debajo del mínimo recomendado (${NutritionCalculator.getMinimumCalories(_gender)} kcal). Revisa tus datos.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Macros row
          Row(
            children: [
              _buildMacroCard('Proteína', protein, 'g', AppColors.protein),
              const SizedBox(width: 10),
              _buildMacroCard('Carbohid.', carbs, 'g', AppColors.carbs),
              const SizedBox(width: 10),
              _buildMacroCard('Grasa', fat, 'g', AppColors.fat),
            ],
          ),

          const SizedBox(height: 20),

          // Dietary preference
          Text(
            'Preferencia alimentaria',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<DietaryPreference>(
            value: _preference,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: DietaryPreference.values.map((p) {
              return DropdownMenuItem(
                  value: p,
                  child: Text(p.displayName,
                      overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) => setState(() => _preference = v!),
          ),

          const SizedBox(height: 8),
          Text(
            'Cambiar la preferencia ajusta la distribución de macros.',
            style:
                TextStyle(fontSize: 12, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
      String label, int value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$value$unit',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildNumberField({
    required String label,
    required String initial,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    String? suffix,
    bool isInt = false,
  }) {
    return TextFormField(
      initialValue: initial,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: context.colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}
