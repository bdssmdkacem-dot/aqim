import 'package:flutter/material.dart';
import '../services/adhan_playback_controller.dart';

class AdhanStopButton extends StatelessWidget {
  const AdhanStopButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: AdhanPlaybackController.stop,
      icon: const Icon(Icons.stop_circle_outlined),
      label: const Text('إيقاف الأذان'),
    );
  }
}
