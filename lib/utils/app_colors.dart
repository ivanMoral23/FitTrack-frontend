import 'package:flutter/material.dart';

/// Sistema de diseño unificado para FitTrack.
/// Usa [AppColors.of(context)] para colores que varían entre temas.
/// Los colores de marca/acento son estáticos (iguales en light y dark).
class AppColors {
  // ── Brand / Primary (igual en ambos modos) ────────────────────────────────
  static const Color primary       = Color(0xFF7C3AED); // Violet 600
  static const Color primaryDark   = Color(0xFF5B21B6); // Violet 800
  static const Color primaryLight  = Color(0xFFEDE9FE); // Violet 100
  static const Color primaryMid    = Color(0xFF8B5CF6); // Violet 500

  // ── Section accent colours (igual en ambos modos) ─────────────────────────
  static const Color homeAccent      = Color(0xFF7C3AED);
  static const Color trainingAccent  = Color(0xFF2563EB);
  static const Color dietAccent      = Color(0xFF059669);
  static const Color chatAccent      = Color(0xFF7C3AED);

  // ── Macro / nutrition (igual en ambos modos) ──────────────────────────────
  static const Color protein = Color(0xFFDC2626);
  static const Color carbs   = Color(0xFF2563EB);
  static const Color fat     = Color(0xFFD97706);

  // ── Health metrics (igual en ambos modos) ─────────────────────────────────
  static const Color steps         = Color(0xFF7C3AED);
  static const Color sleep         = Color(0xFF5B21B6);
  static const Color calories      = Color(0xFFDC2626);
  static const Color water         = Color(0xFF0284C7);
  static const Color heartRate     = Color(0xFFE11D48);
  static const Color activeMinutes = Color(0xFF059669);

  // ── Status (igual en ambos modos) ─────────────────────────────────────────
  static const Color success   = Color(0xFF059669);
  static const Color warning   = Color(0xFFD97706);
  static const Color error     = Color(0xFFDC2626);
  static const Color secondary = Color(0xFF059669);

  // ── Statics de compatibilidad (valores modo claro) ────────────────────────
  static const Color background     = Color(0xFFF3F0FA);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F7FF);
  static const Color textPrimary    = Color(0xFF1C1C2E);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textMuted      = Color(0xFF9CA3AF);

  // ── Accessor contextual ───────────────────────────────────────────────────
  static AppColorScheme of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? _dark : _light;
  }

  static const _light = AppColorScheme(
    background:     Color(0xFFF3F0FA),
    surface:        Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF8F7FF),
    textPrimary:    Color(0xFF1C1C2E),
    textSecondary:  Color(0xFF6B7280),
    textMuted:      Color(0xFF9CA3AF),
    shadowColor:    Color(0xFF1C1C2E),
    shadowOpacity:  0.06,
  );

  static const _dark = AppColorScheme(
    background:     Color(0xFF0F0F1A),
    surface:        Color(0xFF1C1C2E),
    surfaceVariant: Color(0xFF252535),
    textPrimary:    Color(0xFFF1F5F9),
    textSecondary:  Color(0xFF94A3B8),
    textMuted:      Color(0xFF64748B),
    shadowColor:    Color(0xFF000000),
    shadowOpacity:  0.30,
  );

  // ── Helpers estáticos (modo claro, compatibilidad) ────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1C1C2E).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static BoxDecoration cardDecoration({Color? bg, double radius = 20}) =>
      BoxDecoration(
        color: bg ?? surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cardShadow,
      );
}

/// Paleta de colores dependiente del tema activo.
class AppColorScheme {
  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.shadowColor,
    required this.shadowOpacity,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color shadowColor;
  final double shadowOpacity;

  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: shadowColor.withValues(alpha: shadowOpacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  BoxDecoration cardDecoration({Color? bg, double radius = 20}) =>
      BoxDecoration(
        color: bg ?? surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cardShadow,
      );
}

/// Extensión de conveniencia: `context.colors.textPrimary`
extension AppColorsX on BuildContext {
  AppColorScheme get colors => AppColors.of(this);
}
