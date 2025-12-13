import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/meal_detail.dart';
import '../services/meal_api_service.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final MealApiService _mealApiService = MealApiService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _dailyChannel = AndroidNotificationChannel(
    'daily_recipe_channel',
    'Daily Recipes',
    description: 'Notifications reminding you to check the random recipe of the day',
    importance: Importance.high,
  );

  static const int _dailyNotificationId = 1001;

  bool _isInitialized = false;
  bool _notificationPluginReady = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _ensureNotificationPluginReady();
    await _requestMessagingPermission();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    await scheduleDailyRandomRecipe();
    _isInitialized = true;
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _ensureNotificationPluginReady();
    await _showNotificationFromMessage(message);
  }

  Future<void> scheduleDailyRandomRecipe({
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    final MealDetail randomMeal = await _mealApiService.getRandomMeal();
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(reminderTime);

    await _localNotifications.zonedSchedule(
      _dailyNotificationId,
      'Random recipe of the day',
      'Check out ${randomMeal.strMeal} today!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannel.id,
          _dailyChannel.name,
          channelDescription: _dailyChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'recipe-of-the-day',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: randomMeal.idMeal,
    );
  }

  Future<void> _requestMessagingPermission() async {
    await _messaging.requestPermission();
    await _messaging.setAutoInitEnabled(true);
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _localNotifications.initialize(initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_dailyChannel);
  }

  Future<void> _ensureNotificationPluginReady() async {
    if (_notificationPluginReady) return;
    await _configureTimeZone();
    await _initLocalNotifications();
    _notificationPluginReady = true;
  }

  Future<void> _configureTimeZone() async {
    tzdata.initializeTimeZones();
    final String timeZoneName = DateTime.now().timeZoneName;
    if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } else {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showNotificationFromMessage(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    await _showNotificationFromMessage(message);
  }

  Future<void> _showNotificationFromMessage(RemoteMessage message) async {
    final String title = message.notification?.title ??
        message.data['title'] ??
        'Recipe reminder';
    final String body = message.notification?.body ??
        message.data['body'] ??
        'Open the app to discover today\'s random recipe!';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannel.id,
          _dailyChannel.name,
          channelDescription: _dailyChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['mealId'],
    );
  }
}

Future<void> configureFirebaseMessagingBackgroundHandler() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.handleBackgroundMessage(message);
}
