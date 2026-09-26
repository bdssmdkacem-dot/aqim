import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/quran_service.dart';
import '../services/quran_audio_service.dart';
import 'mushaf_quran_screen.dart';
import '../theme/app_theme.dart';

class TextQuranScreen extends StatefulWidget {
  final int? initialPage;
  final MushafRiwaya? initialRiwaya;
  const TextQuranScreen({super.key, this.initialPage, this.initialRiwaya});

  @override
  State<TextQuranScreen> createState() => _TextQuranScreenState();
}

class _TextQuranScreenState extends State<TextQuranScreen> {
  static const pages = 604;
  final service = QuranService.instance;
  final cache = <String, QuranPage>{};
  late PageController controller;
  MushafRiwaya riwaya = MushafRiwaya.warsh;
  int page = 1;
  bool controls = true;
  String? error;
  final audioPlayer = AudioPlayer();
  QuranReciter audioReciter = QuranAudioService.reciters.first;
  PlayerState audioState = PlayerState.stopped;
  Duration audioPosition = Duration.zero;
  Duration audioDuration = Duration.zero;
  bool audioLoading = false;

  QuranRiwaya get mode =>
      riwaya == MushafRiwaya.warsh ? QuranRiwaya.warsh : QuranRiwaya.hafs;

  String get label =>
      riwaya == MushafRiwaya.warsh ? 'ورش عن نافع' : 'حفص عن عاصم';

  String get storageKey => 'quran_' + riwaya.name + '_page';

  @override
  void initState() {
    super.initState();
    riwaya = widget.initialRiwaya ?? MushafRiwaya.warsh;
    page = (widget.initialPage ?? 1).clamp(1, pages).toInt();
    controller = PageController(initialPage: page - 1);
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => audioState = state);
    });
    audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => audioPosition = position);
    });
    audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => audioDuration = duration);
    });
    _restore();
    _restoreAudio();
    _load(page);
  }


  QuranReciter _defaultAudioReciter(MushafRiwaya value) {
    final wanted = value == MushafRiwaya.warsh ? 'ورش عن نافع' : 'حفص عن عاصم';
    return QuranAudioService.reciters.firstWhere((r) => r.riwaya == wanted);
  }

  Future<void> _restoreAudio() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('quran_audio_reciter_id');
    final fallback = _defaultAudioReciter(riwaya);
    final wanted = fallback.riwaya;
    final matches = id == null
        ? const <QuranReciter>[]
        : QuranAudioService.reciters
            .where((r) => r.id == id && r.riwaya == wanted)
            .toList();
    if (!mounted) return;
    setState(() => audioReciter = matches.isEmpty ? fallback : matches.first);
  }

  Future<void> _selectAudioReciter(QuranReciter value) async {
    await audioPlayer.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quran_audio_reciter_id', value.id);
    if (!mounted) return;
    setState(() {
      audioReciter = value;
      audioState = PlayerState.stopped;
      audioPosition = Duration.zero;
      audioDuration = Duration.zero;
    });
  }

  int _audioSurahForPage(QuranPage data) =>
      data.verses.isEmpty ? 1 : data.verses.first.surahNumber;

  Future<void> _playCurrentAudio() async {
    final data = _data(page);
    if (data == null || data.verses.isEmpty) return;
    final surahNumber = _audioSurahForPage(data);
    setState(() => audioLoading = true);
    try {
      if (audioState == PlayerState.playing) {
        await audioPlayer.pause();
      } else if (audioState == PlayerState.paused &&
          audioPosition < audioDuration) {
        await audioPlayer.resume();
      } else {
        await audioPlayer.play(UrlSource(audioReciter.audioUrl(surahNumber)));
      }
    } finally {
      if (mounted) setState(() => audioLoading = false);
    }
  }

  Future<void> _showAudioReciters() async {
    final selected = await showModalBottomSheet<QuranReciter>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (sheet) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .72,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('اختر القارئ',
                      style: TextStyle(
                        color: AppColors.ivory,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      )),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: QuranAudioService.reciters.length,
                    itemBuilder: (_, i) {
                      final r = QuranAudioService.reciters[i];
                      final selected = r.id == audioReciter.id;
                      return ListTile(
                        leading: Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? AppColors.gold : AppColors.textMuted,
                        ),
                        title: Text(r.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          r.riwaya + ' • ' + r.style,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                        onTap: () => Navigator.pop(sheet, r),
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
    if (selected != null) await _selectAudioReciter(selected);
  }

  Widget _audioBar(QuranPage data) {
    final surahNumber = _audioSurahForPage(data);
    final rawPosition = audioPosition.inMilliseconds.toDouble();
    final max = audioDuration.inMilliseconds > 0
        ? audioDuration.inMilliseconds.toDouble()
        : 1.0;
    final position = rawPosition.clamp(0.0, max).toDouble();
    return Material(
      color: AppColors.surfaceDark.withOpacity(.98),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'اختيار القارئ',
                  onPressed: _showAudioReciters,
                  icon: const Icon(Icons.record_voice_over_rounded, color: AppColors.gold),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _showAudioReciters,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(audioReciter.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ivory,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            )),
                        Text(
                          data.surahName + ' • ' + audioReciter.riwaya,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: audioState == PlayerState.playing ? 'إيقاف مؤقت' : 'تشغيل',
                  onPressed: audioLoading ? null : _playCurrentAudio,
                  icon: audioLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                      : Icon(
                          audioState == PlayerState.playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: AppColors.gold,
                          size: 32,
                        ),
                ),
              ],
            ),
            Slider(
              value: position,
              max: max,
              onChanged: audioDuration.inMilliseconds <= 0
                  ? null
                  : (value) => audioPlayer.seek(Duration(milliseconds: value.round())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_audioTime(audioPosition),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                Text('السورة ' + _ar(surahNumber).toString(),
                    style: const TextStyle(color: AppColors.goldSoft, fontSize: 9)),
                Text(_audioTime(audioDuration),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _audioTime(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = value.inHours;
    return hours > 0 ? hours.toString() + ':' + minutes + ':' + seconds : minutes + ':' + seconds;
  }

  Future<void> _restore() async {
    if (widget.initialPage != null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getInt(storageKey) ?? 1).clamp(1, pages).toInt();
    if (!mounted || saved == page) return;
    page = saved;
    controller.jumpToPage(saved - 1);
    _load(saved);
  }

  Future<void> _load(int p) async {
    final key = riwaya.name + ':' + p.toString();
    if (cache.containsKey(key)) return;
    try {
      final value = await service.fetchPage(p, riwaya: mode);
      cache[key] = value;
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = 'تعذر تحميل الصفحة: $e');
    }
  }

  QuranPage? _data(int p) => cache[riwaya.name + ':' + p.toString()];

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final next = page == pages ? 1 : page + 1;
    await prefs.setInt(storageKey, page);
    await prefs.setInt('quran_resume_page_' + riwaya.name, page);
    await prefs.setInt('quran_next_page_' + riwaya.name, next);
    await prefs.setInt('quran_resume_page', page);
    await prefs.setInt('quran_next_page', next);
    await prefs.setString('quran_last_riwaya', riwaya.name);
  }

  void _go(int p) {
    final value = ((p - 1) % pages + pages) % pages + 1;
    controller.jumpToPage(value - 1);
    setState(() => page = value);
    _load(value);
    _save();
  }

  String _ar(int n) {
    const western = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return n.toString().split('').map((d) => arabic[western.indexOf(d)]).join();
  }

  Future<void> _switch(MushafRiwaya value) async {
    if (value == riwaya) return;
    await _save();
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getInt('quran_' + value.name + '_page') ?? 1)
        .clamp(1, pages)
        .toInt();
    setState(() {
      riwaya = value;
      page = saved;
      error = null;
      audioReciter = _defaultAudioReciter(value);
    });
    await _selectAudioReciter(audioReciter);
    controller.jumpToPage(saved - 1);
    await _load(saved);
    await _save();
  }

  Future<void> _index() async {
    final surahs = await service.fetchSurahs(riwaya: mode);
    if (!mounted) return;
    final search = TextEditingController();
    var filter = '';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (_, setSheet) {
          final list = surahs.where((s) =>
              filter.trim().isEmpty || s.name.contains(filter.trim())).toList();
          return Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .84,
                child: Column(children: [
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('فهرس السور', style: TextStyle(
                      color: AppColors.ivory, fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: search,
                      onChanged: (v) => setSheet(() => filter = v),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن سورة…',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                        filled: true,
                        fillColor: Colors.black.withOpacity(.22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final s = list[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.gold.withOpacity(.18),
                            child: Text(s.number.toString(), style: const TextStyle(
                              color: AppColors.gold, fontSize: 12))),
                          title: Text(s.name, style: const TextStyle(
                              color: Colors.white, fontSize: 17)),
                          subtitle: Text(s.numberOfAyahs.toString() + ' آيات',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          trailing: Text('ص ' + s.startPage.toString(),
                              style: const TextStyle(color: AppColors.textMuted)),
                          onTap: () {
                            Navigator.pop(sheet);
                            _go(s.startPage);
                          },
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
    search.dispose();
  }

  Future<void> _searchQuran() async {
    final input = TextEditingController();
    List<QuranSearchResult> results = const [];
    var busy = false;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (_, setDialog) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text('البحث في القرآن',
                style: TextStyle(color: AppColors.ivory)),
            content: SizedBox(
              width: 430,
              height: MediaQuery.of(context).size.height * .56,
              child: Column(children: [
                TextField(
                  controller: input,
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) async {
                    setDialog(() => busy = true);
                    results = await service.search(input.text, riwaya: mode);
                    if (context.mounted) setDialog(() => busy = false);
                  },
                  decoration: InputDecoration(
                    hintText: 'كلمة أو عبارة…',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: AppColors.gold),
                      onPressed: () async {
                        setDialog(() => busy = true);
                        results = await service.search(input.text, riwaya: mode);
                        if (context.mounted) setDialog(() => busy = false);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (busy)
                  const Expanded(child: Center(
                      child: CircularProgressIndicator(color: AppColors.gold)))
                else if (results.isEmpty)
                  const Expanded(child: Center(
                      child: Text('اكتب كلمة للبحث.',
                          style: TextStyle(color: AppColors.textMuted))))
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10),
                      itemBuilder: (_, i) {
                        final v = results[i].verse;
                        return ListTile(
                          title: Text(v.text, maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.amiri(
                                  color: Colors.white, fontSize: 18, height: 1.7)),
                          subtitle: Text(
                            '${v.surahName} • الآية ${_ar(v.numberInSurah)} • ص ${v.page}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                          onTap: () {
                            Navigator.pop(dialog);
                            _go(v.page);
                          },
                        );
                      },
                    ),
                  ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('إغلاق')),
            ],
          ),
        ),
      ),
    );
    input.dispose();
  }

  Future<void> _tafsir(QuranVerse verse) async {
    try {
      final tafsir = await service.fetchTafsir(verse);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surfaceDark,
        isScrollControlled: true,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .72,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('تفسير الآية', textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(color: AppColors.ivory,
                            fontSize: 23, fontWeight: FontWeight.w800)),
                    Text(
                      '${verse.surahName} • الآية ${_ar(verse.numberInSurah)} • الصفحة ${_ar(verse.page)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 14),
                    Text(verse.text, textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(color: AppColors.ivory,
                            fontSize: 22, height: 1.9)),
                    const Divider(height: 28, color: Colors.white12),
                    Text(tafsir.source, textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(color: AppColors.goldSoft,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(tafsir.text, textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(color: AppColors.ivory,
                            fontSize: 19, height: 1.9)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل التفسير: $e')));
      }
    }
  }

  Future<void> _sajda(QuranVerse verse) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('سجدة التلاوة',
                  style: GoogleFonts.amiri(color: AppColors.ivory,
                      fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${verse.surahName} • الآية ${_ar(verse.numberInSurah)}',
                  style: const TextStyle(color: AppColors.gold)),
              const SizedBox(height: 10),
              Text('۩  موضع سجدة التلاوة في هذه الصفحة.',
                  style: GoogleFonts.cairo(color: AppColors.textMuted)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _header(QuranPage data) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [AppColors.surfaceElevated, AppColors.surfaceDark],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.gold.withOpacity(.30)),
    ),
    child: Row(children: [
      Expanded(child: Text(data.surahName, textAlign: TextAlign.right,
          style: GoogleFonts.amiri(color: AppColors.ivory,
              fontSize: 18, fontWeight: FontWeight.w800))),
      Text('الجزء ${_ar(data.juz)} • الحزب ${_ar(data.hizb)}',
          style: GoogleFonts.cairo(color: AppColors.gold,
              fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      Text('ص ${_ar(data.page)}',
          style: GoogleFonts.cairo(color: AppColors.inkSoft,
              fontSize: 11, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _body(QuranPage data) => Directionality(
    textDirection: TextDirection.rtl,
    child: ListView.builder(
      key: PageStorageKey<String>('${riwaya.name}:${data.page}'),
      padding: const EdgeInsets.fromLTRB(18, 82, 18, 84),
      itemCount: data.verses.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) {
          return Column(children: [
            _header(data),
            if (data.page == 1 || data.verses.first.numberInSurah == 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('﷽', style: GoogleFonts.amiri(
                    color: AppColors.goldPale, fontSize: 27)),
              ),
          ]);
        }

        final verse = data.verses[index - 1];
        final previous = index > 1 ? data.verses[index - 2] : null;
        final rubChanged =
            previous != null && previous.hizbQuarter != verse.hizbQuarter;

        return Column(children: [
          if (rubChanged)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '۞ بداية ربع الحزب ${_ar(((verse.hizbQuarter - 1) % 4) + 1)}',
                style: GoogleFonts.cairo(color: AppColors.gold,
                    fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          InkWell(
            onTap: () => _tafsir(verse),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: RichText(
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  style: GoogleFonts.amiri(color: AppColors.ivory,
                      fontSize: 23, height: 1.95),
                  children: [
                    TextSpan(text: verse.text),
                    const TextSpan(text: ' '),
                    if (verse.isSajda)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => _sajda(verse),
                          child: const Text('۩', style: TextStyle(
                            color: AppColors.gold, fontSize: 24,
                            fontWeight: FontWeight.w800)),
                        ),
                      ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.gold.withOpacity(.7)),
                        ),
                        alignment: Alignment.center,
                        child: Text(_ar(verse.numberInSurah),
                            style: GoogleFonts.amiri(color: AppColors.gold,
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]);
      },
    ),
  );

  Widget _top() => Material(
    color: AppColors.surfaceDark.withOpacity(.96),
    borderRadius: BorderRadius.circular(18),
    child: Row(children: [
      IconButton(onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
      Expanded(child: Column(children: [
        const Text('القرآن الكريم', style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
        Text(label, style: const TextStyle(
          color: AppColors.goldSoft, fontSize: 11, fontWeight: FontWeight.w700)),
      ])),
      IconButton(onPressed: _searchQuran,
          icon: const Icon(Icons.search_rounded, color: AppColors.gold)),
      IconButton(onPressed: _index,
          icon: const Icon(Icons.list_alt_rounded, color: AppColors.gold)),
      PopupMenuButton<MushafRiwaya>(
        icon: const Icon(Icons.menu_book_rounded, color: AppColors.gold),
        color: AppColors.surfaceDark,
        onSelected: _switch,
        itemBuilder: (_) => const [
          PopupMenuItem(value: MushafRiwaya.warsh,
              child: Text('ورش عن نافع', style: TextStyle(color: Colors.white))),
          PopupMenuItem(value: MushafRiwaya.hafs,
              child: Text('حفص عن عاصم', style: TextStyle(color: Colors.white))),
        ],
      ),
      IconButton(onPressed: _gotoPage,
          icon: const Icon(Icons.find_in_page_rounded, color: AppColors.gold)),
    ]),
  );

  Future<void> _gotoPage() async {
    final input = TextEditingController(text: page.toString());
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('الانتقال إلى صفحة',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.ivory)),
        content: TextField(
          controller: input, autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.ivory, fontSize: 22),
          decoration: const InputDecoration(hintText: '1 - 604',
              hintStyle: TextStyle(color: AppColors.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(input.text.trim());
              if (p != null && p >= 1 && p <= pages) Navigator.pop(context, p);
            },
            child: const Text('فتح'),
          ),
        ],
      ),
    );
    input.dispose();
    if (selected != null && mounted) _go(selected);
  }

  Widget _bottom() => Material(
    color: Colors.black.withOpacity(.72),
    borderRadius: BorderRadius.circular(20),
    child: Row(children: [
      IconButton(onPressed: () => _go(page == 1 ? pages : page - 1),
          icon: const Icon(Icons.chevron_right_rounded,
              color: Colors.white, size: 30)),
      Expanded(child: Text('${_ar(page)} / ${_ar(pages)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800))),
      IconButton(onPressed: () => _go(page == pages ? 1 : page + 1),
          icon: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 30)),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(
      child: Stack(children: [
        PageView.builder(
          controller: controller,
          reverse: true,
          itemCount: pages,
          onPageChanged: (i) {
            page = i + 1;
            setState(() {});
            _load(page);
            _save();
          },
          itemBuilder: (_, i) {
            final data = _data(i + 1);
            if (data == null) {
              _load(i + 1);
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold));
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => controls = !controls),
              child: _body(data),
            );
          },
        ),
        if (error != null)
          Positioned(
            top: 70, left: 18, right: 18,
            child: Material(
              color: Colors.red.withOpacity(.88),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                dense: true,
                title: Text(error!,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _load(page),
                ),
              ),
            ),
          ),
        if (controls) ...[
          Positioned(top: 8, left: 8, right: 8, child: _top()),
          Positioned(bottom: 10, left: 12, right: 12, child: _bottom()),
          if (_data(page) != null)
            Positioned(bottom: 68, left: 12, right: 12, child: _audioBar(_data(page)!)),
        ],
      ]),
    ),
  );

  @override
  void dispose() {
    audioPlayer.dispose();
    controller.dispose();
    super.dispose();
  }
}
