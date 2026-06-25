import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/currency_formatter.dart';
import '../../features/incentive/data/models/incentive_target_model.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Channel ID
  static const _channelId   = 'gocarfinance_incentive';
  static const _channelName = 'Insentif GocarFinance';
  static const _channelDesc =
      'Notifikasi progress insentif driver GoCar';

  // ── Init ─────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings =
        InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    // Buat notification channel (Android 8+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Minta permission Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Cek & Kirim Notifikasi ────────────────────────────────

  static Future<void> checkInsentif({
    required int currentTrips,
    required List<IncentiveTargetModel> targets,
  }) async {
    if (!_initialized) await initialize();
    if (targets.isEmpty) return;

    for (final target in targets) {
      final remaining = target.tripTarget - currentTrips;
      final bonus = CurrencyFormatter.formatCompact(target.bonusAmount);
      final id = target.id ?? 0;

      if (remaining == 0) {
        // Tercapai!
        await _show(
          id: id,
          title: '🎉 Insentif Tercapai!',
          body:
              '${target.tierName} selesai! '
              'Bonus $bonus siap diklaim. Selamat! 🚗',
          largeIcon: '🏆',
        );
      } else if (remaining == 1) {
        await _show(
          id: id + 1000,
          title: '🔥 1 Trip Lagi!',
          body:
              'Kurang 1 trip untuk ${target.tierName}! '
              'Bonus $bonus menantimu.',
          largeIcon: '⚡',
        );
      } else if (remaining == 3) {
        await _show(
          id: id + 2000,
          title: '🎯 Hampir Sampai!',
          body:
              '$remaining trip lagi untuk ${target.tierName}. '
              'Bonus $bonus sudah dekat!',
          largeIcon: '🎯',
        );
      }
    }
  }

  // ── Notifikasi Manual ─────────────────────────────────────

  static Future<void> showPengingat({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();
    await _show(id: 9999, title: title, body: body);
  }

  // ── Private ───────────────────────────────────────────────

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? largeIcon,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      ticker: title,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  // ── Batalkan semua notif ──────────────────────────────────

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
