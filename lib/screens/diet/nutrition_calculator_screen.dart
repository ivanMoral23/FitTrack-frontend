import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/nutrition_calculator.dart';
import '../../models/nutrition_profile.dart';

class NutritionCalculatorScreen extends StatefulWidget {
  const NutritionCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<NutritionCalculatorScreen> createState() =>
      _NutritionCalculatorScreenState();
}

class _NutritionCalculatorScreenState
    extends State<NutritionCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  double _weight = 70.0;
  double _height = 175.0;
  int _age = 25;
  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  Goal _goal = Goal.maintain;
  DietaryPreference _preference = DietaryPreference.standard;

  int? _calculatedCalories;
  int? _maintenanceCalories;
  Map<String, int>? _calculatedMacros;
  bool _calculating = false;
  bool _belowMinimum = false;

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _calculating = true;
      _calculatedCalories = null;
      _calculatedMacros = null;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    final maintenance = NutritionCalculator.calculateMaintenanceCalories(
      weight: _weight,
      height: _height,
      age: _age,
      gender: _gender,
      activityLevel: _activityLevel,
    );

    final target =
        NutritionCalculator.calculateTargetCalories(maintenance, _goal);

    final macros =
        NutritionCalculator.calculateMacros(target, _weight, _preference);

    if (!mounted) return;
    setState(() {
      _maintenanceCalories = maintenance;
      _calculatedCalories = target;
      _calculatedMacros = macros;
      _belowMinimum = NutritionCalculator.isBelowMinimum(target, _gender);
      _calculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Calculadora Nutricional',
            style: TextStyle(color: context.colors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Introduce tus datos para calcular tus necesidades calóricas diarias y la distribución de macronutrientes.',
              style:
                  TextStyle(color: context.colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Datos físicos
                  _sectionLabel('Datos físicos'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Peso (kg)',
                          initialValue: _weight.toString(),
                          onSaved: (v) => _weight = double.parse(v!),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n < 20 || n > 500) {
                              return 'Entre 20-500';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Altura (cm)',
                          initialValue: _height.toString(),
                          onSaved: (v) => _height = double.parse(v!),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n < 100 || n > 280) {
                              return 'Entre 100-280';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Edad',
                          initialValue: _age.toString(),
                          isInt: true,
                          onSaved: (v) => _age = int.parse(v!),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 14 || n > 100) {
                              return 'Entre 14-100';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<Gender>(
                    label: 'Género',
                    value: _gender,
                    items: Gender.values,
                    getName: (g) => g.displayName,
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                  const SizedBox(height: 20),

                  // Actividad y objetivos
                  _sectionLabel('Actividad y objetivos'),
                  const SizedBox(height: 10),
                  _buildDropdown<ActivityLevel>(
                    label: 'Nivel de actividad',
                    value: _activityLevel,
                    items: ActivityLevel.values,
                    getName: (a) => a.displayName,
                    onChanged: (v) => setState(() => _activityLevel = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<Goal>(
                    label: 'Objetivo',
                    value: _goal,
                    items: Goal.values,
                    getName: (g) => g.displayName,
                    onChanged: (v) => setState(() => _goal = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<DietaryPreference>(
                    label: 'Preferencia alimentaria',
                    value: _preference,
                    items: DietaryPreference.values,
                    getName: (p) => p.displayName,
                    onChanged: (v) => setState(() => _preference = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _calculating ? null : _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _calculating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Calcular',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Resultados
            if (_calculatedCalories != null && _calculatedMacros != null) ...[
              const Divider(),
              const SizedBox(height: 20),
              Text(
                'Resultados',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary),
              ),
              const SizedBox(height: 16),

              if (_belowMinimum)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El objetivo calculado (${_calculatedCalories} kcal) está por debajo del mínimo recomendado para tu perfil. Considera ajustar tu actividad o goal.',
                          style: TextStyle(
                              color: context.colors.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$_calculatedCalories kcal/día',
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark),
                    ),
                    if (_maintenanceCalories != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Mantenimiento: $_maintenanceCalories kcal',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.colors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMacroResult(
                          'Proteínas',
                          '${_calculatedMacros!['protein']}g',
                          AppColors.protein,
                        ),
                        _buildMacroResult(
                          'Carbohi.',
                          '${_calculatedMacros!['carbs']}g',
                          AppColors.carbs,
                        ),
                        _buildMacroResult(
                          'Grasas',
                          '${_calculatedMacros!['fat']}g',
                          AppColors.fat,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Estos valores son estimaciones basadas en la ecuación de Mifflin-St Jeor. Consulta con un profesional de la nutrición para un plan personalizado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String initialValue,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    bool isInt = false,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: context.colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) getName,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: context.colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(getName(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMacroResult(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style:
              TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}
