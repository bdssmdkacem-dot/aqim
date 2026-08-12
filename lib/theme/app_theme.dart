import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// لوحة ألوان "أقم" الجديدة: أخضر إسلامي عميق وذهبي، مستوحاة من التصميم
/// المرجعي — خلفيات داكنة، تفاصيل ذهبية، ونصوص بيضاء/كريمية.
class AppColors {
  static const ink = Color(0xFF0C2E24); // أخضر داكن جدًا (كان نيلي سابقًا)
  static const inkSoft = Color(0xFF7FA394); // نص ثانوي فاتح على خلفية داكنة
  static const surfaceDark = Color(0xFF0F3D2E); // أخضر البطاقات/الأزرار الداكنة
  static const paper = Color(0xFFF7F4EC); // خلفية فاتحة (للنصوص الطويلة/الشاشات الثانوية)
  static const paperLine = Color(0xFF1B4B3A); // خطوط فاصلة على الخلفية الداكنة
  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE8CE7A);
  static const ember = Color(0xFFB5654A);
  static const sage = Color(0xFF5B9E7A);
  static const textMuted = Color(0xFF8FA79B);
}

class AppTheme {
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: GoogleFonts.amiri(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      headlineSmall: GoogleFonts.amiri(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
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

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      primaryColor: AppColors.gold,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.gold,
        secondary: AppColors.goldSoft,
        surface: AppColors.surfaceDark,
      ),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.paperLine),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.paperLine),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      dividerColor: AppColors.paperLine,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.gold : Colors.white70,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold.withOpacity(0.4)
              : Colors.white24,
        ),
      ),
    );
  }

  /// أُبقيت للتوافق مع الشاشات التي قد تستدعي الثيم الفاتح القديم؛ التطبيق
  /// الآن يستعمل dark() افتراضيًا فـ main.dart.
  static ThemeData light() => dark();
}
