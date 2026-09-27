import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../bloc/speaking_bloc.dart';
import 'cue_card_session_page.dart';
import 'dictaphone_page.dart';
import 'notification_settings_page.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const DashboardPage({super.key, required this.onNavigateToTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = 'there';
  int _streakCount = 0;
  int _completedTestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final prefs = sl<SharedPreferences>();
    final name = prefs.getString('ielts_speaky_user_name') ?? 'there';
    final streak = prefs.getInt(AppConstants.prefStreakCount) ?? 0;
    int completed = 0;
    final json = prefs.getString(AppConstants.prefCompletedTests);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List<dynamic>;
        completed = list.length;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _userName = name;
        _streakCount = streak;
        _completedTestsCount = completed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<SpeakingBloc, SpeakingState>(
          builder: (context, state) {
            if (state is SpeakingError) {
              return _buildErrorView(context, state.message);
            }

            final cueCard = (state is SpeakingLoaded && state.cueCards.isNotEmpty)
                ? state.cueCards.first
                : null;
            final topicsCount = state is SpeakingLoaded ? state.allTopics.length : 0;
            final cueCardsCount = state is SpeakingLoaded ? state.cueCards.length : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Greeting Row (Instant 120fps render)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WELCOME BACK', style: AppTextStyles.overline),
                          const SizedBox(height: 4),
                          Text('Ready to speak, $_userName?', style: AppTextStyles.h1),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationSettingsPage(),
                            ),
                          );
                          _loadUserStats();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Two Stat Cards (streak & completed tests - instantaneous render)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.orange,
                          iconBgColor: AppColors.orangeSoft,
                          value: '$_streakCount day${_streakCount == 1 ? '' : 's'}',
                          label: 'Current streak',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.assignment_turned_in_rounded,
                          iconColor: AppColors.teal,
                          iconBgColor: AppColors.tealSoft,
                          value: '$_completedTestsCount',
                          label: 'Tests done',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Today's Session Card (Solid Royal Blue - NO GRADIENT)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCard,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with session title and circular percentage
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TODAY'S SESSION",
                                    style: AppTextStyles.label.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Let's build your fluency",
                                    style: AppTextStyles.h2.copyWith(
                                      color: Colors.white,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Part 2 • People and relationships',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Circular progress indicator
                            SizedBox(
                              width: 58,
                              height: 58,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: cueCardsCount > 0 ? (cueCardsCount / 8).clamp(0.0, 1.0) : 0.0,
                                    strokeWidth: 5,
                                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.progressArc,
                                    ),
                                  ),
                                  Text(
                                    cueCardsCount > 0
                                        ? '${((cueCardsCount / 8) * 100).clamp(0, 100).round()}%'
                                        : '0%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Coach Tip Inner Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCardInner,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.mintTipBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF065F46),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Coach tip',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Focus on natural pauses, not perfect sentences.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // White Continue Practice Button
                        GestureDetector(
                          onTap: () {
                            if (cueCard != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CueCardSessionPage(cueCard: cueCard),
                                ),
                              );
                            } else {
                              widget.onNavigateToTab(1);
                            }
                          },
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue practice',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  cueCard != null ? 'Cue card' : 'Browse',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Dictaphone Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DictaphonePage()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.band5,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.band5.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DICTAPHONE',
                                  style: AppTextStyles.label.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Record & analyze your voice',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Record, listen back, and download your audio',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Practice by Part Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Practice by part', style: AppTextStyles.h2),
                          const SizedBox(height: 2),
                          Text(
                            'Choose what you want to improve',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigateToTab(1),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Part 1 Card
                  _buildPracticePartCard(
                    partLabel: 'PART 1',
                    partLabelColor: AppColors.textSecondary,
                    title: 'Quick conversations',
                    subtitle: 'Familiar topics • 4–5 min',
                    topicsCount: '$topicsCount topics',
                    icon: Icons.mic_none_rounded,
                    iconColor: AppColors.tealIcon,
                    iconBgColor: AppColors.tealIconBg,
                    onTap: () => widget.onNavigateToTab(1),
                  ),

                  const SizedBox(height: 12),

                  // Part 2 Card
                  _buildPracticePartCard(
                    partLabel: 'PART 2',
                    partLabelColor: AppColors.purple,
                    title: 'Speak for two minutes',
                    subtitle: 'Cue cards • 3–4 min',
                    topicsCount: '$cueCardsCount topics',
                    icon: Icons.article_outlined,
                    iconColor: AppColors.purple,
                    iconBgColor: AppColors.purpleSoft,
                    onTap: () {
                      if (cueCard != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CueCardSessionPage(cueCard: cueCard),
                          ),
                        );
                      } else {
                        widget.onNavigateToTab(2);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Part 3 Card
                  _buildPracticePartCard(
                    partLabel: 'MOCK',
                    partLabelColor: AppColors.orange,
                    title: 'Full Speaking Simulation',
                    subtitle: 'Complete exam • 11–14 min',
                    topicsCount: 'Start here',
                    icon: Icons.verified_outlined,
                    iconColor: AppColors.orange,
                    iconBgColor: AppColors.orangeSoft,
                    onTap: () => widget.onNavigateToTab(4),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Error view with retry button
  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              onPressed: () {
                context.read<SpeakingBloc>().add(const LoadSpeakingDataEvent());
              },
            ),
          ],
        ),
      ),
    );
  }

  // Stat Card (Solid White with subtle border)
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Practice by Part Card (Solid White with soft icon container)
  Widget _buildPracticePartCard({
    required String partLabel,
    required Color partLabelColor,
    required String title,
    required String subtitle,
    required String topicsCount,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partLabel,
                    style: TextStyle(
                      color: partLabelColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  topicsCount,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
