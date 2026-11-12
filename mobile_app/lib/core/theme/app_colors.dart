import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds & Surfaces (Clean Calm Focus aesthetic)
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundSecondary = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceBorder = Color(0xFFE2E8F0);
  static const Color surfaceBorderLight = Color(0xFFE2E8F0);

  // Brand Primary: Speaky Indigo (single recognizable brand color)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryCard = Color(0xFF4F46E5);
  static const Color primaryCardInner = Color(0xFF4338CA);
  static const Color progressArc = Color(0xFFC7D2FE);

  // Semantic Accents (used strictly for status, never decorative rainbows)
  static const Color secondary = Color(0xFF10B981); // Success / Band 8+
  static const Color secondarySoft = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFD97706); // Amber / Caution / Focus
  static const Color warningSoft = Color(0xFFFFFBEB);

  static const Color rose = Color(0xFFE11D48); // Recording Active / Destructive
  static const Color roseSoft = Color(0xFFFFF1F2);

  // Unified aliases (mapped strictly to the 4 brand/semantic tokens above)
  static const Color teal = secondary;
  static const Color tealSoft = secondarySoft;
  static const Color tealIcon = primary;
  static const Color tealIconBg = primarySoft;

  static const Color orange = warning;
  static const Color orangeSoft = warningSoft;

  static const Color purple = primary;
  static const Color purpleSoft = primarySoft;

  static const Color mint = secondary;
  static const Color mintSoft = secondarySoft;
  static const Color mintTipBg = primarySoft;

  // Assessment & Band Scores
  static const Color band9 = secondary;
  static const Color band8 = primary;
  static const Color band7 = primaryLight;
  static const Color band6 = warning;
  static const Color band5 = rose;

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textOverline = Color(0xFF64748B);
}
