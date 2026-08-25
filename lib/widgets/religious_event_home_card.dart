import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/religious_events_service.dart';
import '../theme/app_theme.dart';

class ReligiousEventHomeCard extends StatelessWidget {
  final ReligiousEvent event;
  const ReligiousEventHomeCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(.55)),
      ),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.10), border: Border.all(color: AppColors.gold.withOpacity(.45))), child: const Icon(Icons.event_available_rounded, color: AppColors.gold, size: 25)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('اليوم مناسبة دينية', style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.goldSoft, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(event.title, style: GoogleFonts.amiri(fontSize: 18, color: AppColors.ivory, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('${event.hijri}${event.provisional ? ' • موعد متوقع' : ''}', style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.inkSoft)),
        ])),
      ]),
    );
  }
}
