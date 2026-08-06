import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/complete_profile_screen.dart';
import '../../features/shell/main_shell_screen.dart';
import '../../features/home/screens/home_tab_screen.dart';
import '../../features/tasks/screens/tasks_tab_screen.dart';
import '../../features/tasks/screens/task_detail_screen.dart';
import '../../features/tasks/screens/create_task_screen.dart';
import '../../features/tasks/screens/processes_screen.dart';
import '../../features/tasks/tasks_paths.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/clients/models/client.dart';
import '../../features/clients/screens/client_list_screen.dart';
import '../../features/clients/screens/client_detail_screen.dart';
import '../../features/clients/screens/client_form_screen.dart';
import 'hero_page.dart';
import '../../features/guests/screens/guest_detail_screen.dart';
import '../../features/guests/screens/guest_form_screen.dart';
import '../models/recipient_ref.dart';
import '../../features/measurements/screens/measurement_capture_screen.dart';
import '../../features/measurements/screens/measurement_history_screen.dart';
import '../../features/measurements/screens/measurement_set_detail_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/order_form_screen.dart';
import '../../features/orders/screens/order_list_screen.dart';
import '../../features/fabrics/screens/fabric_inventory_screen.dart';
import '../../features/fabrics/screens/fabric_detail_screen.dart';
import '../../features/employees/screens/employee_list_screen.dart';
import '../../features/employees/screens/employee_form_screen.dart';
import '../../features/employees/screens/employee_detail_screen.dart';
import '../../features/measurements/screens/measurement_fields_screen.dart';
import '../../features/measurements/screens/measurement_field_form_screen.dart';
import '../../features/measurements/screens/measurement_templates_screen.dart';
import '../../features/measurements/screens/measurement_template_form_screen.dart';
import '../auth/auth_state.dart';
import '../auth/models/user.dart';

/// Bridges Riverpod's AsyncNotifier-based auth state to go_router's
/// ChangeNotifier-based refreshListenable, so the redirect guard re-runs when
/// auth changes in the background (e.g. a 401-triggered logout).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AsyncValue<dynamic>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  late final ProviderSubscription _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // Still checking secure storage on cold start — hold position rather
      // than flashing /login and back once the check resolves.
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      const publicRoutes = {'/login', '/register'};
      const completeProfilePath = '/complete-profile';
      final isOnPublicRoute = publicRoutes.contains(state.matchedLocation);
      final isOnCompleteProfile =
          state.matchedLocation == completeProfilePath;

      // Not logged in: only the public auth routes are reachable.
      if (!isLoggedIn) {
        return isOnPublicRoute ? null : '/login';
      }

      // Logged in but the profile is missing fields registration now requires
      // (Google signups, pre-existing accounts) — funnel to /complete-profile
      // and keep them there until it's filled in. This gate outranks the
      // public-route bounce below so a half-set-up account can't slip into the
      // app via /login or /register.
      if (!user.isProfileComplete) {
        return isOnCompleteProfile ? null : completeProfilePath;
      }

      // Complete profile: keep them out of the auth-only screens.
      if (isOnPublicRoute || isOnCompleteProfile) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      // The five-tab bottom-nav shell. Only the tab ROOTS live in branches
      // (so the nav bar persists and each tab keeps its own stack). Detail and
      // form screens are top-level routes below, rendering full-screen over
      // the shell on the root navigator.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeTabScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrderListScreen(),
            ),
          ]),
          // Tasks — the new third branch, replacing Dashboard's slot in the
          // bar. `tasksTabPath` and `taskDetailPath` are the shared constants
          // the notification tap handler also uses, so the deep link and the
          // registered route can't drift.
          StatefulShellBranch(routes: [
            GoRoute(
              path: tasksTabPath,
              // `?filter=delayed|due_today|due_tomorrow` preselects a tab —
              // the Home chips deep-link with it. Absent/invalid values
              // fall back to Active inside the screen.
              builder: (context, state) => TasksTabScreen(
                initialFilter: state.uri.queryParameters['filter'],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/clients',
              builder: (context, state) => const ClientListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),

      // Customers: detail + form + nested guests + measurements
      GoRoute(
        path: '/clients/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id',
        // pageBuilder, not builder — two reasons, both about the avatar Hero:
        //
        // 1. HeroPage slows the route transition from the platform default
        //    300ms to 400ms. A Hero's flight lasts exactly as long as the
        //    destination route's transition, so this is the only place the
        //    flight speed can be set at all. See hero_page.dart.
        //
        // 2. `extra` carries the Client the caller already had in hand (the
        //    list row and the order tile both render an avatar from it). The
        //    destination Hero must be in the widget tree on the FIRST frame of
        //    the transition — the HeroController matches tags once, at flight
        //    start, and never re-checks. Without `extra`, ClientDetailScreen
        //    opens on AsyncLoading, shows a spinner, has no Hero, and Flutter
        //    silently runs no flight at all. Seeding it means the avatar is
        //    there on frame 1 and the flight happens.
        //
        // Null when deep-linked or cold-started (nothing to seed from): the
        // screen falls back to the spinner and there's no flight, which is
        // correct — there's no origin avatar to fly *from*.
        pageBuilder: (context, state) => HeroPage<void>(
          key: state.pageKey,
          child: ClientDetailScreen(
            clientId: state.pathParameters['id']!,
            initialClient: state.extra is Client ? state.extra! as Client : null,
          ),
        ),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (context, state) =>
            ClientFormScreen(clientId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/clients/:clientId/guests/new',
        builder: (context, state) =>
            GuestFormScreen(clientId: state.pathParameters['clientId']!),
      ),
      GoRoute(
        path: '/clients/:clientId/guests/:guestId',
        builder: (context, state) => GuestDetailScreen(
          clientId: state.pathParameters['clientId']!,
          guestId: state.pathParameters['guestId']!,
        ),
      ),
      GoRoute(
        path: '/clients/:clientId/guests/:guestId/edit',
        builder: (context, state) => GuestFormScreen(
          clientId: state.pathParameters['clientId']!,
          guestId: state.pathParameters['guestId'],
        ),
      ),

      // Measurements. `new` and `history` carry a RecipientRef via `extra`
      // (pinned by the launching screen); sets are addressable by id.
      GoRoute(
        path: '/measurements/new',
        builder: (context, state) =>
            MeasurementCaptureScreen(recipient: state.extra as RecipientRef),
      ),
      GoRoute(
        path: '/measurements/history',
        builder: (context, state) {
          // ``?template=<id>`` filters the history to a single template; the
          // ``kCustomTemplateFilter`` sentinel restricts to sets captured
          // without any template. Absent/empty query param means the classic
          // unfiltered view.
          final raw = state.uri.queryParameters['template'];
          final filter = (raw == null || raw.isEmpty) ? null : raw;
          return MeasurementHistoryScreen(
            recipient: state.extra as RecipientRef,
            templateFilter: filter,
          );
        },
      ),
      GoRoute(
        path: '/measurements/sets/:id',
        builder: (context, state) =>
            MeasurementSetDetailScreen(setId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/measurements/sets/:id/edit',
        builder: (context, state) =>
            MeasurementCaptureScreen(setId: state.pathParameters['id']!),
      ),

      // Dashboard — moved out of the bottom nav; reached from Settings.
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Task detail — a full-screen route (over the shell) reached from
      // the Tasks tab, the Home chips, an order item's chip, or a
      // reminder notification tap.
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),

      // Create the production task for one order item (reached from the
      // item's "Create task" affordance on the order detail — step 6).
      GoRoute(
        path: '/orders/:orderId/items/:itemId/task/new',
        builder: (context, state) => CreateTaskScreen(
          orderId: state.pathParameters['orderId']!,
          itemId: state.pathParameters['itemId']!,
        ),
      ),

      // Orders: create + detail
      GoRoute(
        path: '/orders/new',
        builder: (context, state) =>
            OrderFormScreen(clientId: state.extra as String),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),

      // Fabric inventory: list/search + per-serial detail (reached from Home).
      // `/fabrics/:serial` must stay below `/orders/:id` style top-level routes;
      // serial is a path segment (e.g. FAB-KEMI-001), URL-safe as-is.
      GoRoute(
        path: '/fabrics',
        builder: (context, state) => const FabricInventoryScreen(),
      ),
      GoRoute(
        path: '/fabrics/:serial',
        builder: (context, state) =>
            FabricDetailScreen(serial: state.pathParameters['serial']!),
      ),

      // Settings: the production-process dictionary (Task system).
      GoRoute(
        path: '/settings/processes',
        builder: (context, state) => const ProcessesScreen(),
      ),

      // Settings: Employees
      GoRoute(
        path: '/settings/employees',
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: '/settings/employees/new',
        builder: (context, state) => const EmployeeFormScreen(),
      ),
      GoRoute(
        path: '/settings/employees/:id',
        builder: (context, state) =>
            EmployeeDetailScreen(employeeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings/employees/:id/edit',
        builder: (context, state) =>
            EmployeeFormScreen(employeeId: state.pathParameters['id']),
      ),

      // Settings: the measurement dictionary (fields) and the templates built
      // from it. `/new` must be declared before `/:id`, or go_router matches
      // "new" as an id and the create screen tries to fetch a field called
      // "new".
      GoRoute(
        path: '/settings/measurements/fields',
        builder: (context, state) => const MeasurementFieldsScreen(),
      ),
      GoRoute(
        path: '/settings/measurements/fields/new',
        builder: (context, state) => const MeasurementFieldFormScreen(),
      ),
      GoRoute(
        path: '/settings/measurements/fields/:id',
        builder: (context, state) =>
            MeasurementFieldFormScreen(fieldId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/settings/measurements/templates',
        builder: (context, state) => const MeasurementTemplatesScreen(),
      ),
      GoRoute(
        path: '/settings/measurements/templates/new',
        builder: (context, state) => const MeasurementTemplateFormScreen(),
      ),
      GoRoute(
        path: '/settings/measurements/templates/:id',
        builder: (context, state) => MeasurementTemplateFormScreen(
          templateId: state.pathParameters['id'],
        ),
      ),
    ],
  );
});
