import '../../features/tasks/models/reminder_item.dart';

/// The ONLY code in the app allowed to know how a reminder physically
/// reaches the user. Today that's device-local notifications
/// ([LocalReminderService]); when server push (FCM) lands, it becomes a
/// second implementation behind this same interface plus a server-side
/// sender — zero call-site changes. Keep it that way: if a widget ever
/// imports flutter_local_notifications directly, the swap point is broken.
///
/// The SERVER row is the single source of truth for *when* a reminder
/// fires: `remind_at` arrives computed on every [ReminderItem] and this
/// service never derives it locally. The device is just one delivery
/// mechanism reading that truth — which is exactly why reconciliation
/// (not fire-and-forget scheduling) is the core operation.
///
/// Known v1 limitation, accepted by design: a local notification fires on
/// devices that have synced the task; an edit made on another device
/// reschedules here only at the next sync. That is precisely the gap FCM
/// closes later.
abstract class ReminderService {
  /// One-time platform initialization (plugin setup, timezone database,
  /// tap-handler registration). Called from bootstrap before any other
  /// method; must be safe to call more than once.
  Future<void> initialize();

  /// Ask the OS for notification permission if not yet granted. Called on
  /// first USE of a reminder (the to-do sheet, when the user actually
  /// picks an offset) — never at app start; a permission dialog before
  /// the user has expressed any interest in reminders is how apps get
  /// denied forever. Returns whether notifications may be shown. A false
  /// return isn't fatal: reminders still exist server-side and the
  /// in-app Reminders strip remains the fallback surface.
  Future<bool> ensurePermissions();

  /// Schedule (or replace) the one notification for [item] at its
  /// server-computed `remindAt`. A past `remindAt` is never scheduled —
  /// no late fires.
  Future<void> scheduleFor(ReminderItem item);

  /// Cancel the notification for one task, if any (completed / deleted /
  /// reminder removed).
  Future<void> cancelTask(String taskId);

  /// Cancel everything this app ever scheduled. Used on logout — the next
  /// account's reminders must not inherit the previous account's
  /// notifications.
  Future<void> cancelAll();

  /// Make the device's scheduled set match [openReminders] (the full
  /// `GET /tasks/reminders` payload) exactly: schedule what's missing,
  /// replace what changed, cancel what's gone or past. Runs on app start
  /// and after every to-do mutation (the provider invalidation refires
  /// the listener that calls this).
  Future<void> reconcile(List<ReminderItem> openReminders);
}
