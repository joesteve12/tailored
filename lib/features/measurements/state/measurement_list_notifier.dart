import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recipient_ref.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_set.dart';

/// One notifier serves both ClientDetailScreen's and GuestDetailScreen's
/// measurement sections — [RecipientRef] (a value-equatable record) is the
/// family arg, so Riverpod caches a separate list per client/guest.
///
/// Not scoped to the logged-in user here: AuthStateNotifier already invalidates
/// this whole family on login/logout/register (see _clearPerTenantCaches).
///
/// Kept under the name `measurementListProvider` and the same family signature
/// the old flat-measurement version used, so the auth-state cache clear and the
/// embedded section keep referencing it unchanged — only the element type moved
/// from the old Measurement row to MeasurementSet.
class MeasurementListNotifier
    extends FamilyAsyncNotifier<List<MeasurementSet>, RecipientRef> {
  @override
  Future<List<MeasurementSet>> build(RecipientRef recipient) {
    return ref.read(measurementRepositoryProvider).listFor(recipient);
  }

  /// Call after recording or editing a set. Full refetch — lists are small.
  Future<void> refresh() async {
    state = const AsyncLoading<List<MeasurementSet>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(measurementRepositoryProvider).listFor(arg),
    );
  }
}

final measurementListProvider = AsyncNotifierProvider.family<
    MeasurementListNotifier, List<MeasurementSet>, RecipientRef>(
  MeasurementListNotifier.new,
);
