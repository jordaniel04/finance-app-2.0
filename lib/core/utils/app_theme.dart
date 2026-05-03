import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Tokens semánticos del tema ─────────────────────────────────────────────
// En cada widget usa AppColors.of(context).xxx en vez de colores hardcodeados.

class AppColors {
  // Fondos
  final Color background;
  final Color surface;
  final Color surfaceVariant; // tarjetas secundarias, dropdown
  final Color surfaceBorder;
  final Color summaryBar; // barra inferior del dashboard

  // Acento principal
  final Color primary;
  final Color primaryMuted; // fondo de indicador nav, chips seleccionados

  // Semánticos (fijos en ambos temas)
  static const income = Color(0xFF4ADE80);
  static const expense = Color(0xFFF87171);
  static const danger = Color(0xFFF87171);

  // Texto
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;

  // Elementos de UI
  final Color iconMuted;
  final Color divider;
  final Color inputFill;
  final Color inputBorder;
  final Color monthChipUnselected;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceBorder,
    required this.summaryBar,
    required this.primary,
    required this.primaryMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.iconMuted,
    required this.divider,
    required this.inputFill,
    required this.inputBorder,
    required this.monthChipUnselected,
  });

  static AppColors of(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>();
    assert(ext != null, 'AppColorsExtension not found in theme');
    return ext!.colors;
  }
}

// ─── Tema oscuro (negro neutro) ───────────────────────────────────────────────
const _dark = AppColors(
  background: Color(0xFF111111),   // negro casi puro
  surface: Color(0xFF1E1E1E),      // gris muy oscuro para tarjetas
  surfaceVariant: Color(0xFF2A2A2A), // dropdown / variante de superficie
  surfaceBorder: Color(0xFF333333), // bordes sutiles
  summaryBar: Color(0xFF181818),
  primary: Color(0xFF5C6BC0),
  primaryMuted: Color(0x4D5C6BC0),
  textPrimary: Colors.white,
  textSecondary: Color(0xB3FFFFFF),
  textMuted: Color(0x61FFFFFF),
  textDisabled: Color(0x3DFFFFFF),
  iconMuted: Color(0x8AFFFFFF),
  divider: Color(0x1FFFFFFF),      // ~12% blanco
  inputFill: Color(0x0FFFFFFF),    // ~6% blanco
  inputBorder: Color(0x1FFFFFFF),
  monthChipUnselected: Color(0x0FFFFFFF),
);

// ─── Tema claro (beige cálido — amigable con los ojos) ────────────────────────
// Base: #F5EFE6 — crema cálido, no blanco puro. Reduce fatiga visual.
const _light = AppColors(
  background: Color(0xFFF5EFE6),   // crema cálido
  surface: Color(0xFFFFFFFF),       // blanco para tarjetas sobre crema
  surfaceVariant: Color(0xFFEDE8DF), // crema más oscuro para dropdown
  surfaceBorder: Color(0xFFDDD5C8), // borde sutil
  summaryBar: Color(0xFFEDE8DF),
  primary: Color(0xFF5C6BC0),
  primaryMuted: Color(0x265C6BC0), // 15% opacity
  textPrimary: Color(0xFF1A1A2E),   // azul muy oscuro (mismo que bg dark)
  textSecondary: Color(0xFF4A4A6A),
  textMuted: Color(0xFF8A8AAA),
  textDisabled: Color(0xFFBBBBCC),
  iconMuted: Color(0xFF6A6A8A),
  divider: Color(0xFFDDD5C8),
  inputFill: Color(0xFFF0EAE0),
  inputBorder: Color(0xFFDDD5C8),
  monthChipUnselected: Color(0xFFEDE8DF),
);

// ─── ThemeExtension para inyectar en ThemeData ───────────────────────────────

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final AppColors colors;
  const AppColorsExtension(this.colors);

  @override
  AppColorsExtension copyWith({AppColors? colors}) =>
      AppColorsExtension(colors ?? this.colors);

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) => this;
}

// ─── ThemeData completos ─────────────────────────────────────────────────────

ThemeData buildDarkTheme() => _buildTheme(_dark, Brightness.dark);
ThemeData buildLightTheme() => _buildTheme(_light, Brightness.light);

ThemeData _buildTheme(AppColors c, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    textTheme: GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    ),
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: Colors.white,
      secondary: c.primary,
      onSecondary: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: c.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: c.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.primaryMuted,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(color: c.textSecondary, fontSize: 12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.primary,
      foregroundColor: Colors.white,
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: c.primary,
      labelColor: c.textPrimary,
      unselectedLabelColor: c.iconMuted,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    extensions: [AppColorsExtension(c)],
  );
}
