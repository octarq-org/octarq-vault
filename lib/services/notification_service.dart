import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Completer<void> _initCompleter = Completer<void>();

  Future<void> init() async {
    if (kIsWeb) {
      _initCompleter.complete();
      return;
    }
    try {
      tz.initializeTimeZones();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('app_icon');
      
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );
      
      await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
    }
  }

  Future<void> scheduleExpirationNotification(
      int id, String assetName, DateTime expirationDate, int daysOffset) async {
    if (kIsWeb) return;

    // Wait for init to complete before using tz.local
    await _initCompleter.future;
    
    final notificationDate = expirationDate.subtract(Duration(days: daysOffset));
    if (notificationDate.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'Asset Expiring Soon',
      body: '$assetName is expiring in $daysOffset days.',
      scheduledDate: tz.TZDateTime.from(notificationDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiration_channel',
          'Asset Expirations',
          channelDescription: 'Notifications for expiring assets',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.init();
  return service;
});
