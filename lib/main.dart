import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  final onboardingDone = await isOnboardingDone();

  final container = ProviderContainer();
  container.read(autoBackupSessionProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: GocarFinanceApp(showOnboarding: !onboardingDone),
    ),
  );
}
