import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/client_repository.dart';
import '../models/client.dart';

/// FamilyAsyncNotifier<Client, String> — the `arg` (client id) is
/// available via the inherited `arg` getter both inside and outside
/// build(), which refresh() relies on below.
///
/// Not scoped to the logged-in user on purpose: AuthStateNotifier's
/// _clearPerTenantCaches() invalidates this entire family (every cached
/// clientId, not just the currently-viewed one) on every login, logout,
/// and registration, which is the actual fix for cross-tenant cache
/// leakage.
class ClientDetailNotifier extends FamilyAsyncNotifier<Client, String> {
  @override
  Future<Client> build(String clientId) {
    return ref.read(clientRepositoryProvider).getById(clientId);
  }

  /// Refetches from the server. Call this after editing or after
  /// uploading a photo — the latter is how the (unconfirmed) assumption
  /// that photo upload persists server-side gets tested in practice: if
  /// photoUrl is still null after this refresh, the assumption was wrong.
  Future<void> refresh() async {
    state = const AsyncLoading<Client>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(clientRepositoryProvider).getById(arg),
    );
  }
}

final clientDetailProvider =
    AsyncNotifierProvider.family<ClientDetailNotifier, Client, String>(
  ClientDetailNotifier.new,
);
