import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/meal.dart';
import '../../models/food_item.dart';
import '../../services/nutrition_service.dart';
import '../../services/usda_food_service.dart';
import '../../utils/app_colors.dart';
import '../../data/food_database.dart';

class AddManualMealScreen extends StatefulWidget {
  const AddManualMealScreen({Key? key}) : super(key: key);

  @override
  State<AddManualMealScreen> createState() => _AddManualMealScreenState();
}

class _AddManualMealScreenState extends State<AddManualMealScreen> {
  final _mealFormKey = GlobalKey<FormState>();
  final _itemFormKey = GlobalKey<FormState>();

  final _mealNameController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _portionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  MealType _selectedMealType = MealType.snack;
  final List<FoodItem> _items = [];

  @override
  void dispose() {
    _mealNameController.dispose();
    _itemNameController.dispose();
    _portionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _addItemFromDatabase(FoodDatabaseItem food) {
    setState(() {
      _items.add(FoodItem(
        id: const Uuid().v4(),
        name: food.name,
        portion: food.portion,
        calories: food.calories,
        protein: food.protein,
        carbs: food.carbs,
        fat: food.fat,
      ));
    });
  }

  void _showFoodSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FoodSearchSheet(
        onFoodSelected: (food) {
          Navigator.pop(ctx);
          _addItemFromDatabase(food);
        },
      ),
    );
  }

  void _addItem() {
    if (!_itemFormKey.currentState!.validate()) return;
    _itemFormKey.currentState!.save();

    setState(() {
      _items.add(FoodItem(
        id: const Uuid().v4(),
        name: _itemNameController.text.trim(),
        portion: _portionController.text.trim().isEmpty
            ? '1 ración'
            : _portionController.text.trim(),
        calories: int.tryParse(_caloriesController.text) ?? 0,
        protein: int.tryParse(_proteinController.text) ?? 0,
        carbs: int.tryParse(_carbsController.text) ?? 0,
        fat: int.tryParse(_fatController.text) ?? 0,
      ));

      _itemNameController.clear();
      _portionController.clear();
      _caloriesController.clear();
      _proteinController.clear();
      _carbsController.clear();
      _fatController.clear();

      _itemFormKey.currentState!.reset();
    });
  }

  void _saveMeal() {
    if (!_mealFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ponle un nombre a la comida antes de guardar.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // If the item form has data filled but wasn't explicitly added, auto-add it first
    if (_itemNameController.text.trim().isNotEmpty) {
      if (!_itemFormKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Corrige los errores del alimento antes de guardar.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      _addItem();
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un alimento antes de guardar.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final newMeal = Meal(
      id: const Uuid().v4(),
      name: _mealNameController.text.trim(),
      items: List.from(_items),
      isCompleted: true,
      mealType: _selectedMealType,
    );

    Provider.of<NutritionService>(context, listen: false).addCustomMeal(newMeal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comida "${newMeal.name}" añadida correctamente.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  int get _totalCalories => _items.fold(0, (s, i) => s + i.calories);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Añadir Comida Manual',
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
            // ── Datos de la comida ──────────────────────────────
            Form(
              key: _mealFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _mealNameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la comida',
                      hintText: 'Ej: Merienda, Post-entreno...',
                      filled: true,
                      fillColor: context.colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Introduce un nombre para la comida';
                      }
                      if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<MealType>(
                    label: 'Momento del día',
                    value: _selectedMealType,
                    items: MealType.values,
                    getName: (t) => t.displayName,
                    onChanged: (v) => setState(() => _selectedMealType = v!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Alimentos ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Añadir Alimentos',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: _showFoodSearch,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Buscar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search hint chip
            GestureDetector(
              onTap: _showFoodSearch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.library_books_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Buscar en base de datos de alimentos',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _itemFormKey,
                  child: Column(
                    children: [
                      _buildItemField(
                        controller: _itemNameController,
                        label: 'Nombre del alimento *',
                        hint: 'Ej: Pollo, Arroz...',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildItemField(
                        controller: _portionController,
                        label: 'Porción (opcional)',
                        hint: 'Ej: 100g, 1 taza...',
                      ),
                      const SizedBox(height: 10),
                      _buildNumericRow(
                        children: [
                          _buildNumericField(
                            controller: _caloriesController,
                            label: 'Calorías *',
                            suffix: 'kcal',
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 0) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildNumericRow(
                        children: [
                          _buildNumericField(
                            controller: _proteinController,
                            label: 'Proteína',
                            suffix: 'g',
                            validator: _validateMacro,
                          ),
                          _buildNumericField(
                            controller: _carbsController,
                            label: 'Carboh.',
                            suffix: 'g',
                            validator: _validateMacro,
                          ),
                          _buildNumericField(
                            controller: _fatController,
                            label: 'Grasa',
                            suffix: 'g',
                            validator: _validateMacro,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir este alimento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Alimentos añadidos ─────────────────────────────
            if (_items.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alimentos añadidos (${_items.length})',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary),
                  ),
                  Text(
                    'Total: $_totalCalories kcal',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  color: AppColors.primaryLight.withOpacity(0.2),
                  child: ListTile(
                    dense: true,
                    title: Text(item.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${item.portion}  •  ${item.calories} kcal  •  ${item.protein}P ${item.carbs}C ${item.fat}G',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      onPressed: () =>
                          setState(() => _items.removeAt(index)),
                      tooltip: 'Quitar alimento',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            if (_items.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryLight,
                      style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.restaurant,
                        size: 40, color: context.colors.textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'Aún no has añadido alimentos.\nUsa el buscador o el formulario de arriba.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _saveMeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'GUARDAR COMIDA',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String? _validateMacro(String? v) {
    if (v == null || v.isEmpty) return null;
    final n = int.tryParse(v);
    if (n == null || n < 0) return 'Valor inválido';
    if (n > 9999) return 'Valor demasiado alto';
    return null;
  }

  Widget _buildItemField({
    required TextEditingController controller,
    required String label,
    String? hint,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: context.colors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildNumericRow({required List<Widget> children}) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
        filled: true,
        fillColor: context.colors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
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

// ── Food search bottom sheet ─────────────────────────────────────────────────

class _FoodSearchSheet extends StatefulWidget {
  final void Function(FoodDatabaseItem) onFoodSelected;

  const _FoodSearchSheet({required this.onFoodSelected});

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  final _searchController = TextEditingController();
  List<FoodDatabaseItem> _results = FoodDatabase.items;
  String? _activeCategory;
  bool _isLoading = false;
  bool _isApiSource = false;
  String? _errorMessage;
  bool _isInfoMessage = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim();
    _debounce?.cancel();

    if (q.isEmpty) {
      setState(() {
        _activeCategory = null;
        _results = FoodDatabase.items;
        _isLoading = false;
        _isApiSource = false;
        _errorMessage = null;
        _isInfoMessage = false;
      });
      return;
    }

    setState(() {
      _activeCategory = null;
      _isLoading = true;
      _errorMessage = null;
      _isInfoMessage = false;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () => _searchUsda(q));
  }

  Future<void> _searchUsda(String query) async {
    try {
      final results = await UsdaFoodService.search(query);
      if (!mounted) return;
      setState(() {
        _results = results.isNotEmpty ? results : FoodDatabase.search(query);
        _isApiSource = results.isNotEmpty;
        _isLoading = false;
        _errorMessage = results.isEmpty ? 'Sin resultados — mostrando base local' : null;
        _isInfoMessage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = FoodDatabase.search(query);
        _isApiSource = false;
        _isLoading = false;
        _errorMessage = 'Sin conexión — mostrando resultados locales';
        _isInfoMessage = false;
      });
    }
  }

  void _filterByCategory(String? cat) {
    _debounce?.cancel();
    setState(() {
      _activeCategory = cat;
      _searchController.clear();
      _isApiSource = false;
      _isLoading = false;
      _errorMessage = null;
      _isInfoMessage = false;
      if (cat == null) {
        _results = FoodDatabase.items;
      } else {
        _results = FoodDatabase.items
            .where((f) => f.category == cat)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = FoodDatabase.categories;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Buscar alimentos',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  if (_isApiSource)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'USDA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      '${_results.length} resultados',
                      style: TextStyle(
                          fontSize: 12, color: context.colors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar alimento...',
                  prefixIcon:
                      Icon(Icons.search, color: context.colors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: context.colors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _filterByCategory(_activeCategory);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Category chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'Todos',
                    selected: _activeCategory == null,
                    onTap: () => _filterByCategory(null),
                  ),
                  ...categories.map((cat) => _CategoryChip(
                        label: cat,
                        selected: _activeCategory == cat,
                        onTap: () => _filterByCategory(cat),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_isInfoMessage ? Colors.blue : AppColors.warning).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_isInfoMessage ? Colors.blue : AppColors.warning).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isInfoMessage ? Icons.info_outline : Icons.wifi_off,
                        size: 14,
                        color: _isInfoMessage ? Colors.blue : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 11,
                            color: _isInfoMessage ? Colors.blue : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 1),
            // Results list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            'Buscando alimentos...',
                            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 48, color: context.colors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'Sin resultados',
                                style:
                                    TextStyle(color: context.colors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 16),
                          itemBuilder: (context, index) {
                            final food = _results[index];
                            return ListTile(
                              title: Text(food.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              subtitle: Text(
                                '${food.portion}  •  ${food.calories} kcal',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.textSecondary),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _MacroChip('${food.protein}P',
                                      AppColors.protein),
                                  const SizedBox(width: 4),
                                  _MacroChip(
                                      '${food.carbs}C', AppColors.carbs),
                                  const SizedBox(width: 4),
                                  _MacroChip('${food.fat}G', AppColors.fat),
                                ],
                              ),
                              onTap: () => widget.onFoodSelected(food),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MacroChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color),
      ),
    );
  }
}
