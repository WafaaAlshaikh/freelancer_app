// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
 
  static const Color lightInfoBg = Color(
    0xFFE6F7FF,
  ); 
  static const Color lightInfoBorder = Color(
    0xFF91D5FF,
  ); 
  static const Color darkInfoBg = Color(0xFF0D3B4F);

  static const Color lightBorder = Color(
    0xFFE5E7EB,
  ); 
  static const Color darkBorder = Color(0xFF2D3A4F);  

  // --- (Core Colors from logo) ---
  static const Color primary = Color(0xFF122543);
  static const Color primaryDark = Color(0xFF0B1727);
  static const Color primaryLight = Color(0xFF1E3D6B);

  static const Color secondary = Color(0xFF3A5A8C);
  static const Color secondaryLight = Color(0xFF5A7AAC);
  static const Color secondaryDark = Color(0xFF1A3A6C);

  static const Color accent = Color(0xFFE2FF65);
  static const Color accentLight = Color(0xFFEAFF85);
  static const Color accentDark = Color(0xFFC8E84A);

  // --- (Backgrounds - Light Mode) ---
  static const Color lightBackground = Color(0xFFF7F5F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFF122543);

  // --- (Backgrounds - Dark Mode) ---
  static const Color darkBackground = Color(0xFF0B1727);
  static const Color darkSurface = Color(0xFF122543);
  static const Color darkCard = Color(0xFF1A2D4A);
  static const Color darkSidebar = Color(0xFF061224);

  // --- (Text Colors - Light Mode) ---
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightTextHint = Color(0xFF718096);
  static const Color lightTextDisabled = Color(0xFFB0C4DE);

  // --- (Text Colors - Dark Mode) ---
  static const Color darkTextPrimary = Color(0xFFF7F5F0);
  static const Color darkTextSecondary = Color(0xFFB8C5D6);
  static const Color darkTextHint = Color(0xFF6B7A8A);
  static const Color darkTextDisabled = Color(0xFF4A5A6A);

  // --- (Status Colors) ---
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFDBEAFE);

  // --- (General Colors) ---
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFF9CA3AF);
  static const Color grayDark = Color(0xFF4B5563);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color dark = Color(0xFF1F2937);

  // --- (Additional Backgrounds) ---
  static const Color accentBg = Color(0xFFF2F9E6);
  static const Color greenBg = Color(0xFFECFDF5);

  // --- (Card Colors) ---
  static const Color card = lightSurface;
  static const Color cardDark = darkCard;

  // --- (Button Colors) ---
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonAccent = accent;
  static const Color buttonDanger = danger;
  static const Color buttonWarning = warning;
  static const Color buttonInfo = info;

  // --- (Sidebar Colors) ---
  static const Color sidebarBg = lightSidebar;
  static const Color sidebarText = Color(0xFFC8C6E8);
  static const Color sidebarActive = accent;

  // --- (Gradients) ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: GoogleFonts.notoSans().fontFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    dividerColor: AppColors.border,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.lightSurface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: AppColors.primaryDark,
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
      shadowColor: AppColors.primary.withOpacity(0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    textTheme: GoogleFonts.notoSansTextTheme().copyWith(
      displayLarge: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: const TextStyle(color: AppColors.lightTextPrimary),
      bodyMedium: const TextStyle(color: AppColors.lightTextSecondary),
      bodySmall: const TextStyle(color: AppColors.lightTextHint),
      labelLarge: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.lightTextHint),
      labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentDark,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accent;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.notoSans().fontFamily,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.primaryDark,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      tertiary: AppColors.accent,
      surface: AppColors.darkSurface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: AppColors.primaryDark,
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
      shadowColor: Colors.black.withOpacity(0.3),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          displayLarge: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineLarge: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(color: AppColors.darkTextPrimary),
          bodyMedium: const TextStyle(color: AppColors.darkTextSecondary),
          bodySmall: const TextStyle(color: AppColors.darkTextHint),
          labelLarge: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.darkTextHint),
      labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accent;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: AppColors.darkTextHint),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}
