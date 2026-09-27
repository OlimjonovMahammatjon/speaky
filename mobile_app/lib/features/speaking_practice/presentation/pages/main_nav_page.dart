import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'dashboard_page.dart';
import 'part1_topics_page.dart';
import 'cue_cards_list_page.dart';
import 'vocabulary_bank_page.dart';
import 'mock_test_intro_page.dart';

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(onNavigateToTab: _onTabTapped),
      const Part1TopicsPage(),
      const CueCardsListPage(),
      const VocabularyBankPage(),
      const MockTestIntroPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.surfaceBorderLight, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.article_rounded, Icons.article_outlined, 'Part 1'),
                _buildNavItem(2, Icons.mic_none_rounded, Icons.mic_none_outlined, 'Part 2'),
                _buildNavItem(3, Icons.menu_book_rounded, Icons.menu_book_outlined, 'Vocab'),
                _buildNavItem(4, Icons.verified_rounded, Icons.verified_outlined, 'Mock'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: isSelected ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4) : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
