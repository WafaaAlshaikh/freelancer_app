// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // --- (Core) ---
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF4A42D4);

  static const Color secondary = Color(0xFF14A800);
  static const Color secondaryLight = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF0D7A00);

  // --- (Backgrounds) ---
  static const Color lightBackground = Color(0xFFF5F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFF2D2B55);

  static const Color darkBackground = Color(0xFF0D0B1E);
  static const Color darkSurface = Color(0xFF1E1B3B);  
  static const Color darkSidebar = Color(0xFF122543);
  static const Color darkCard2 = Color(0xFF13102B);

  // ---dark mode ---
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextHint = Color(0xFF9CA3AF);

  static const Color darkTextPrimary = Color(0xFFF1F5F9);  
  static const Color darkTextSecondary = Color(0xFFCBD5E1); 
  static const Color darkTextHint = Color(0xFF64748B);
  
  // ---(Extra Colors) ---
  static const Color pageBg = lightBackground;
  static const Color cardBg = lightSurface;
  static const Color accent = primary;
  static const Color accentLight = primaryLight;
  static const Color green = secondary;
  
  // ---(Status Colors) ---
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  
  // --- (Sidebar Colors) ---
  static const Color sidebarBg = lightSidebar;
  static const Color sidebarText = Color(0xFFC8C6E8);
  static const Color sidebarActive = primary;
  
  // --- (General Colors) ---
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFF9CA3AF);
  static const Color grayDark = Color(0xFF4B5563);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color dark = Color(0xFF1F2937);
  
  // --- (Additional Backgrounds) ---
  static const Color accentBg = Color(0xFFEEF2FF);
  static const Color greenBg = Color(0xFFECFDF5);
  
  // --- (Card Colors) ---
  static const Color card = lightSurface;
  static const Color cardDark = darkSurface;
  
  // ---(Button Colors) ---
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDanger = danger;
  static const Color buttonWarning = warning;
  static const Color buttonInfo = info;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: GoogleFonts.notoSans().fontFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightSurface,
    dividerColor: Colors.grey.shade200,
    
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightTextPrimary,
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.lightTextPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    
    textTheme: GoogleFonts.notoSansTextTheme().copyWith(
      bodyLarge: const TextStyle(color: AppColors.lightTextPrimary),
      bodyMedium: const TextStyle(color: AppColors.lightTextSecondary),
      labelLarge: const TextStyle(color: AppColors.lightTextPrimary),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.lightTextHint),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 50),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    
    iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.notoSans().fontFamily,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkSurface,
    dividerColor: Colors.grey.shade800,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      surface: AppColors.darkSurface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkTextPrimary,
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.darkTextPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.white.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    
    textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: const TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: const TextStyle(color: AppColors.darkTextSecondary),
      bodySmall: const TextStyle(color: AppColors.darkTextHint),
      labelLarge: const TextStyle(color: AppColors.darkTextPrimary),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.darkTextHint),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 50),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    
    iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
  );
}