import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/guest_repository.dart';
import '../models/guest_profile.dart';

/// Composite family key — a single guest is only addressable via its
/// parent client's id plus its own id
/// (GET /clients/{client_id}/guests/{guest_id} requires both). A named
/// Dart 3 record, same trick as RecipientRef in the measurements
/// feature: structural `==`/`hashCode` for free, so Riverpod's family
/// cache keys correctly without a hand-written class.
typedef GuestDetailArg = ({String clientId, String guestId});

/// Not scoped to the logged-in user here — see ClientDetailNotifier for
/// why: AuthStateNotifier._clearPerTenantCaches() already invalidates
/// this whole family (every cached clientId+guestId pair) on
/// login/logout/register.
class GuestDetailNotifier
    extends FamilyAsyncNotifier<GuestProfile, GuestDetailArg> {
  @override
  Future<GuestProfile> build(GuestDetailArg key) {
    return ref.read(guestRepositoryProvider).getById(key.clientId, key.guestId);
  }

  /// Call after editing or after uploading a photo — the latter is how
  /// the (unconfirmed) assumption that photo upload persists server-side
  /// gets tested in practice, same pattern as ClientDetailNotifier.
  Future<void> refresh() async {
    state = const AsyncLoading<GuestProfile>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(guestRepositoryProvider).getById(arg.clientId, arg.guestId),
    );
  }
}

final guestDetailProvider =
    AsyncNotifierProvider.family<GuestDetailNotifier, GuestProfile, GuestDetailArg>(
  GuestDetailNotifier.new,
);
