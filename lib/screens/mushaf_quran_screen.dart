import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Offline, page-accurate Mushaf viewer.
/// Hafs and Warsh are separate datasets downloaded at release-build time.
class MushafQuranScreen extends StatefulWidget {
  final int? initialPage;
  const MushafQuranScreen({super.key, this.initialPage});

  @override
  State<MushafQuranScreen> createState() => _MushafQuranScreenState();
}

enum MushafRiwaya { hafs, warsh }

class _MushafQuranScreenState extends State<MushafQuranScreen> {
  static const int pageCount = 604;
  MushafRiwaya _riwaya = MushafRiwaya.hafs;
  late PageController _controller;
  int _page = 1;
  bool _controlsVisible = true;

  String get _key => _riwaya == MushafRiwaya.hafs ? 'quran_hafs_page' : 'quran_warsh_page';
  String get _label => _riwaya == MushafRiwaya.hafs ? 'حفص عن عاصم' : 'ورش عن نافع';
  String get _folder => _riwaya == MushafRiwaya.hafs ? 'hafs' : 'warsh';

  @override
  void initState() {
    super.initState();
    _page = (widget.initialPage ?? 1).clamp(1, pageCount).toInt();
    _controller = PageController(initialPage: _page - 1);
    _restorePage();
  }

  Future<void> _restorePage() async {
    if (widget.initialPage != null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getInt(_key) ?? 1).clamp(1, pageCount).toInt();
    if (!mounted || saved == _page) return;
    _controller.jumpToPage(saved - 1);
    setState(() => _page = saved);
  }

  Future<void> _savePage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _page);
  }

  Future<void> _switchRiwaya(MushafRiwaya value) async {
    if (value == _riwaya) return;
    final prefs = await SharedPreferences.getInstance();
    final key = value == MushafRiwaya.hafs ? 'quran_hafs_page' : 'quran_warsh_page';
    final saved = (prefs.getInt(key) ?? 1).clamp(1, pageCount).toInt();
    final old = _controller;
    setState(() {
      _riwaya = value;
      _page = saved;
      _controller = PageController(initialPage: saved - 1);
    });
    old.dispose();
  }

  Future<void> _gotoPage() async {
    final text = TextEditingController(text: '$_page');
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('الانتقال إلى صفحة', textAlign: TextAlign.right, style: TextStyle(color: AppColors.ivory)),
        content: TextField(
          controller: text,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.ivory, fontSize: 22),
          decoration: const InputDecoration(hintText: '1 - 604', hintStyle: TextStyle(color: AppColors.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(text.text.trim());
              if (p != null && p >= 1 && p <= pageCount) Navigator.pop(context, p);
            },
            child: const Text('فتح'),
          ),
        ],
      ),
    );
    text.dispose();
    if (selected == null || !mounted) return;
    _controller.jumpToPage(selected - 1);
    setState(() => _page = selected);
    await _savePage();
  }

  void _previous() {
    if (_page <= 1) return;
    _controller.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  void _next() {
    if (_page >= pageCount) return;
    _controller.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F0DF),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => setState(() => _controlsVisible = !_controlsVisible),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _controller,
                  reverse: true,
                  itemCount: pageCount,
                  onPageChanged: (index) {
                    setState(() => _page = index + 1);
                    _savePage();
                  },
                  itemBuilder: (_, index) {
                    final page = index + 1;
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      boundaryMargin: const EdgeInsets.all(24),
                      child: Center(
                        child: Image.asset(
                          'assets/quran/$_folder/pages/${page.toString().padLeft(3, '0')}.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Center(child: Text('صفحة المصحف غير متوفرة', style: TextStyle(color: Colors.red))),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_controlsVisible) ...[
              Positioned(top: 8, left: 8, right: 8, child: _topBar()),
              Positioned(bottom: 10, left: 12, right: 12, child: _bottomBar()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Material(
      color: Colors.black.withOpacity(.72),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(children: [
          IconButton(tooltip: 'رجوع', onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
          Expanded(
            child: Column(children: [
              const Text('القرآن الكريم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              Text(_label, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
          PopupMenuButton<MushafRiwaya>(
            tooltip: 'اختيار الرواية',
            icon: const Icon(Icons.menu_book_rounded, color: AppColors.gold),
            color: AppColors.surfaceDark,
            onSelected: _switchRiwaya,
            itemBuilder: (_) => const [
              PopupMenuItem(value: MushafRiwaya.hafs, child: Text('حفص عن عاصم', style: TextStyle(color: Colors.white))),
              PopupMenuItem(value: MushafRiwaya.warsh, child: Text('ورش عن نافع', style: TextStyle(color: Colors.white))),
            ],
          ),
          IconButton(tooltip: 'رقم الصفحة', onPressed: _gotoPage, icon: const Icon(Icons.find_in_page_rounded, color: AppColors.gold)),
        ]),
      ),
    );
  }

  Widget _bottomBar() {
    return Material(
      color: Colors.black.withOpacity(.72),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(onPressed: _previous, icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30)),
          Expanded(child: Text('$_page / $pageCount', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          IconButton(onPressed: _next, icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30)),
          IconButton(onPressed: _savePage, tooltip: 'حفظ الصفحة', icon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.gold)),
        ]),
      ),
    );
  }
}
