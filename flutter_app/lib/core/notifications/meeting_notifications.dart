import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../models/schedule_models.dart';

const String kMeetingNotifEnabled = 'meeting_notif_enabled';
const String kMeetingNotifDelayMin = 'meeting_notif_delay_min';
const String kMeetingNotifHeadsUp = 'meeting_notif_heads_up';

const String _channelId = 'leccheck_meeting_followup';
const String _channelName = 'Meeting follow-up';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

/// Linux builds skip local notification plugin init (not supported reliably).
bool get meetingNotificationsSupportedOnPlatform {
  if (kIsWeb) return false;
  if (defaultTargetPlatform == TargetPlatform.linux) return false;
  return true;
}

void Function(String payload, String actionId)? _actionHandler;

void setMeetingNotificationActionHandler(
  void Function(String payload, String actionId)? handler,
) {
  _actionHandler = handler;
}

void _onNotificationResponse(NotificationResponse response) {
  final p = response.payload;
  if (p == null) return;
  final action = response.actionId;
  if (action != null && action.isNotEmpty) {
    _actionHandler?.call(p, action);
  }
}

Future<void> initMeetingNotifications() async {
  if (kIsWeb || !meetingNotificationsSupportedOnPlatform) return;
  tzdata.initializeTimeZones();
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
  } on Object {
    tz.setLocalLocation(tz.UTC);
  }
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await _plugin.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: _onNotificationResponse,
  );
}

Future<bool> requestAndroidNotificationPermission() async {
  if (kIsWeb) return false;
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android == null) return false;
  final r = await android.requestNotificationsPermission();
  return r ?? false;
}

Future<void> rescheduleMeetingNotifications(ScheduleRootState? root) async {
  if (kIsWeb || !meetingNotificationsSupportedOnPlatform) return;
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool(kMeetingNotifEnabled) ?? false;
  await _plugin.cancelAll();
  if (!enabled || root == null) return;

  final delayMin = (prefs.getInt(kMeetingNotifDelayMin) ?? 5).clamp(0, 120);
  final headsUp = prefs.getBool(kMeetingNotifHeadsUp) ?? true;
  final importance =
      headsUp ? Importance.high : Importance.defaultImportance;
  final priority = headsUp ? Priority.high : Priority.defaultPriority;

  final sch = root.activeSchedule;
  final now = DateTime.now();
  const maxSched = 48;
  var count = 0;

  for (final c in sch.courses) {
    for (final l in c.lectures) {
      if (count >= maxSched) return;
      if (l.status == LectureStatus.canceled ||
          l.status == LectureStatus.skipped) {
        continue;
      }
      final end = _lectureEndDateTime(l);
      var trigger = end.add(Duration(minutes: delayMin));
      if (!trigger.isAfter(now)) continue;

      final id = _notifId(l);
      final payload = _payload(l);
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'After a session ends, quick status update',
        importance: importance,
        priority: priority,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'attended',
            'Attended',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'missed',
            'Missed',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'skipped',
            'Skipped',
            showsUserInterface: true,
          ),
        ],
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(trigger, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'How was class?',
          body: l.courseName,
          payload: payload,
        );
        count++;
      } on Object catch (e, st) {
        if (kDebugMode) {
          debugPrint('Failed to schedule notification for ${l.courseName}: $e\n$st');
        }
      }
    }
  }
}

DateTime _lectureEndDateTime(Lecture l) {
  final p = l.end.split(':');
  final h = int.parse(p[0]);
  final m = int.parse(p[1]);
  return DateTime(l.date.year, l.date.month, l.date.day, h, m);
}

int _notifId(Lecture l) => _payload(l).hashCode & 0x7fffffff;

String _payload(Lecture l) =>
    '${l.courseId}|${scheduleDateKey(l.date)}|${l.start}|${l.end}';

Future<bool> getMeetingNotificationsEnabled() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(kMeetingNotifEnabled) ?? false;
}

Future<void> setMeetingNotificationsEnabled(bool value) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kMeetingNotifEnabled, value);
}

Future<int> getMeetingNotificationDelayMinutes() async {
  final p = await SharedPreferences.getInstance();
  return (p.getInt(kMeetingNotifDelayMin) ?? 5).clamp(0, 120);
}

Future<void> setMeetingNotificationDelayMinutes(int minutes) async {
  final p = await SharedPreferences.getInstance();
  await p.setInt(kMeetingNotifDelayMin, minutes.clamp(0, 120));
}

Future<bool> getMeetingNotificationsHeadsUp() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(kMeetingNotifHeadsUp) ?? true;
}

Future<void> setMeetingNotificationsHeadsUp(bool value) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kMeetingNotifHeadsUp, value);
}
