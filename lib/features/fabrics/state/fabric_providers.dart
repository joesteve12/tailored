import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fabric_repository.dart';
import '../models/fabric_inventory.dart';

/// The current inventory search query, driven by the search field. Empty means
/// "show everything". Kept as a tiny piece of shared state so the list provider
/// can key off it and rebuild when it changes.
final fabricSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// The inventory list for the active search query. A `family` keyed by the
/// query string so distinct searches cache independently; `autoDispose` so the
/// cache clears when the inventory screen closes. The screen watches this via
/// `fabricSearchProvider` and re-reads on change.
final fabricListProvider = FutureProvider.autoDispose
    .family<List<FabricInventoryItem>, String>((ref, search) async {
  return ref.read(fabricRepositoryProvider).list(search: search);
});

/// One fabric by serial — backs the detail screen. `autoDispose` family keyed
/// by serial.
final fabricDetailProvider = FutureProvider.autoDispose
    .family<FabricInventoryDetail, String>((ref, serial) async {
  return ref.read(fabricRepositoryProvider).getBySerial(serial);
});
