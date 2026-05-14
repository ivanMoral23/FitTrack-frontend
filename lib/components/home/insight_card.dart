import 'package:flutter/material.dart';
import 'package:fittrack_flutter/utils/app_colors.dart';

class InsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;

  const InsightCard({super.key, required this.insight});

  IconData _getIconForType(String type) {
    if (type == 'nutrition') return Icons.restaurant;
    if (type == 'training') return Icons.fitness_center;
    if (type == 'motivation') return Icons.whatshot;
    return Icons.psychology; // general
  }

  Color _getColorForType(String type) {
    if (type == 'nutrition') return Colors.green.shade400;
    if (type == 'training') return Colors.blue.shade400;
    if (type == 'motivation') return Colors.orange.shade400;
    return Colors.purple.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final type = insight['type'] ?? 'general';
    final dateBytes = insight['createdAt'] != null ? DateTime.tryParse(insight['createdAt']) : DateTime.now();
    final dateStr = dateBytes != null ? '${dateBytes.day}/${dateBytes.month} - ${dateBytes.hour}:${dateBytes.minute.toString().padLeft(2, '0')}' : 'Hoy';

    return Card(
      elevation: 6,
      shadowColor: _getColorForType(type).withOpacity(0.4),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _getColorForType(type).withOpacity(0.05),
              Colors.white.withOpacity(0.01)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getColorForType(type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Icon(_getIconForType(type), color: _getColorForType(type)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Agente Proactivo",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                insight['message'] ?? '',
                style: const TextStyle(fontSize: 15, height: 1.4),
              )
            ],
          ),
        ),
      ),
    );
  }
}
