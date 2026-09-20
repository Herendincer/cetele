import 'package:flutter/material.dart';

/// Çetele uygulaması için tema tanımları.
///
/// Paraşüt benzeri sade, ferah ve güven veren bir görünüm hedeflenir:
/// açık gri/beyaz zemin, canlı lacivert-mavi vurgu, gelir için zümrüt
/// yeşili ve gider için mercan kırmızısı.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryDarkColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF0EA5E9);
  static const Color incomeColor = Color(0xFF10B981);
  static const Color expenseColor = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color textPrimaryColor = Color(0xFF0F172A);
  static const Color textSecondaryColor = Color(0xFF64748B);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      textTheme: base.textTheme
          .apply(
            bodyColor: textPrimaryColor,
            displayColor: textPrimaryColor,
          )
          .copyWith(
            headlineSmall: const TextStyle(
              fontWeight: FontWeight.w700,
              color: textPrimaryColor,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w700,
              color: textPrimaryColor,
            ),
            titleMedium: const TextStyle(
              fontWeight: FontWeight.w600,
              color: textPrimaryColor,
            ),
            bodyMedium: const TextStyle(color: textSecondaryColor),
            bodySmall: const TextStyle(color: textSecondaryColor),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        elevation: 2,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primaryColor
                : textSecondaryColor,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: const IconThemeData(color: textSecondaryColor),
        selectedLabelTextStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(color: textSecondaryColor),
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF111827),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF111827),
      ),
    );
  }
}

