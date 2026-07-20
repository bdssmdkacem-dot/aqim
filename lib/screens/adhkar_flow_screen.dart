import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/adhkar.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class AdhkarFlowScreen extends StatefulWidget {
  final String title;
  final List<AdhkarItem> items;
  final String audioCategory; // 'before' أو 'after'
  final Widget Function()? nextScreenBuilder;

  const AdhkarFlowScreen({
    super.key,
    required this.title,
    required this.items,
    required this.audioCategory,
    this.nextScreenBuilder,
  });

  @override
  State<AdhkarFlowScreen> createState() => _AdhkarFlowScreenState();
}

class _AdhkarFlowScreenState extends State<AdhkarFlowScreen> {
  int index = 0;
  int count = 0;

  AdhkarItem get current => widget.items[index];
  bool get isLast => index == widget.items.length - 1;

  void _next() {
    if (isLast) {
      if (widget.nextScreenBuilder != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreenBuilder!()),
        );
      } else {
        Navigator.of(context).pop();
      }
      return;
    }
    setState(() {
      index++;
      count = 0;
    });
  }

  void _tap() {
    setState(() {
      count++;
      if (count >= current.repeat) {
        Future.delayed(const Duration(milliseconds: 250), _next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = current;
    final pct = (count / item.repeat).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (index + pct) / widget.items.length,
            backgroundColor: AppColors.paperLine,
            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${index + 1} / ${widget.items.length}', style: Theme.of(context).textTheme.labelSmall),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.inkSoft),
                    tooltip: 'استماع',
                    onPressed: () => AudioService.instance.playAsset(
                      context,
                      item.audioAsset(widget.audioCategory),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: item.repeat > 1 ? _tap : null,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.paperLine),
                            ),
                            child: Text(
                              item.text,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(fontSize: 19, height: 2.1, color: AppColors.ink),
                            ),
                          ),
                        ),
                        if (item.note != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            item.note!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (item.repeat > 1) ...[
                          const SizedBox(height: 20),
                          Text(
                            '$count / ${item.repeat}',
                            style: GoogleFonts.tajawal(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.gold),
                          ),
                          const SizedBox(height: 4),
                          Text('اضغط النص لكل مرة', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'إنهاء' : 'تخطي'),
                    ),
                  ),
                  if (item.repeat <= 1) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(isLast ? 'إنهاء' : 'التالي'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
