import 'package:flutter/material.dart';

class SetTrackerRow extends StatelessWidget {
  final int setIndex;
  final int reps;
  final double weight;
  final bool isCompleted;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<bool> onCompletionToggled;

  const SetTrackerRow({
    super.key,
    required this.setIndex,
    required this.reps,
    required this.weight,
    required this.isCompleted,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onCompletionToggled,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isCompleted 
        ? Colors.green.withOpacity(0.15) 
        : Colors.grey.withOpacity(isDark ? 0.2 : 0.1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Número de serie
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withOpacity(isDark ? 0.3 : 0.2) : Colors.grey.withOpacity(isDark ? 0.3 : 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${setIndex + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCompleted 
                    ? (isDark ? Colors.green.shade200 : Colors.green.shade800)
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Input Peso
          Expanded(
            child: TextFormField(
              initialValue: weight == 0 ? '' : weight.toString().replaceAll(RegExp(r'\.0$'), ''),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                hintText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              onChanged: (val) {
                onWeightChanged(double.tryParse(val) ?? 0.0);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Input Reps
          Expanded(
            child: TextFormField(
              initialValue: reps == 0 ? '' : reps.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                hintText: 'reps',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              onChanged: (val) {
                onRepsChanged(int.tryParse(val) ?? 0);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Botón Completado
          GestureDetector(
            onTap: () => onCompletionToggled(!isCompleted),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey.withOpacity(isDark ? 0.4 : 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check,
                color: isCompleted ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 28,
              ),
            ),
          )
        ],
      ),
    );
  }
}
