import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static int _locationToIndex(String path) {
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/catat'))     return 1;
    if (path.startsWith('/insentif'))  return 2;
    if (path.startsWith('/laporan'))   return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/catat'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNavBar(selectedIndex: selectedIndex),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  const _BottomNavBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.cardBackground,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Dashboard',
            selected: selectedIndex == 0,
            onTap: () => context.go('/dashboard'),
          ),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Catat',
            selected: selectedIndex == 1,
            onTap: () => context.go('/catat'),
          ),
          const SizedBox(width: 56), // gap FAB
          _NavItem(
            icon: Icons.emoji_events_rounded,
            label: 'Insentif',
            selected: selectedIndex == 2,
            onTap: () => context.go('/insentif'),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Laporan',
            selected: selectedIndex == 3,
            onTap: () => context.go('/laporan'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
