import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../shared/providers/theme_provider.dart';
import 'router.dart';

class GocarFinanceApp extends ConsumerWidget {
  const GocarFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'GocarFinance',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme:     _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      routerConfig: router,
    );
  }

  // ── Light Theme ────────────────────────────────────────

  ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: AppColors.cardBackground,
        elevation: 8,
      ),
      cardColor: AppColors.cardBackground,
      dividerColor: AppColors.divider,
    );
  }

  // ── Dark Theme ─────────────────────────────────────────

  ThemeData _buildDarkTheme() {
    const darkBg    = Color(0xFF121212);
    const darkCard  = Color(0xFF1E1E1E);
    const darkCard2 = Color(0xFF252525);
    const darkText  = Color(0xFFF0F0F0);
    const darkSub   = Color(0xFF9E9E9E);
    const darkDiv   = Color(0xFF2E2E2E);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary:   AppColors.primary,
        secondary: AppColors.accent,
      ),
      scaffoldBackgroundColor: darkBg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor:    darkText,
        displayColor: darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: darkText,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: darkCard,
        elevation: 8,
      ),
      cardColor:     darkCard2,
      dividerColor:  darkDiv,
      iconTheme:     const IconThemeData(color: darkText),
      listTileTheme: const ListTileThemeData(
        textColor:  darkText,
        iconColor:  darkSub,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        hintStyle: TextStyle(color: darkSub),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkDiv),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkDiv),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.primary, width: 2),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkCard,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: darkSub,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard2,
        contentTextStyle:
            GoogleFonts.poppins(color: darkText),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
