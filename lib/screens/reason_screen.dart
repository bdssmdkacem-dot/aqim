import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ReasonScreen extends StatefulWidget {
  final Prayer prayer;
  const ReasonScreen({super.key, required this.prayer});

  @override
  State<ReasonScreen> createState() => _ReasonScreenState();
}

class _ReasonScreenState extends State<ReasonScreen> {
  String? picked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('صلاة ${widget.prayer.arabicName}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          children: [
            Text('لماذا لم تصلِّ بعد؟', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            ...missedReasons.map((r) {
              final isPicked = picked == r;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerRight,
                    foregroundColor: isPicked ? AppColors.ember : AppColors.ink,
                    side: BorderSide(color: isPicked ? AppColors.ember : AppColors.paperLine),
                    backgroundColor: isPicked ? AppColors.ember.withOpacity(0.06) : Colors.white,
                  ),
                  onPressed: () async {
                    setState(() => picked = r);
                    await context.read<AppState>().markMissed(widget.prayer, r);
                  },
                  child: Align(alignment: Alignment.centerRight, child: Text(r)),
                ),
              );
            }),
            if (picked != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اقتراح', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      Text(suggestionForReason(picked!), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                ),
                child: const Text('حسنًا'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
