import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer.dart';
import '../services/notification_inbox_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'missed_prayer_response_screen.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  List<AqimInboxItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Prayer? _prayerFromMissedId(String id) {
    const prefix = 'missed-prayer-';
    if (!id.startsWith(prefix)) return null;
    final parts = id.substring(prefix.length).split('-');
    if (parts.length < 4) return null;
    final name = parts.sublist(3).join('-');
    for (final prayer in Prayer.values) {
      if (prayer.name == name) return prayer;
    }
    return null;
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final items = await NotificationInboxService.instance.getItems();

    // A missed-prayer inbox item is valid only while that prayer is still
    // missed. This removes stale entries if the prayer was completed from
    // Home or from the system notification.
    for (final item in items) {
      final prayer = _prayerFromMissedId(item.id);
      if (prayer != null && !state.missedTodayPrayers.contains(prayer)) {
        await NotificationInboxService.instance.remove(item.id);
      }
    }

    final freshItems = await NotificationInboxService.instance.getItems();
    if (!mounted) return;
    setState(() {
      _items = freshItems;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationInboxService.instance.markAllRead();
    await _load();
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} • ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openItem(AqimInboxItem item) async {
    final prayer = _prayerFromMissedId(item.id);
    if (!item.read) await NotificationInboxService.instance.markRead(item.id);

    if (prayer != null) {
      final state = context.read<AppState>();
      if (!state.missedTodayPrayers.contains(prayer)) {
        await NotificationInboxService.instance.remove(item.id);
        await _load();
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MissedPrayerResponseScreen(prayer: prayer, qadaMode: true),
        ),
      );
      await _load();
      return;
    }

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((item) => !item.read).length;
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.ivory,
        title: Text('الإشعارات', style: GoogleFonts.amiri(fontWeight: FontWeight.w800)),
        actions: [
          if (unread > 0)
            TextButton(onPressed: _markAllRead, child: Text('تحديد الكل كمقروء', style: GoogleFonts.cairo(color: AppColors.goldSoft, fontSize: 11))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _items.isEmpty
              ? Center(child: Text('لا توجد رسائل بعد', style: GoogleFonts.cairo(color: AppColors.inkSoft)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.gold,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = _items[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openItem(item),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: item.read ? AppColors.surfaceDark : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: item.read ? AppColors.paperLine : AppColors.gold.withOpacity(.65)),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.10)), child: Icon(item.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, color: AppColors.gold, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(item.title, style: GoogleFonts.cairo(color: AppColors.ivory, fontWeight: item.read ? FontWeight.w600 : FontWeight.w900))), if (!item.read) Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold))]),
                              const SizedBox(height: 5),
                              Text(item.body, style: GoogleFonts.cairo(color: AppColors.inkSoft, height: 1.5, fontSize: 12)),
                              const SizedBox(height: 7),
                              Text(_date(item.createdAt), style: GoogleFonts.tajawal(color: AppColors.textMuted, fontSize: 10)),
                            ])),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
