import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AqimBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AqimBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.paperLine)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'الرئيسية', selected: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'القرآن', selected: currentIndex == 1, onTap: () => onTap(1)),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => onTap(4),
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                          child: const Icon(Icons.timer_outlined, color: AppColors.ink, size: 26),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('استعد للصلاة', style: GoogleFonts.cairo(fontSize: 9.5, color: AppColors.gold, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                    ],
                  ),
                ),
              ),
              _NavItem(icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'أذكار', selected: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.more_horiz_rounded, selectedIcon: Icons.more_horiz_rounded, label: 'المزيد', selected: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.cairo(fontSize: 10, color: color, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
          ],
        ),
      ),
    );
  }
}
