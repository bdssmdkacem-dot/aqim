import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class MushafQuranScreen extends StatefulWidget {
  final int? initialPage;
  final MushafRiwaya? initialRiwaya;
  const MushafQuranScreen({super.key, this.initialPage, this.initialRiwaya});

  @override
  State<MushafQuranScreen> createState() => _MushafQuranScreenState();
}

enum MushafRiwaya { hafs, warsh }

class _Surah {
  final int number;
  final String name;
  final int page;
  const _Surah(this.number, this.name, this.page);
}

class _MushafQuranScreenState extends State<MushafQuranScreen> {
  static const int pageCount = 604;
  MushafRiwaya _riwaya = MushafRiwaya.hafs;
  late PageController _controller;
  int _page = 1;
  bool _controlsVisible = true;

  String get _riwayaName => _riwaya.name;
  String get _key => _riwaya == MushafRiwaya.hafs ? 'quran_hafs_page' : 'quran_warsh_page';
  String get _resumeKey => 'quran_resume_page_$_riwayaName';
  String get _nextKey => 'quran_next_page_$_riwayaName';
  String get _label => _riwaya == MushafRiwaya.hafs ? 'حفص عن عاصم' : 'ورش عن نافع';
  String get _folder => _riwaya == MushafRiwaya.hafs ? 'hafs' : 'warsh';

  static const List<_Surah> _surahs = [
    _Surah(1, 'الفاتحة', 1), _Surah(2, 'البقرة', 2), _Surah(3, 'آل عمران', 50),
    _Surah(4, 'النساء', 77), _Surah(5, 'المائدة', 106), _Surah(6, 'الأنعام', 128),
    _Surah(7, 'الأعراف', 151), _Surah(8, 'الأنفال', 177), _Surah(9, 'التوبة', 187),
    _Surah(10, 'يونس', 208), _Surah(11, 'هود', 221), _Surah(12, 'يوسف', 235),
    _Surah(13, 'الرعد', 249), _Surah(14, 'إبراهيم', 255), _Surah(15, 'الحجر', 262),
    _Surah(16, 'النحل', 267), _Surah(17, 'الإسراء', 282), _Surah(18, 'الكهف', 293),
    _Surah(19, 'مريم', 305), _Surah(20, 'طه', 312), _Surah(21, 'الأنبياء', 322),
    _Surah(22, 'الحج', 332), _Surah(23, 'المؤمنون', 342), _Surah(24, 'النور', 350),
    _Surah(25, 'الفرقان', 359), _Surah(26, 'الشعراء', 367), _Surah(27, 'النمل', 377),
    _Surah(28, 'القصص', 385), _Surah(29, 'العنكبوت', 396), _Surah(30, 'الروم', 404),
    _Surah(31, 'لقمان', 411), _Surah(32, 'السجدة', 415), _Surah(33, 'الأحزاب', 418),
    _Surah(34, 'سبأ', 428), _Surah(35, 'فاطر', 434), _Surah(36, 'يس', 440),
    _Surah(37, 'الصافات', 446), _Surah(38, 'ص', 453), _Surah(39, 'الزمر', 458),
    _Surah(40, 'غافر', 467), _Surah(41, 'فصلت', 477), _Surah(42, 'الشورى', 483),
    _Surah(43, 'الزخرف', 489), _Surah(44, 'الدخان', 496), _Surah(45, 'الجاثية', 499),
    _Surah(46, 'الأحقاف', 502), _Surah(47, 'محمد', 507), _Surah(48, 'الفتح', 511),
    _Surah(49, 'الحجرات', 515), _Surah(50, 'ق', 518), _Surah(51, 'الذاريات', 520),
    _Surah(52, 'الطور', 523), _Surah(53, 'النجم', 526), _Surah(54, 'القمر', 528),
    _Surah(55, 'الرحمن', 531), _Surah(56, 'الواقعة', 534), _Surah(57, 'الحديد', 537),
    _Surah(58, 'المجادلة', 542), _Surah(59, 'الحشر', 545), _Surah(60, 'الممتحنة', 549),
    _Surah(61, 'الصف', 551), _Surah(62, 'الجمعة', 553), _Surah(63, 'المنافقون', 554),
    _Surah(64, 'التغابن', 556), _Surah(65, 'الطلاق', 558), _Surah(66, 'التحريم', 560),
    _Surah(67, 'الملك', 562), _Surah(68, 'القلم', 564), _Surah(69, 'الحاقة', 566),
    _Surah(70, 'المعارج', 568), _Surah(71, 'نوح', 570), _Surah(72, 'الجن', 572),
    _Surah(73, 'المزمل', 574), _Surah(74, 'المدثر', 575), _Surah(75, 'القيامة', 577),
    _Surah(76, 'الإنسان', 578), _Surah(77, 'المرسلات', 580), _Surah(78, 'النبأ', 582),
    _Surah(79, 'النازعات', 583), _Surah(80, 'عبس', 585), _Surah(81, 'التكوير', 586),
    _Surah(82, 'الانفطار', 587), _Surah(83, 'المطففين', 587), _Surah(84, 'الانشقاق', 589),
    _Surah(85, 'البروج', 590), _Surah(86, 'الطارق', 591), _Surah(87, 'الأعلى', 591),
    _Surah(88, 'الغاشية', 592), _Surah(89, 'الفجر', 593), _Surah(90, 'البلد', 594),
    _Surah(91, 'الشمس', 595), _Surah(92, 'الليل', 595), _Surah(93, 'الضحى', 596),
    _Surah(94, 'الشرح', 596), _Surah(95, 'التين', 597), _Surah(96, 'العلق', 597),
    _Surah(97, 'القدر', 598), _Surah(98, 'البينة', 598), _Surah(99, 'الزلزلة', 599),
    _Surah(100, 'العاديات', 599), _Surah(101, 'القارعة', 600), _Surah(102, 'التكاثر', 600),
    _Surah(103, 'العصر', 601), _Surah(104, 'الهمزة', 601), _Surah(105, 'الفيل', 601),
    _Surah(106, 'قريش', 602), _Surah(107, 'الماعون', 602), _Surah(108, 'الكوثر', 602),
    _Surah(109, 'الكافرون', 603), _Surah(110, 'النصر', 603), _Surah(111, 'المسد', 603),
    _Surah(112, 'الإخلاص', 604), _Surah(113, 'الفلق', 604), _Surah(114, 'الناس', 604),
  ];

  @override
  void initState() {
    super.initState();
    _riwaya = widget.initialRiwaya ?? MushafRiwaya.hafs;
    _page = (widget.initialPage ?? 1).clamp(1, pageCount).toInt();
    _controller = PageController(initialPage: _page - 1);
    _restorePage();
  }

  Future<void> _restorePage() async {
    if (widget.initialPage != null) return;
    final prefs = await SharedPreferences.getInstance();
    final legacyMatches = prefs.getString('quran_last_riwaya') == _riwayaName;
    final saved = (prefs.getInt(_key) ?? prefs.getInt(_resumeKey) ??
            (legacyMatches ? prefs.getInt('quran_resume_page') : null) ?? 1)
        .clamp(1, pageCount).toInt();
    if (!mounted || saved == _page) return;
    _controller.jumpToPage(saved - 1);
    setState(() => _page = saved);
  }

  Future<void> _savePage() async {
    final prefs = await SharedPreferences.getInstance();
    final nextPage = _page == pageCount ? 1 : _page + 1;
    await prefs.setInt(_key, _page);
    await prefs.setInt(_resumeKey, _page);
    await prefs.setInt(_nextKey, nextPage);
    await prefs.setInt('quran_resume_page', _page);
    await prefs.setInt('quran_next_page', nextPage);
    await prefs.setString('quran_last_riwaya', _riwayaName);
  }

  void _setPage(int page) {
    final normalized = ((page - 1) % pageCount + pageCount) % pageCount + 1;
    _controller.jumpToPage(normalized - 1);
    setState(() => _page = normalized);
    _savePage();
  }

  void _openSurahIndex() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .82,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('فهرس السور', style: TextStyle(color: AppColors.ivory, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _surahs.length,
                    itemBuilder: (_, i) {
                      final s = _surahs[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.gold.withOpacity(.18),
                          child: Text('${s.number}', style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                        ),
                        title: Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 17)),
                        trailing: Text('ص ${s.page}', style: const TextStyle(color: AppColors.textMuted)),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _setPage(s.page);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _switchRiwaya(MushafRiwaya value) async {
    if (value == _riwaya) return;
    await _savePage();
    final prefs = await SharedPreferences.getInstance();
    final key = value == MushafRiwaya.hafs ? 'quran_hafs_page' : 'quran_warsh_page';
    final saved = (prefs.getInt(key) ?? prefs.getInt('quran_resume_page_${value.name}') ?? 1)
        .clamp(1, pageCount).toInt();
    final old = _controller;
    setState(() {
      _riwaya = value;
      _page = saved;
      _controller = PageController(initialPage: saved - 1);
    });
    old.dispose();
    await _savePage();
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
    if (selected != null && mounted) _setPage(selected);
  }

  void _previous() => _setPage(_page == 1 ? pageCount : _page - 1);
  void _next() => _setPage(_page == pageCount ? 1 : _page + 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _pageView() {
    return Directionality(
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
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _controlsVisible = !_controlsVisible),
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(80),
              panEnabled: true,
              scaleEnabled: true,
              clipBehavior: Clip.none,
              interactionEndFrictionCoefficient: 0.00001,
              child: Center(
                child: Image.asset(
                  'assets/quran/$_folder/pages/${page.toString().padLeft(3, '0')}.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('صفحة المصحف غير متوفرة', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F0DF),
      body: SafeArea(
        child: Stack(
          children: [
            _pageView(),
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
        child: Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text('القرآن الكريم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(_label, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            IconButton(tooltip: 'فهرس السور', onPressed: _openSurahIndex, icon: const Icon(Icons.list_alt_rounded, color: AppColors.gold)),
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
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Material(
      color: Colors.black.withOpacity(.72),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(onPressed: _previous, icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30)),
            Expanded(child: Text('$_page / $pageCount', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            IconButton(onPressed: _next, icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30)),
          ],
        ),
      ),
    );
  }
}
