import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'models/user.dart';
import 'token_storage.dart';
import '../../features/clients/state/client_detail_notifier.dart';
import '../../features/clients/state/client_list_notifier.dart';
import '../../features/guests/state/guest_detail_notifier.dart';
import '../../features/guests/state/guest_list_notifier.dart';
import '../../features/measurements/state/measurement_list_notifier.dart';
import '../../features/measurements/state/measurement_dictionary_providers.dart';
import '../../features/measurements/state/dictionary_admin_notifiers.dart';
import '../../features/measurements/state/measurement_set_providers.dart';
import '../../features/orders/state/order_detail_notifier.dart';
import '../../features/orders/state/order_list_notifier.dart';

/// Holds the logged-in user, or null if logged out.
/// AsyncValue.loading while checking secure storage on cold start;
/// AsyncValue.data(null) means "checked — nobody's logged in."
/// go_router's redirect guard (app_router.dart) watches this to decide
/// where to send the user, and the dio interceptor (dio_client.dart)
/// invalidates this provider on a 401 to force a re-check.
class AuthStateNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final storage = ref.watch(tokenStorageProvider);

    final token = await storage.readToken();
    if (token == null) return null;

    final cachedJson = await storage.readCachedUserJson();
    if (cachedJson == null) {
      // Token exists but no cached user — shouldn't normally happen given
      // how _handleAuthResponse writes both together, but if storage ever
      // gets into this state, treat it as logged out rather than guess.
      await storage.clearSession();
      return null;
    }

    return User.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
  }

  Future<User> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .loginWithPassword(email: email, password: password);
    state = AsyncData(user);
    _clearPerTenantCaches();
    return user;
  }

  Future<User> loginWithGoogle({required String idToken}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .loginWithGoogle(idToken: idToken);
    state = AsyncData(user);
    _clearPerTenantCaches();
    return user;
  }

  Future<User> registerWithPassword({
    required String businessName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final user = await ref.read(authRepositoryProvider).registerWithPassword(
          businessName: businessName,
          email: email,
          phone: phone,
          password: password,
        );
    state = AsyncData(user);
    _clearPerTenantCaches();
    return user;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
    _clearPerTenantCaches();
  }

  /// Wipes every cache keyed by a record id local to one tenant (client,
  /// guest, measurement). This used to only invalidate [clientListProvider]
  /// — every `.family` provider (client/guest detail, guest list,
  /// measurement list) was left untouched across a login/logout, even
  /// though none of them are scoped by user id and none are autoDispose.
  /// Concretely: User A opens client #7, logs out; User B (a different
  /// tenant) logs in and opens *their* client #7 — same id, different
  /// business, same DB sequence numbering. Without this, B would get A's
  /// cached name/phone/photo/measurements served straight from memory,
  /// no network call, no 401, nothing to even notice — that's not a UI
  /// flicker, it's tenant A's data rendered on tenant B's screen.
  ///
  /// `ref.invalidate(someFamilyProvider)` (no argument) invalidates every
  /// cached argument combination of that family, not just one id — that's
  /// what makes this safe without tracking every id ever fetched.
  void _clearPerTenantCaches() {
    ref.invalidate(clientListProvider);
    ref.invalidate(clientDetailProvider);
    ref.invalidate(guestListProvider);
    ref.invalidate(guestDetailProvider);
    ref.invalidate(measurementListProvider);
    ref.invalidate(measurementFieldsProvider);
    ref.invalidate(measurementTemplatesProvider);
    ref.invalidate(measurementSetByIdProvider);
    ref.invalidate(fieldAdminListProvider);
    ref.invalidate(templateAdminListProvider);
    ref.invalidate(fieldByIdProvider);
    ref.invalidate(templateByIdProvider);
    ref.invalidate(fieldTemplateUsageProvider);
    ref.invalidate(orderListProvider);
    ref.invalidate(orderDetailProvider);
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthStateNotifier, User?>(AuthStateNotifier.new);
