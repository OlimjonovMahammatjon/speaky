import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class BandScoreBadge extends StatelessWidget {
  final String scoreText;
  final bool isLarge;

  const BandScoreBadge({
    super.key,
    required this.scoreText,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: AppColors.teal,
            size: isLarge ? 16 : 13,
          ),
          const SizedBox(width: 4),
          Text(
            scoreText,
            style: (isLarge ? AppTextStyles.titleMedium : AppTextStyles.bodySmall).copyWith(
              color: AppColors.teal,
              fontWeight: FontWeight.w800,
              fontSize: isLarge ? 14 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
