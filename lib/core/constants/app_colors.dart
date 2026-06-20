import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — Hijau GoCar
  static const Color primary      = Color(0xFF00880D);
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color primaryDark  = Color(0xFF005C08);

  // Accent — Oranye CTA
  static const Color accent      = Color(0xFFFF6B00);
  static const Color accentLight = Color(0xFFFFF3E0);

  // Background
  static const Color background     = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textHint      = Color(0xFF9E9E9E);

  // Semantik
  static const Color income  = Color(0xFF00AA13); // pemasukan
  static const Color expense = Color(0xFFE53935); // pengeluaran
  static const Color warning = Color(0xFFFFA726); // insentif hampir

  // Lain
  static const Color divider = Color(0xFFE0E0E0);
}
