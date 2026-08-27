import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mushaf_quran_screen.dart';

/// Backwards-compatible entry point used by AQIM navigation.
/// Restores the last Mushaf riwaya when opened from a Quran notification.
class QuranScreen extends StatefulWidget {
  final int? initialPage;
  const QuranScreen({super.key, this.initialPage});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  MushafRiwaya _riwaya = MushafRiwaya.hafs;

  @override
  void initState() {
    super.initState();
    _restoreRiwaya();
  }

  Future<void> _restoreRiwaya() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('quran_last_riwaya');
    if (!mounted) return;
    setState(() {
      _riwaya = saved == MushafRiwaya.warsh.name
          ? MushafRiwaya.warsh
          : MushafRiwaya.hafs;
    });
  }

  @override
  Widget build(BuildContext context) => MushafQuranScreen(
        initialPage: widget.initialPage,
        initialRiwaya: _riwaya,
      );
}
