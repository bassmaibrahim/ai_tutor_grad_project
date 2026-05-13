// lib/widgets/ai/waveform_visualizer.dart
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class WaveformVisualizer extends StatelessWidget {
  final double progress;      // 0.0 – 1.0
  final bool isPlaying;
  final Animation<double> animation;

  const WaveformVisualizer({
    Key? key,
    required this.progress,
    required this.isPlaying,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _WaveformPainter(
            progress: progress,
            amplitude: isPlaying ? animation.value : 0.0,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final double amplitude;

  _WaveformPainter({required this.progress, required this.amplitude});

  @override
  void paint(Canvas canvas, Size size) {
    final playedPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final unplayedPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barCount = 40;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      double height = 10 + (amplitude * 30) * (i.isEven ? 1 : 0.6);
      final x = i * barWidth + barWidth / 2;
      canvas.drawLine(Offset(x, size.height), Offset(x, size.height - height),
          (i / barCount) <= progress ? playedPaint : unplayedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      progress != oldDelegate.progress || amplitude != oldDelegate.amplitude;
}