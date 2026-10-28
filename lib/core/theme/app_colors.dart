import 'package:flutter/material.dart';

/// FitDesk renk paleti (Stitch DESIGN.md'den).
abstract final class AppColors {
  static const surface = Color(0xFFF9FAF6);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F0);
  static const surfaceContainer = Color(0xFFEDEEEA);
  static const surfaceContainerHigh = Color(0xFFE7E9E5);
  static const surfaceContainerHighest = Color(0xFFE2E3DF);
  static const onSurface = Color(0xFF1A1C1A);
  static const onSurfaceVariant = Color(0xFF414943);
  static const outline = Color(0xFF717973);
  static const outlineVariant = Color(0xFFC0C9C1);

  static const primary = Color(0xFF003621);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1A4D36);
  static const onPrimaryContainer = Color(0xFF89BD9F);
  static const primaryFixed = Color(0xFFB9EFCF);

  static const secondary = Color(0xFF006C49);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondaryContainer = Color(0xFF00714D);
  static const secondaryFixed = Color(0xFF6FFBBE);
  static const secondaryFixedDim = Color(0xFF4EDEA3);
  static const onSecondaryFixed = Color(0xFF002113);

  /// Kart gölgesi (tasarımdaki rgba(20,56,40,…)).
  static const cardShadow = Color(0x0D143828);
  static const streak = Color(0xFFF2711C);

  static const tertiary = Color(0xFF003524);
  static const tertiaryContainer = Color(0xFF004E37);
  static const tertiaryFixed = Color(0xFFA6F2CF);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}
