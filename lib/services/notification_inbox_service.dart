import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AqimInboxItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  const AqimInboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  AqimInboxItem copyWith({bool? read}) => AqimInboxItem(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory AqimInboxItem.fromJson(Map<String, dynamic> json) => AqimInboxItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
      );
}

class NotificationInboxService {
  NotificationInboxService._();
  static final NotificationInboxService instance = NotificationInboxService._();
  static const _key = 'aqim_inbox_v1';
  static const _maxItems = 100;

  Future<List<AqimInboxItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final items = <AqimInboxItem>[];
    for (final value in raw) {
      try {
        items.add(AqimInboxItem.fromJson(jsonDecode(value) as Map<String, dynamic>));
      } catch (_) {}
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> add({required String id, required String title, required String body, DateTime? createdAt}) async {
    final items = await getItems();
    if (items.any((item) => item.id == id)) return;
    items.insert(0, AqimInboxItem(id: id, title: title, body: body, createdAt: createdAt ?? DateTime.now(), read: false));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items.take(_maxItems).map((item) => jsonEncode(item.toJson())).toList());
  }

  Future<void> markRead(String id) async {
    await _replace((item) => item.id == id ? item.copyWith(read: true) : item);
  }

  Future<void> markAllRead() async => _replace((item) => item.copyWith(read: true));

  Future<void> remove(String id) async {
    final items = await getItems();
    final remaining = items.where((item) => item.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, remaining.map((item) => jsonEncode(item.toJson())).toList());
  }

  Future<void> removeMissedPrayer(String dateKey, String prayerName) =>
      remove('missed-prayer-$dateKey-$prayerName');

  Future<int> unreadCount() async => (await getItems()).where((item) => !item.read).length;

  Future<void> _replace(AqimInboxItem Function(AqimInboxItem) transform) async {
    final items = (await getItems()).map(transform).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items.map((item) => jsonEncode(item.toJson())).toList());
  }
}
