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
        horizontal: isLarge ? 12 : 9,
        vertical: isLarge ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(isLarge ? 10 : 8),
      ),
      child: Text(
        scoreText,
        style: (isLarge ? AppTextStyles.titleMedium : AppTextStyles.bodySmall).copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: isLarge ? 13 : 11,
        ),
      ),
    );
  }
}
