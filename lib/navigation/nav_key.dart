import 'package:flutter/material.dart';

/// مفتاح تنقّل عام يُستعمل داخل MaterialApp، ويسمح لخدمة الإشعارات
/// بفتح شاشة معيّنة عند الضغط على إشعار حتى لو كان التطبيق فـ الخلفية.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
