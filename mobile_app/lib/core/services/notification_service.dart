import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local notifications.
///
/// Handles:
/// - Daily practice reminders (scheduled at a user-chosen time)
/// - Immediate notifications (recording saved, streak achieved)
/// - Permission requests (iOS & Android 13+)
class NotificationService {
  static const _prefEnabled = 'notif_reminders_enabled';
  static const _prefHour = 'notif_reminder_hour';
  static const _prefMinute = 'notif_reminder_minute';
  static const _prefPermissionAsked = 'notif_permission_asked';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification channel IDs
  static const _channelId = 'ielts_speaky_reminders';
  static const _channelName = 'Practice Reminders';
  static const _channelDesc = 'Daily reminders to practice IELTS speaking.';

  // Notification IDs
  static const _dailyReminderId = 0;
  static const _recordingSavedId = 1;
  static const _streakReminderId = 2;
  static const _testCompletedId = 3;

  /// Initializes the notification plugin and timezone data.
  /// Call once at app startup.
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Callback when user taps a notification.
  void Function(NotificationResponse)? _onTapCallback;

  void setOnTapCallback(void Function(NotificationResponse)? callback) {
    _onTapCallback = callback;
  }

  void _onNotificationTapped(NotificationResponse response) {
    _onTapCallback?.call(response);
  }

  /// Requests notification permission from the user.
  ///
  /// On iOS: shows the system permission dialog.
  /// On Android 13+: shows the POST_NOTIFICATIONS permission dialog.
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    if (!_initialized) await init();

    bool granted = false;

    // iOS permission
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final result = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }

    // Android 13+ permission
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final result =
          await androidImpl.requestNotificationsPermission();
      granted = granted || (result ?? false);
    }

    // Mark permission as asked
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPermissionAsked, true);

    return granted;
  }

  /// Checks if notification permission has been asked before.
  Future<bool> hasAskedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefPermissionAsked) ?? false;
  }

  /// Checks if daily reminders are enabled.
  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabled) ?? false;
  }

  /// Gets the configured reminder time.
  Future<(int hour, int minute)> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_prefHour) ?? 19; // Default: 7 PM
    final minute = prefs.getInt(_prefMinute) ?? 0;
    return (hour, minute);
  }

  /// Enables daily practice reminders at the specified time.
  /// Requests permission first if not already granted.
  Future<bool> enableDailyReminder({int hour = 19, int minute = 0}) async {
    if (!_initialized) await init();

    // Request permission
    final granted = await requestPermission();
    if (!granted) return false;

    // Schedule the daily reminder
    await _scheduleDailyReminder(hour, minute);

    // Save settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, true);
    await prefs.setInt(_prefHour, hour);
    await prefs.setInt(_prefMinute, minute);

    return true;
  }

  /// Disables daily practice reminders.
  Future<void> disableDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, false);
  }

  /// Schedules the daily reminder notification.
  Future<void> _scheduleDailyReminder(int hour, int minute) async {
    // Cancel any existing reminder first
    await _plugin.cancel(_dailyReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Time to practice speaking!',
      'Keep your streak alive. Open IELTS Speaky and practice for 5 minutes.',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Shows an immediate notification when a recording is saved.
  Future<void> showRecordingSavedNotification(String title, String duration) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _recordingSavedId,
      'Recording Saved',
      '"$title" ($duration) is ready to review in your dictaphone.',
      platformDetails,
    );
  }

  /// Shows a streak reminder notification.
  Future<void> showStreakNotification(int streakDays) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _streakReminderId,
      '🔥 $streakDays-day streak!',
      'You\'re on fire! Open IELTS Speaky to keep your streak going.',
      platformDetails,
    );
  }

  /// Shows a notification when a mock test is completed.
  Future<void> showTestCompletedNotification(double bandScore) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _testCompletedId,
      'Mock Test Completed!',
      'Your estimated band score: ${bandScore.toStringAsFixed(1)}. Tap to see details.',
      platformDetails,
    );
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Checks if the app was launched from a notification.
  Future<NotificationResponse?> getInitialNotification() async {
    if (!_initialized) await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.notificationResponse;
  }
}
