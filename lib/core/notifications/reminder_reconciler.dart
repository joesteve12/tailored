import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tasks/models/reminder_item.dart';
import '../../features/tasks/state/tasks_providers.dart';
import '../../features/tasks/tasks_paths.dart';
import '../auth/auth_state.dart';
import '../router/app_router.dart';
import 'local_reminder_service.dart';
import 'reminder_service.dart';

/// The app's one ReminderService. Widgets and providers depend on the
/// INTERFACE; this is the only place that names the implementation — the
/// FCM swap point in provider form. The tap handler routes through
/// [taskDetailPath] so the deep link and the (step-3) route registration
/// share one definition.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return LocalReminderService(
    onTapTask: (taskId) {
      ref.read(appRouterProvider).push(taskDetailPath(taskId));
    },
  );
});

/// Keeps the device's scheduled notifications in step with the server,
/// across the whole app lifetime. Read once from TailoredApp.build (a
/// non-autodispose Provider stays alive after first read); everything
/// else is listeners:
///
///  * auth: on login, (re)attach to the reminders feed with a fresh
///    fetch; on logout, detach and CANCEL EVERYTHING — the next account
///    must not inherit this one's notifications. The reminders listener
///    only exists while logged in, so no logged-out 401 fetch spam.
///  * reminders feed: every AsyncData (initial fetch, and every refetch
///    caused by the to-do mutation invalidations in the tasks providers)
///    runs a full reconcile — schedule missing, replace changed, cancel
///    gone/past.
///  * cold start from a notification tap: if the OS launched the app via
///    a reminder, deep-link to that task once; the router's own auth
///    redirect handles the logged-out case.
final reminderReconcilerProvider = Provider<ReminderReconciler>((ref) {
  final reconciler =
      ReminderReconciler(ref, ref.watch(reminderServiceProvider));
  ref.onDispose(reconciler.dispose);
  return reconciler;
});

class ReminderReconciler {
  ReminderReconciler(this._ref, this._service) {
    _init();
  }

  final Ref _ref;
  final ReminderService _service;
  ProviderSubscription<AsyncValue<List<ReminderItem>>>? _remindersSub;

  Future<void> _init() async {
    await _service.initialize();

    // Cold-start deep link (app launched by tapping a reminder). Deferred
    // to after the first frame: this provider is created during
    // TailoredApp's very first build, before the router has a Navigator
    // to push onto.
    final service = _service;
    if (service is LocalReminderService) {
      final launchTaskId = await service.launchTaskId();
      if (launchTaskId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ref.read(appRouterProvider).push(taskDetailPath(launchTaskId));
        });
      }
    }

    _ref.listen<AsyncValue<dynamic>>(
      authStateProvider,
      (prev, next) {
        final wasLoggedIn = prev?.valueOrNull != null;
        final isLoggedIn = next.valueOrNull != null;
        if (isLoggedIn) {
          _attach();
        } else if (wasLoggedIn) {
          // A REAL logout — wipe this account's notifications. The
          // logged-out-at-cold-start case (auth still restoring, prev
          // null) deliberately does nothing: cancelling then immediately
          // re-scheduling on restore would risk dropping a reminder due
          // in the gap, for zero benefit.
          _detach();
        }
      },
      fireImmediately: true,
    );
  }

  void _attach() {
    if (_remindersSub != null) return;
    // Fresh fetch for THIS account — never reconcile against a cached
    // result that may belong to whoever was logged in before.
    _ref.invalidate(taskRemindersProvider);
    _remindersSub = _ref.listen<AsyncValue<List<ReminderItem>>>(
      taskRemindersProvider,
      (_, next) {
        next.whenData(_service.reconcile);
      },
      fireImmediately: true,
    );
  }

  void _detach() {
    _remindersSub?.close();
    _remindersSub = null;
    _service.cancelAll();
  }

  void dispose() {
    _remindersSub?.close();
    _remindersSub = null;
  }
}
