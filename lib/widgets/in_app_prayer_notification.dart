import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer.dart';
import '../theme/app_theme.dart';

/// A compact in-app notification for prayer reminders.
/// It is designed to sit inside Aqim's home screen without behaving like
/// an intrusive dialog or Android system notification.
class InAppPrayerNotification extends StatefulWidget {
  final Prayer prayer;
  final String timeLabel;
  final Duration? remaining;
  final int beforeMinutes;
  final VoidCallback? onDismiss;
  final VoidCallback? onOpenAdhkar;

  const InAppPrayerNotification({
    super.key,
    required this.prayer,
    required this.timeLabel,
    required this.remaining,
    required this.beforeMinutes,
    this.onDismiss,
    this.onOpenAdhkar,
  });

  @override
  State<InAppPrayerNotification> createState() => _InAppPrayerNotificationState();
}

class _InAppPrayerNotificationState extends State<InAppPrayerNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _countdown(Duration value) {
    final h = value.inHours.toString().padLeft(2, '0');
    final m = (value.inMinutes % 60).toString().padLeft(2, '0');
    final s = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.remaining;
    final isSoon = remaining != null && remaining.inMinutes < widget.beforeMinutes;

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withOpacity(0.48)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                ),
                child: Icon(
                  isSoon ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                  color: AppColors.gold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isSoon ? 'اقتربت الصلاة' : 'الصلاة القادمة',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.prayer.arabicName,
                      style: GoogleFonts.amiri(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.timeLabel,
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (remaining != null) ...[
                          const SizedBox(width: 7),
                          Text(
                            '• ${_countdown(remaining)}',
                            style: GoogleFonts.tajawal(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.onOpenAdhkar != null)
                IconButton(
                  tooltip: 'الأذكار',
                  onPressed: widget.onOpenAdhkar,
                  icon: const Icon(Icons.menu_book_outlined, color: AppColors.gold, size: 19),
                ),
              if (widget.onDismiss != null)
                IconButton(
                  tooltip: 'إخفاء',
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}