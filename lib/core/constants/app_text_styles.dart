import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // Angka besar Rupiah di dashboard
  static const TextStyle rupiah = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
