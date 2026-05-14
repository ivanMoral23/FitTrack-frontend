import 'package:flutter/material.dart';

class ConfirmSelectionFab extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onPressed;

  const ConfirmSelectionFab({
    super.key,
    required this.selectedCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay seleccionados, devolvemos un widget vacío
    if (selectedCount == 0) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      label: Text(
        'Añadir $selectedCount',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      icon: const Icon(Icons.check),
    );
  }
}
