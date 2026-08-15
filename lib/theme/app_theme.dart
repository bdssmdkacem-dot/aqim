import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aqim luxury palette — deep emerald, antique gold and warm ivory.
/// The goal is a calm, premium Islamic aesthetic rather than a bright green UI.
class AppColors {
  static const ink = Color(0xFF061B16);
  static const inkDeep = Color(0xFF041510);
  static const inkSoft = Color(0xFF8FA99E);
  static const surfaceDark = Color(0xFF0B2B22);
  static const surface = Color(0xFF10372C);
  static const surfaceElevated = Color(0xFF153F32);
  static const paper = Color(0xFFF4EBD0);
  static const paperLine = Color(0xFF244A3D);
  static const ivory = Color(0xFFF7F1DE);
  static const gold = Color(0xFFC9A227);
  static const goldSoft = Color(0xFFE5C766);
  static const goldPale = Color(0xFFF0D98A);
  static const ember = Color(0xFF9B5A43);
  static const sage = Color(0xFF4D9670);
  static const success = Color(0xFF3FA66B);
  static const textMuted = Color(0xFF849C92);
}

class AppTheme {
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: GoogleFonts.amiri(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ivory),
      headlineMedium: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ivory),
      headlineSmall: GoogleFonts.amiri(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ivory),
      titleLarge: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ivory),
      titleMedium: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ivory),
      bodyLarge: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.ivory, height: 1.7),
      bodyMedium: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.8),
      labelLarge: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
      labelSmall: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.35),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      primaryColor: AppColors.gold,
      canvasColor: AppColors.ink,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.gold,
        onPrimary: AppColors.inkDeep,
        secondary: AppColors.goldSoft,
        onSecondary: AppColors.inkDeep,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.ivory,
      ),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ivory,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.paperLine, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.inkDeep,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      // Keep compact icon+label buttons from wrapping Arabic labels. This is
      // especially important for the Quran page navigation on narrow phones.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ivory,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: AppColors.paperLine, width: 0.9),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 12.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      dividerColor: AppColors.paperLine,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: GoogleFonts.cairo(color: AppColors.textMuted),
        labelStyle: GoogleFonts.cairo(color: AppColors.inkSoft),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.paperLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.gold : AppColors.ivory,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.gold.withOpacity(0.35) : Colors.white12,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.gold.withOpacity(0.65) : AppColors.paperLine,
        ),
      ),
    );
  }

  static ThemeData light() => dark();
}
