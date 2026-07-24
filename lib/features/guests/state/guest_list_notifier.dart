import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/guest_repository.dart';
import '../models/guest_profile.dart';

/// Not scoped to the logged-in user here — see ClientDetailNotifier for
/// why: AuthStateNotifier._clearPerTenantCaches() already invalidates
/// this whole family (every cached clientId) on login/logout/register.
class GuestListNotifier extends FamilyAsyncNotifier<List<GuestProfile>, String> {
  @override
  Future<List<GuestProfile>> build(String clientId) {
    return ref.read(guestRepositoryProvider).list(clientId);
  }

  /// Call after creating, editing, or deleting a guest under this client.
  Future<void> refresh() async {
    state = const AsyncLoading<List<GuestProfile>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(guestRepositoryProvider).list(arg),
    );
  }
}

final guestListProvider = AsyncNotifierProvider.family<GuestListNotifier,
    List<GuestProfile>, String>(
  GuestListNotifier.new,
);
