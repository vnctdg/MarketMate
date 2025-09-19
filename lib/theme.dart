import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final ColorScheme customColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50), // Main Green
      primary: const Color(0xFF4CAF50),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE8F5E9),
      onPrimaryContainer: const Color(0xFF1B5E20),
      secondary: const Color(0xFF00BFA5), // Teal accent
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE0F7FA),
      onSecondaryContainer: const Color(0xFF00695C),
      tertiary: const Color(0xFF42A5F5), // Light Blue accent
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE3F2FD),
      onTertiaryContainer: const Color(0xFF1565C0),
      error: const Color(0xFFE57373), // Red for errors
      onError: Colors.white,
      errorContainer: const Color(0xFFFFEBEE),
      onErrorContainer: const Color(0xFFC62828),
      background: const Color(0xFFF5F5F5), // Light grey background
      onBackground: const Color(0xFF212121),
      surface: Colors.white, // Card/dialog surface
      onSurface: const Color(0xFF212121),
      surfaceVariant: const Color(0xFFEEEEEE),
      onSurfaceVariant: const Color(0xFF616161),
      outline: const Color(0xFFBDBDBD),
      shadow: Colors.black.withOpacity(0.08),
      inverseSurface: const Color(0xFF303030),
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFFA5D6A7),
      surfaceTint: const Color(0xFF4CAF50),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: customColorScheme,
      scaffoldBackgroundColor: customColorScheme.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: customColorScheme.surface,
        foregroundColor: customColorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: customColorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      cardTheme: CardThemeData(
        color: customColorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: customColorScheme.shadow,
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: customColorScheme.surface,
        selectedTileColor: customColorScheme.primaryContainer,
        selectedColor: customColorScheme.onPrimaryContainer,
        textColor: customColorScheme.onSurface,
        iconColor: customColorScheme.onSurfaceVariant,
        subtitleTextStyle: TextStyle(color: customColorScheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: customColorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: customColorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
        contentTextStyle: TextStyle(
          color: customColorScheme.onSurface,
          fontSize: 16,
          fontFamily: 'Roboto',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: customColorScheme.surfaceVariant.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: customColorScheme.outline.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: customColorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: customColorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: customColorScheme.onSurfaceVariant.withOpacity(0.7)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        errorStyle: TextStyle(color: customColorScheme.error, fontSize: 13),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: customColorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: customColorScheme.error, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: customColorScheme.primary,
        foregroundColor: customColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: customColorScheme.primary,
          foregroundColor: customColorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
          elevation: 3,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: customColorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: customColorScheme.primary,
          foregroundColor: customColorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
          elevation: 3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: customColorScheme.surface,
        indicatorColor: customColorScheme.primaryContainer,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: customColorScheme.onPrimaryContainer, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Roboto');
          }
          return TextStyle(color: customColorScheme.onSurfaceVariant, fontSize: 12, fontFamily: 'Roboto');
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: customColorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: customColorScheme.onSurfaceVariant);
        }),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 57, color: customColorScheme.onBackground, fontFamily: 'Roboto'),
        displayMedium: TextStyle(fontSize: 45, color: customColorScheme.onBackground, fontFamily: 'Roboto'),
        displaySmall: TextStyle(fontSize: 36, color: customColorScheme.onBackground, fontFamily: 'Roboto'),
        headlineLarge: TextStyle(fontSize: 32, color: customColorScheme.onBackground, fontFamily: 'Roboto'),
        headlineMedium: TextStyle(fontSize: 28, color: customColorScheme.onBackground, fontFamily: 'Roboto'),
        headlineSmall: TextStyle(fontSize: 24, color: customColorScheme.onBackground, fontFamily: 'Roboto'),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: customColorScheme.onSurface, fontFamily: 'Roboto'),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: customColorScheme.onSurface, fontFamily: 'Roboto'),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: customColorScheme.onSurface, fontFamily: 'Roboto'),
        bodyLarge: TextStyle(fontSize: 16, color: customColorScheme.onSurface, fontFamily: 'Roboto'),
        bodyMedium: TextStyle(fontSize: 14, color: customColorScheme.onSurface, fontFamily: 'Roboto'),
        bodySmall: TextStyle(fontSize: 12, color: customColorScheme.onSurface, fontFamily: 'Roboto'),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: customColorScheme.onPrimary, fontFamily: 'Roboto'),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: customColorScheme.onSurfaceVariant, fontFamily: 'Roboto'),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: customColorScheme.onSurfaceVariant, fontFamily: 'Roboto'),
      ),
    );
  }
}