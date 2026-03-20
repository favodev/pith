import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class BirthdayReminderTarget {
  const BirthdayReminderTarget({
    required this.contactId,
    required this.name,
    required this.birthday,
  });

  final String contactId;
  final String name;
  final DateTime birthday;
}

class BirthdayNotificationService {
  BirthdayNotificationService._();

  static final BirthdayNotificationService instance = BirthdayNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Set<String> _sessionLateReminderKeys = <String>{};
  bool _initialized = false;

  static const _androidChannelId = 'pith_birthdays';
  static const _androidChannelName = 'Cumpleaños';
  static const _androidChannelDescription = 'Recordatorios de cumpleaños de contactos';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    await _setLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> syncBirthdays(List<BirthdayReminderTarget> reminders) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);

    final pending = await _plugin.pendingNotificationRequests();
    for (final item in pending) {
      final payload = item.payload ?? '';
      if (payload.startsWith('birthday:')) {
        await _plugin.cancel(item.id);
      }
    }

    for (final reminder in reminders) {
      final id = _notificationIdForContact(reminder.contactId);
      final scheduledAt = _nextBirthdayAtNine(reminder.birthday);
      final isBirthdayToday =
          now.month == reminder.birthday.month && now.day == reminder.birthday.day;

      if (isBirthdayToday && scheduledAt.isBefore(now.add(const Duration(minutes: 2)))) {
        final dateKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final lateKey = '${reminder.contactId}:$dateKey';
        if (_sessionLateReminderKeys.add(lateKey)) {
          await _plugin.show(
            id,
            'Cumpleaños hoy',
            'Hoy esta de cumple ${reminder.name}.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannelId,
                _androidChannelName,
                channelDescription: _androidChannelDescription,
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            payload: 'birthday:${reminder.contactId}',
          );
        }

        final nextYear = _birthdayAtHour(
          year: now.year + 1,
          month: reminder.birthday.month,
          day: reminder.birthday.day,
          hour: 9,
        );

        await _plugin.zonedSchedule(
          id,
          'Cumpleaños hoy',
          'Hoy esta de cumple ${reminder.name}.',
          nextYear,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannelId,
              _androidChannelName,
              channelDescription: _androidChannelDescription,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: 'birthday:${reminder.contactId}',
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        continue;
      }

      await _plugin.zonedSchedule(
        id,
        'Cumpleaños hoy',
        'Hoy esta de cumple ${reminder.name}.',
        scheduledAt,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'birthday:${reminder.contactId}',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _setLocalTimezone() async {
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
  }

  tz.TZDateTime _nextBirthdayAtNine(DateTime birthday) {
    final now = tz.TZDateTime.now(tz.local);
    final isToday = now.month == birthday.month && now.day == birthday.day;

    if (isToday) {
      final todayAtNine = _birthdayAtHour(
        year: now.year,
        month: birthday.month,
        day: birthday.day,
        hour: 9,
      );
      if (todayAtNine.isBefore(now)) {
        return now.add(const Duration(minutes: 1));
      }
      return todayAtNine;
    }

    var candidate = _birthdayAtHour(year: now.year, month: birthday.month, day: birthday.day, hour: 9);
    if (candidate.isBefore(now)) {
      candidate = _birthdayAtHour(year: now.year + 1, month: birthday.month, day: birthday.day, hour: 9);
    }

    return candidate;
  }

  tz.TZDateTime _birthdayAtHour({
    required int year,
    required int month,
    required int day,
    required int hour,
  }) {
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextMonthYear = month == 12 ? year + 1 : year;
    final maxDay = DateTime(nextMonthYear, nextMonth, 0).day;
    final safeDay = day.clamp(1, maxDay).toInt();
    return tz.TZDateTime(tz.local, year, month, safeDay, hour);
  }

  int _notificationIdForContact(String contactId) {
    final raw = contactId.hashCode & 0x7fffffff;
    return raw % 2000000000;
  }
}
