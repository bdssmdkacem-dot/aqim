import 'package:flutter/material.dart';
import 'mushaf_quran_screen.dart';

/// Backwards-compatible entry point used by AQIM navigation.
/// The Quran screen is now the real offline page-based Mushaf viewer.
class QuranScreen extends StatelessWidget {
  final int? initialPage;
  const QuranScreen({super.key, this.initialPage});

  @override
  Widget build(BuildContext context) => MushafQuranScreen(initialPage: initialPage);
}
