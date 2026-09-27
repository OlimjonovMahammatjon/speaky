import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CountdownTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final String label;
  final bool isSpeaking;

  const CountdownTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.label,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    final activeColor = isSpeaking ? AppColors.orange : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: AppColors.surfaceBorderLight,
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$minutes:$seconds',
                  style: AppTextStyles.timerNumber.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
