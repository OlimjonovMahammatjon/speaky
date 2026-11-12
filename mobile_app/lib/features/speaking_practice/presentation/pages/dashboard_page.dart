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

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<SpeakingBloc>().add(const LoadSpeakingDataEvent());
                await _loadUserStats();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Greeting Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('WELCOME BACK', style: AppTextStyles.overline),
                              const SizedBox(height: 4),
                              Text('Ready to speak, $_userName?', style: AppTextStyles.h1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surfaceBorder, width: 1),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Clean Minimalist Stat Cards (no icon box clutter)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            value: '$_streakCount day${_streakCount == 1 ? '' : 's'}',
                            label: 'Current streak',
                            accentColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            value: '$_completedTestsCount',
                            label: 'Tests completed',
                            accentColor: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Today's Session Card (Monochrome Speaky Indigo)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCard,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                        color: Colors.white.withValues(alpha: 0.75),
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
                                      cueCard != null
                                          ? 'Part 2 • ${cueCard.topicArea}'
                                          : 'Part 2 • Guided Cue Card Practice',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 54,
                                height: 54,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: cueCardsCount > 0 ? (cueCardsCount / 8).clamp(0.0, 1.0) : 0.0,
                                      strokeWidth: 4.5,
                                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                    Text(
                                      cueCardsCount > 0
                                          ? '${((cueCardsCount / 8) * 100).clamp(0, 100).round()}%'
                                          : '0%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Coach Tip Inner Box (Clean monochrome indigo)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COACH TIP',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Focus on natural pauses and clear ideas, not perfect grammar.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Crisp White CTA Button
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
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
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
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Voice Recorder / Dictaphone Card (Calm Clean White + Indigo Accent, not screaming red)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DictaphonePage()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.surfaceBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voice Recorder',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Record, replay, and review your speech',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                              size: 22,
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
                              'Focused IELTS Speaking modules',
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

                    const SizedBox(height: 14),

                    // Part 1 Card
                    _buildPracticePartCard(
                      partLabel: 'PART 1',
                      title: 'Quick conversations',
                      subtitle: 'Familiar topics • 4–5 min',
                      topicsCount: '$topicsCount topics',
                      onTap: () => widget.onNavigateToTab(1),
                    ),

                    const SizedBox(height: 10),

                    // Part 2 Card
                    _buildPracticePartCard(
                      partLabel: 'PART 2',
                      title: 'Speak for two minutes',
                      subtitle: 'Cue cards • 3–4 min',
                      topicsCount: '$cueCardsCount cards',
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

                    const SizedBox(height: 10),

                    // Mock Card
                    _buildPracticePartCard(
                      partLabel: 'MOCK',
                      title: 'Full Speaking Simulation',
                      subtitle: 'Parts 1–3 • 11–14 min',
                      topicsCount: 'Start exam',
                      isHighlighted: true,
                      onTap: () => widget.onNavigateToTab(4),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
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

  // Clean Typographic Stat Card (no decorative icon box clutter)
  Widget _buildStatCard({
    required String value,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Practice by Part Card (Clean Typographic Badge, no multi-color icon clutter)
  Widget _buildPracticePartCard({
    required String partLabel,
    required String title,
    required String subtitle,
    required String topicsCount,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted ? AppColors.primary.withValues(alpha: 0.35) : AppColors.surfaceBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isHighlighted ? AppColors.primary : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                partLabel,
                style: TextStyle(
                  color: isHighlighted ? Colors.white : AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            const SizedBox(width: 8),
            Text(
              topicsCount,
              style: TextStyle(
                color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
