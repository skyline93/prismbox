import 'package:flutter/material.dart';

class VideoOverlay extends StatelessWidget {
  final int durationSec;
  const VideoOverlay({super.key, required this.durationSec});

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
                stops: [0.6, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(durationSec),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
