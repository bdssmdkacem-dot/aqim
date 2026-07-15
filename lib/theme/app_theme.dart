import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// لوحة ألوان "أقم": نيلي الليل، ذهبي الفجر، ورقي دافئ، أخضر النجاح، وردي الجمر.
class AppColors {
  static const ink = Color(0xFF101A2E);
  static const inkSoft = Color(0xFF3A4358);
  static const paper = Color(0xFFF4EFE3);
  static const paperLine = Color(0xFFE4DCC8);
  static const gold = Color(0xFFC9A24B);
  static const ember = Color(0xFFB5654A);
  static const sage = Color(0xFF5B7A63);
  static const textMuted = Color(0xFF8B93A8);
}

class AppTheme {
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: GoogleFonts.amiri(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      headlineSmall: GoogleFonts.amiri(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppColors.inkSoft,
        height: 1.8,
      ),
      labelSmall: GoogleFonts.tajawal(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      primaryColor: AppColors.ink,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.ink,
        secondary: AppColors.gold,
        surface: AppColors.paper,
      ),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        elevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.paperLine),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.gold,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.paperLine),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      fontFamily: GoogleFonts.cairo().fontFamily,
    );
  }
}
