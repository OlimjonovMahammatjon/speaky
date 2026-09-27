import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AudioWaveVisualizer extends StatelessWidget {
  final List<double> waveHeights;
  final bool isRecording;

  const AudioWaveVisualizer({
    super.key,
    required this.waveHeights,
    this.isRecording = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRecording ? AppColors.primary : AppColors.surfaceBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _WavePainter(
            waveHeights: waveHeights,
            color: isRecording ? AppColors.primary : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> waveHeights;
  final Color color;

  _WavePainter({required this.waveHeights, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (waveHeights.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barWidth = 4.0;
    final count = waveHeights.length;
    final totalSpacing = size.width - (count * barWidth);
    final spacing = count > 1 ? (totalSpacing / (count - 1)).clamp(1.0, 20.0) : 0.0;
    final centerY = size.height / 2;

    for (int i = 0; i < count; i++) {
      final factor = waveHeights[i].clamp(0.12, 1.0);
      final barHeight = size.height * factor * 0.85;
      final x = i * (barWidth + spacing);
      final y = centerY - (barHeight / 2);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.waveHeights != waveHeights;
  }
}
