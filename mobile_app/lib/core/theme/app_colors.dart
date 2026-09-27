import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds (Clean, modern light aesthetic)
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundSecondary = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceBorder = Color(0xFFE2E8F0);
  static const Color surfaceBorderLight = Color(0xFFF1F5F9);

  // Primary Solid Brand (Royal Blue from the screenshot - NO GRADIENTS)
  static const Color primary = Color(0xFF1D58D8); // Solid Royal Blue
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primarySoft = Color(0xFFEFF6FF); // Very light blue tint
  static const Color primaryCard = Color(0xFF1D58D8); // Today's session card
  static const Color primaryCardInner = Color(0xFF194CBF); // Inner coach tip card

  // Secondary Accents (Solid Colors)
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondarySoft = Color(0xFFCCFBF1);

  // Category & Stat Colors (Exact matches from the design)
  static const Color orange = Color(0xFFEA580C);
  static const Color orangeSoft = Color(0xFFFFF7ED); // Streak / Part 3 bg

  static const Color teal = Color(0xFF0D9488);
  static const Color tealSoft = Color(0xFFF0FDF4); // Time / Part 1 bg
  static const Color tealIcon = Color(0xFF0284C7);
  static const Color tealIconBg = Color(0xFFE0F2FE);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF3E8FF); // Part 2 bg

  static const Color mint = Color(0xFF10B981);
  static const Color mintSoft = Color(0xFFD1FAE5);
  static const Color mintTipBg = Color(0xFF6EE7B7);

  static const Color progressArc = Color(0xFF38BDF8); // Cyan progress ring

  // Assessment & Band Scores (Solid Colors)
  static const Color band9 = Color(0xFF059669);
  static const Color band8 = Color(0xFF0284C7);
  static const Color band7 = Color(0xFF2563EB);
  static const Color band6 = Color(0xFFD97706);
  static const Color band5 = Color(0xFFDC2626);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Deep navy/slate
  static const Color textSecondary = Color(0xFF64748B); // Slate grey
  static const Color textMuted = Color(0xFF94A3B8); // Light grey
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textOverline = Color(0xFF8E9BAE);
}
