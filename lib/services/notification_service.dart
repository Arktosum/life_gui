import 'dart:ui'; // NEW IMPORT FOR THE COLOR CLASS
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();

    // 2. Set the Android Icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // FIX 1: Use the named parameter 'initializationSettings'
    await _notificationsPlugin.initialize(settings: initSettings);

    // 3. Request Permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  // THE TIME BOMB: Resets the 8:00 PM reminder for tomorrow
  Future<void> scheduleDailyReminder() async {
    // 1. Defuse any existing bombs
    await _notificationsPlugin.cancelAll();

    // 2. Calculate Tomorrow at 8:00 PM
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      0,
    ); // 20:00 = 8:00 PM

    // If it's already past 8:00 PM today, schedule for tomorrow
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // 3. Plant the new bomb
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Reminds you to log your day if you forget',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF6200EA), // FIX 2: Wrapped in the Color class!
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // FIX 3: All parameters are now strictly named
    // FIX 4: Removed the deprecated uiLocalNotificationDateInterpretation
    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: "Timeline Check-in ⏱️",
      body:
          "Your timeline is looking a little empty today. Time to log your evening!",
      scheduledDate: scheduledTime,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
