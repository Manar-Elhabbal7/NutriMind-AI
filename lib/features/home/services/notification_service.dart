import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!isSupportedPlatform) return;
    tz.initializeTimeZones();
    try {
      final TimezoneInfo timeZoneInfo =
          await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Failed to get local timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<bool> requestPermissions() async {
    if (!isSupportedPlatform) return false;
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final bool androidGranted =
        await androidImplementation?.requestNotificationsPermission() ?? false;

    final bool iosGranted =
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;

    return androidGranted || iosGranted;
  }

  Future<void> scheduleWaterReminders() async {
    if (!isSupportedPlatform) return;
    // Cancel any previous scheduled reminders to avoid duplication
    await cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled =
        prefs.getBool('water_reminder_enabled') ?? true; // default to true
    if (!isEnabled) return;
    // Schedule a small initial batch immediately so startup stays snappy,
    // then schedule the remaining reminders in the background in a throttled way.
    const int totalReminders = 60;
    const int initialBatch = 8; // schedule the first 8 now

    final List<Future<void>> scheduleFutures = [];
    for (int i = 1; i <= initialBatch && i <= totalReminders; i++) {
      final scheduledTime = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(hours: 3 * i));
      scheduleFutures.add(
        flutterLocalNotificationsPlugin.zonedSchedule(
          id: i,
          title: 'Stay Hydrated! 💧',
          body: 'Time to drink some water and stay healthy!',
          scheduledDate: scheduledTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'water_reminder_channel',
              'Water Reminders',
              channelDescription: 'Channel for daily water intake reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        ),
      );
    }
    await Future.wait(scheduleFutures);

    // Schedule the remaining reminders without blocking startup; space them
    // out to avoid flooding platform channels.
    unawaited(_scheduleRemainingReminders(totalReminders, initialBatch));
  }

  Future<void> _scheduleRemainingReminders(
    int total,
    int alreadyScheduled,
  ) async {
    if (!isSupportedPlatform) return;
    for (int i = alreadyScheduled + 1; i <= total; i++) {
      try {
        final scheduledTime = tz.TZDateTime.now(
          tz.local,
        ).add(Duration(hours: 3 * i));
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: i,
          title: 'Stay Hydrated! 💧',
          body: 'Time to drink some water and stay healthy!',
          scheduledDate: scheduledTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'water_reminder_channel',
              'Water Reminders',
              channelDescription: 'Channel for daily water intake reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        // small delay to yield to the event loop and avoid saturating platform channels
        await Future.delayed(const Duration(milliseconds: 120));
      } catch (e) {
        debugPrint('Failed to schedule reminder $i: $e');
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!isSupportedPlatform) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
