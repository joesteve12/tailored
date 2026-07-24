import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/tasks/models/reminder_item.dart';
import 'reminder_service.dart';

/// Stable 31-bit id for a task's notification, derived from the task UUID
/// with FNV-1a. Deterministic across launches and platforms — unlike
/// `String.hashCode`, which Dart does not guarantee stable between runs —
/// so scheduling the same task again REPLACES its pending notification and
/// cancelling by task id always hits. Masked to 31 bits because Android
/// notification ids are Java ints.
///
/// Collision odds across ~2^31 buckets are negligible at to-do-list scale
/// (hundreds of open reminders, not millions); a collision's worst case is
/// one reminder replacing another, not a crash.
@visibleForTesting
int notificationIdForTask(String taskId) {
  var hash = 0x811c9dc5; // FNV offset basis
  for (final unit in taskId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime, keep 32 bits
  }
  return hash & 0x7FFFFFFF;
}

/// v1 delivery: device-local notifications via flutter_local_notifications.
/// See [ReminderService] for the architecture contract this implements.
class LocalReminderService implements ReminderService {
  LocalReminderService({required this.onTapTask});

  /// Invoked with the task id when the user taps a reminder notification
  /// (payload = task id). Wired in the provider layer to router
  /// navigation, so this file stays free of any routing knowledge.
  final void Function(String taskId) onTapTask;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'task_reminders';
  static const _channelName = 'Task reminders';
  static const _channelDescription =
      'Reminders for to-dos with a due time';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone database + the device's own zone: zonedSchedule needs a
    // TZDateTime, and "5 pm" must mean 5 pm where the shop is even across
    // a DST change between now and the reminder instant.
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      final String localName = localTimezone is String
          ? localTimezone as String
          : (() {
              try {
                return (localTimezone as dynamic).identifier as String;
              } catch (_) {
                try {
                  return (localTimezone as dynamic).id as String;
                } catch (_) {
                  return localTimezone.toString();
                }
              }
            })();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Unknown/unmapped zone id: stay on the package default (UTC). The
      // reminder instant is still absolute (remindAt is a moment in time);
      // only DST-crossing display math would be off, which is acceptable
      // over a fallback crash.
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permissions are NOT requested here — see ensurePermissions(); iOS
    // would otherwise prompt at first launch.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onTapTask(payload);
      },
    );
    _initialized = true;
  }

  /// If the app was cold-launched by tapping a reminder, returns that
  /// notification's task id (payload) so the caller can deep-link once the
  /// router is up. Null otherwise.
  Future<String?> launchTaskId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final payload = details!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) return payload;
    }
    return null;
  }

  @override
  Future<bool> ensurePermissions() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Android 13+ runtime permission; a no-op true below 13.
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  @override
  Future<void> scheduleFor(ReminderItem item) async {
    await initialize();
    final when = tz.TZDateTime.from(item.remindAt.toUtc(), tz.local);
    // Never fire late: a reminder whose moment has passed while the app
    // was closed is noise, not help — the in-app Reminders strip covers
    // "you missed one".
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.cancel(notificationIdForTask(item.taskId));
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final id = notificationIdForTask(item.taskId);
    final body = 'Due ${_formatDue(item.dueAt.toLocal())}';
    try {
      await _plugin.zonedSchedule(
        id,
        item.title,
        body,
        when,
        details,
        payload: item.taskId,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e) {
      // Android 12+ without the exact-alarm special access: degrade to an
      // inexact schedule (fires within a system-chosen window) rather than
      // dropping the reminder entirely.
      if (e.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          id,
          item.title,
          body,
          when,
          details,
          payload: item.taskId,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> cancelTask(String taskId) async {
    await initialize();
    await _plugin.cancel(notificationIdForTask(taskId));
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  @override
  Future<void> reconcile(List<ReminderItem> openReminders) async {
    await initialize();
    // Cancel every pending request that isn't in (or no longer matches)
    // the server set, then (re)schedule the whole set. zonedSchedule with
    // the same id replaces in place, so re-scheduling unchanged rows is
    // idempotent and cheap at to-do scale — no diffing bookkeeping to get
    // subtly wrong.
    final wanted = {
      for (final r in openReminders) notificationIdForTask(r.taskId)
    };
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (!wanted.contains(p.id)) {
        await _plugin.cancel(p.id);
      }
    }
    for (final r in openReminders) {
      await scheduleFor(r); // handles past-remindAt rows by cancelling
    }
  }

  String _formatDue(DateTime local) {
    final h12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month} $h12:$minute $ampm';
  }
}
