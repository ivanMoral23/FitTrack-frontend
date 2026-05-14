import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/nutrition_service.dart';
import '../../models/nutrition_profile.dart';
import '../../utils/app_colors.dart';
import '../../utils/nutrition_calculator.dart';
import '../../components/diet/section_header.dart';

class UserNutritionProfileScreen extends StatefulWidget {
  const UserNutritionProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserNutritionProfileScreen> createState() =>
      _UserNutritionProfileScreenState();
}

class _UserNutritionProfileScreenState
    extends State<UserNutritionProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _mealsCtrl;

  late double _weight;
  late double _height;
  late int _age;
  late Gender _gender;
  late ActivityLevel _activityLevel;
  late Goal _goal;
  late DietaryPreference _preference;
  late int _mealsPerDay;

  bool _isLoading = false;
  bool _profileSynced = false;

  @override
  void initState() {
    super.initState();
    final profile =
        Provider.of<NutritionService>(context, listen: false).userProfile;
    _weightCtrl = TextEditingController(text: profile.weight.toString());
    _heightCtrl = TextEditingController(text: profile.height.toString());
    _ageCtrl = TextEditingController(text: profile.age.toString());
    _mealsCtrl = TextEditingController(text: profile.mealsPerDay.toString());
    _weight = profile.weight;
    _height = profile.height;
    _age = profile.age;
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _goal = profile.goal;
    _preference = profile.preference;
    _mealsPerDay = profile.mealsPerDay;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync form once real data has been loaded from API/SharedPreferences
    final service = Provider.of<NutritionService>(context);
    if (service.prefsLoaded && !_profileSynced) {
      _profileSynced = true;
      final profile = service.userProfile;
      _weightCtrl.text = profile.weight.toString();
      _heightCtrl.text = profile.height.toString();
      _ageCtrl.text = profile.age.toString();
      _mealsCtrl.text = profile.mealsPerDay.toString();
      setState(() {
        _weight = profile.weight;
        _height = profile.height;
        _age = profile.age;
        _gender = profile.gender;
        _activityLevel = profile.activityLevel;
        _goal = profile.goal;
        _preference = profile.preference;
        _mealsPerDay = profile.mealsPerDay;
      });
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _mealsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrige los campos marcados en rojo antes de guardar.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final service = Provider.of<NutritionService>(context, listen: false);
    final updated = service.userProfile.copyWith(
      weight: _weight,
      height: _height,
      age: _age,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      preference: _preference,
      mealsPerDay: _mealsPerDay,
    );

    await service.updateUserProfile(updated);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show warning if calories are below safe minimum
    final targetCals = service.userProfile.targetCalories;
    if (NutritionCalculator.isBelowMinimum(targetCals, _gender)) {
      final min = NutritionCalculator.getMinimumCalories(_gender);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perfil guardado, pero tu objetivo ($targetCals kcal) está por debajo del mínimo recomendado ($min kcal).',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado y objetivos recalculados.'),
          backgroundColor: AppColors.success,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<NutritionService>(context);
    final isInitializing = !service.prefsLoaded;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Mi Perfil Físico',
            style: TextStyle(color: context.colors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: (isInitializing || _isLoading)
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Datos Personales'),
                    _buildNumberField(
                      label: 'Peso actual (kg)',
                      controller: _weightCtrl,
                      suffix: 'kg',
                      onSaved: (v) => _weight = double.parse(v!),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null) return 'Introduce un número válido';
                        if (n < 20 || n > 500) return 'Peso entre 20 y 500 kg';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      label: 'Altura (cm)',
                      controller: _heightCtrl,
                      suffix: 'cm',
                      onSaved: (v) => _height = double.parse(v!),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null) return 'Introduce un número válido';
                        if (n < 100 || n > 280) return 'Altura entre 100 y 280 cm';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      label: 'Edad',
                      controller: _ageCtrl,
                      suffix: 'años',
                      isInt: true,
                      onSaved: (v) => _age = int.parse(v!),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null) return 'Introduce un número entero';
                        if (n < 14 || n > 100) return 'Edad entre 14 y 100 años';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<Gender>(
                      label: 'Género',
                      value: _gender,
                      items: Gender.values,
                      getName: (g) => g.displayName,
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Nivel y Objetivos'),
                    _buildDropdown<ActivityLevel>(
                      label: 'Nivel de Actividad',
                      value: _activityLevel,
                      items: ActivityLevel.values,
                      getName: (a) => a.displayName,
                      onChanged: (v) => setState(() => _activityLevel = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<Goal>(
                      label: 'Objetivo Principal',
                      value: _goal,
                      items: Goal.values,
                      getName: (g) => g.displayName,
                      onChanged: (v) => setState(() => _goal = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<DietaryPreference>(
                      label: 'Preferencia Alimentaria',
                      value: _preference,
                      items: DietaryPreference.values,
                      getName: (p) => p.displayName,
                      onChanged: (v) => setState(() => _preference = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      label: 'Comidas al día',
                      controller: _mealsCtrl,
                      isInt: true,
                      onSaved: (v) => _mealsPerDay = int.parse(v!),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null) return 'Introduce un número entero';
                        if (n < 2 || n > 8) return 'Entre 2 y 8 comidas al día';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Guardar y Recalcular',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    String? suffix,
    bool isInt = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}
