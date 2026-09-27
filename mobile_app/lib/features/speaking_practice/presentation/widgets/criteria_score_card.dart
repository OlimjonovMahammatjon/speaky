import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CriteriaScoreCard extends StatelessWidget {
  final String title;
  final String code;
  final double score;
  final String description;

  const CriteriaScoreCard({
    super.key,
    required this.title,
    required this.code,
    required this.score,
    required this.description,
  });

  Color _getScoreColor(double score) {
    if (score >= 8.0) return AppColors.teal;
    if (score >= 7.0) return AppColors.primary;
    if (score >= 6.0) return AppColors.orange;
    return AppColors.band5;
  }

  Color _getScoreBgColor(double score) {
    if (score >= 8.0) return AppColors.tealSoft;
    if (score >= 7.0) return AppColors.primarySoft;
    if (score >= 6.0) return AppColors.orangeSoft;
    return const Color(0xFFFEF2F2);
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(score);
    final scoreBgColor = _getScoreBgColor(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      code,
                      style: AppTextStyles.label.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 9.0,
              minHeight: 6,
              backgroundColor: AppColors.backgroundSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
