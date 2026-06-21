import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/main_scaffold.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/catat/presentation/catat_screen.dart';
import '../features/incentive/presentation/incentive_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      // Shell: tampil dengan bottom nav
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/catat',
            builder: (context, state) => const CatatScreen(),
          ),
          GoRoute(
            path: '/insentif',
            builder: (context, state) => const InsentifScreen(),
          ),
          GoRoute(
            path: '/laporan',
            builder: (context, state) => const LaporanScreen(),
          ),
        ],
      ),

      // Settings: di luar shell → tidak ada bottom nav
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
