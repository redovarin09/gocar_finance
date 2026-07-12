import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

const _kOnboardingDone = 'onboarding_done';

// ── Cek apakah onboarding sudah pernah ditampilkan ───────

Future<bool> isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> setOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

// ── Data tiap halaman ─────────────────────────────────────

class _OnboardingPage {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<_FeatureItem> features;

  const _OnboardingPage({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.features,
  });
}

class _FeatureItem {
  final String emoji;
  final String text;
  const _FeatureItem(this.emoji, this.text);
}

const _pages = [
  _OnboardingPage(
    icon: Icons.directions_car_rounded,
    iconBg: Color(0xFFE8F5E9),
    iconColor: AppColors.primary,
    title: 'Selamat Datang di\nGocarFinance!',
    subtitle: 'Aplikasi pencatatan keuangan\nkhusus Driver GoCar',
    features: [
      _FeatureItem('💰', 'Catat pemasukan & pengeluaran harian'),
      _FeatureItem('🎯', 'Pantau progress insentif GoCar'),
      _FeatureItem('📊', 'Laporan harian, mingguan & bulanan'),
    ],
  ),
  _OnboardingPage(
    icon: Icons.receipt_long_rounded,
    iconBg: Color(0xFFFFF3E0),
    iconColor: AppColors.accent,
    title: 'Catat Trip\ndengan Mudah',
    subtitle: 'Input fare, tip, dan jarak\ndalam kurang dari 15 detik',
    features: [
      _FeatureItem('➕', 'Tap tombol oranye untuk catat trip baru'),
      _FeatureItem('📱', 'Pilih GoPay atau Cash otomatis'),
      _FeatureItem('⚡', 'Dashboard langsung update real-time'),
    ],
  ),
  _OnboardingPage(
    icon: Icons.emoji_events_rounded,
    iconBg: Color(0xFFE8F5E9),
    iconColor: AppColors.primary,
    title: 'Pantau Target\nInsentif Harian',
    subtitle: 'Set target dari aplikasi GoCar\ndan lacak progress otomatis',
    features: [
      _FeatureItem('🎯', 'Dukung multi-tier insentif sekaligus'),
      _FeatureItem('🔔', 'Notifikasi saat insentif hampir tercapai'),
      _FeatureItem('📋', 'Target tersalin otomatis setiap hari'),
    ],
  ),
];

// ── Main Screen ───────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    await setOnboardingDone();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Tombol Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  'Lewati',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPageWidget(
                  page: _pages[i],
                ),
              ),
            ),

            // Indikator + Tombol
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Next / Mulai
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? '🚗 Mulai Mencatat!' : 'Selanjutnya →',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page Widget ───────────────────────────────────────────

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon besar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.iconColor,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            page.subtitle,
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Feature list
          ...page.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: page.iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        f.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      f.text,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
