import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/adhkar.dart';
import '../models/prayer.dart';
import '../theme/app_theme.dart';
import 'adhkar_flow_screen.dart';
import 'dhikr_screen.dart';
import 'reason_screen.dart';

class PrePrayerScreen extends StatelessWidget {
  final Prayer prayer;
  const PrePrayerScreen({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    final reminder = preReminders[prayer]!;

    return Scaffold(
      appBar: AppBar(title: Text('صلاة ${prayer.arabicName}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Center(
              child: Column(
                children: [
                  Text('تبقّى ١٠ دقائق', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text('صلاة ${prayer.arabicName}', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ReminderCard(label: 'آية', body: reminder.ayah, isQuote: true),
            const SizedBox(height: 10),
            _ReminderCard(label: 'حديث', body: reminder.hadith),
            const SizedBox(height: 10),
            _ReminderCard(label: 'فائدة', body: reminder.benefit),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdhkarFlowScreen(
                      title: 'أذكار ما بين الأذان والإقامة',
                      items: beforePrayerAdhkar,
                      audioCategory: 'before',
                    ),
                  ),
                ),
                leading: const Icon(Icons.menu_book_rounded, color: AppColors.gold),
                title: const Text('أذكار ما بين الأذان والإقامة'),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DhikrScreen(prayer: prayer)),
              ),
              child: const Text('صليت'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReasonScreen(prayer: prayer)),
              ),
              child: const Text('لم أُصلِّ بعد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final String label;
  final String body;
  final bool isQuote;
  const _ReminderCard({required this.label, required this.body, this.isQuote = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(
              body,
              style: isQuote
                  ? GoogleFonts.amiri(fontSize: 16, height: 2, color: AppColors.ink)
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
