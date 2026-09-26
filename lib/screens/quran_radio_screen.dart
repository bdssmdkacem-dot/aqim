import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class QuranRadioScreen extends StatefulWidget {
  const QuranRadioScreen({super.key});

  @override
  State<QuranRadioScreen> createState() => _QuranRadioScreenState();
}

class _QuranRadioScreenState extends State<QuranRadioScreen> {
  static const _streamUrl =
      'https://cdnamd-hls-globecast.akamaized.net/live/ramdisk/'
      'radio_mohammed_6/hls_snrt_radio/index.m3u8';
  static const _officialUrl =
      'https://snrtlive.ma/fr/idaat-mohammed-assadiss';

  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_loading) return;

    if (_playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _player.play(UrlSource(_streamUrl));
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر الاتصال بالبث الآن. يمكنك فتح البث الرسمي مباشرة.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openOfficialStream() async {
    final uri = Uri.parse(_officialUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح صفحة البث الرسمي')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = _playerState == PlayerState.playing;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: const Text('إذاعة القرآن'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.inkDeep,
                      border: Border.all(
                        color: AppColors.gold.withOpacity(.65),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.radio_rounded,
                      color: AppColors.gold,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'إذاعة محمد السادس للقرآن الكريم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ivory,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'بث مباشر من الإذاعة المغربية للقرآن الكريم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.gold,
                            ),
                          )
                        : Row(
                            key: ValueKey(playing),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                playing
                                    ? Icons.graphic_eq_rounded
                                    : Icons.radio_rounded,
                                color: playing
                                    ? AppColors.success
                                    : AppColors.gold,
                                size: 18,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                playing ? 'يُبث الآن' : 'جاهز للبث',
                                style: TextStyle(
                                  color: playing
                                      ? AppColors.success
                                      : AppColors.goldSoft,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: FilledButton(
                      onPressed: _loading ? null : _togglePlayback,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.ink,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 42,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.ember,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InfoTile(
              icon: Icons.verified_rounded,
              title: 'المصدر الرسمي',
              subtitle: 'صفحة إذاعة محمد السادس على SNRT',
              onTap: _openOfficialStream,
            ),
            const SizedBox(height: 10),
            const _InfoTile(
              icon: Icons.menu_book_rounded,
              title: 'استمع للقرآن',
              subtitle: 'بث إذاعي مباشر مع برامج قرآنية ودينية',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paperLine),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 21),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ivory,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.textMuted,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
