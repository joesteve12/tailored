import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recipient_ref.dart';
import '../data/order_repository.dart';
import '../models/fabric.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import 'status_events_providers.dart';

/// FamilyAsyncNotifier<Order, String> — same shape and same
/// not-scoped-to-user-on-purpose reasoning as ClientDetailNotifier.
/// AuthStateNotifier._clearPerTenantCaches() invalidates this (and
/// orderListProvider) on every login/logout/registration.
///
/// Mutation methods here deliberately do NOT flip the provider into
/// `AsyncLoading` the way `refresh()` does. A granular edit (toggling an
/// item's status, attaching one photo) shouldn't blank the whole detail
/// screen with a spinner — instead these update `state` to the new Order on
/// success and rethrow on failure, leaving the existing data on screen so
/// the calling widget can surface a SnackBar and stay put. The screen owns
/// its own per-action "busy" indicator. `refresh()` keeps the loading
/// behaviour, for pull-to-refresh and error-retry where a spinner is right.
class OrderDetailNotifier extends FamilyAsyncNotifier<Order, String> {
  @override
  Future<Order> build(String orderId) {
    return ref.read(orderRepositoryProvider).getById(orderId);
  }

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  /// Runs an op that returns the full updated Order (item add/edit/delete,
  /// detail edit, status change) and adopts it as the new state. Throws on
  /// failure without disturbing the currently-shown order.
  Future<void> _apply(Future<Order> Function() op) async {
    final order = await op();
    state = AsyncData(order);
  }

  /// Runs a side-effecting op whose endpoint doesn't return the order
  /// (media, fabric image, style references), then refetches the order so
  /// state reflects the change. Throws on failure before the refetch.
  Future<void> _mutateThenRefetch(Future<void> Function() op) async {
    await op();
    state = AsyncData(await _repo.getById(arg));
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Order>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _repo.getById(arg));
  }

  // ── Order-level ──────────────────────────────────────────────────────────
  Future<void> updateDetails({
    DateTime? dueDate,
    String? notes,
    String? priority,
    String? discountType,
    double? discountValue,
    bool? discountIncludesAddons,
  }) =>
      _apply(() => _repo.updateDetails(
            arg,
            dueDate: dueDate,
            notes: notes,
            priority: priority,
            discountType: discountType,
            discountValue: discountValue,
            discountIncludesAddons: discountIncludesAddons,
          ));

  /// Caller must pass a status the backend's transition rules accept (see
  /// `allowedOrderTransitions`).
  ///
  /// Note the backend permits moving to 'ready' even when items are still
  /// unfinished — the warning about that is a UI concern, raised by the
  /// detail screen before it calls here (a tailor may legitimately hand an
  /// order over early).
  ///
  /// A successful change appends an 'order' row to the status-event log, so
  /// the Activity → Status tab is invalidated to pick it up. `_apply`
  /// rethrows on failure, short-circuiting before the invalidate — a failed
  /// call never triggers a pointless refetch.
  Future<void> updateStatus(String status) async {
    await _apply(() => _repo.updateStatus(arg, status));
    ref.invalidate(statusEventsProvider(arg));
  }

  // ── Items ────────────────────────────────────────────────────────────────
  /// Adds an item to the order.
  ///
  /// This can move the *order's* status as a side effect: dropping a new,
  /// unfinished garment onto an order that was already 'ready' puts it back
  /// into production ('ready' → 'in_progress'), and the backend logs that as
  /// a status event. The Order returned by the POST already carries the new
  /// status, so all that's left is to refresh the Activity → Status feed.
  Future<void> addItem(OrderItemInput item) async {
    await _apply(() => _repo.addItem(arg, item));
    ref.invalidate(statusEventsProvider(arg));
  }

  Future<void> updateItem(
    String itemId, {
    String? garmentType,
    String? description,
    int? quantity,
    double? unitPrice,
    String? notes,
    RecipientRef? recipient,
    List<String>? measurementSetIds,
  }) async {
    await _apply(() => _repo.updateItem(
          arg,
          itemId,
          garmentType: garmentType,
          description: description,
          quantity: quantity,
          unitPrice: unitPrice,
          notes: notes,
          recipient: recipient,
          measurementSetIds: measurementSetIds,
        ));
    // NOTE: item edits are purely descriptive now — production status is
    // derived from the item's Task and cannot move through this method, so
    // no status event can result and there is no log to refresh. The old
    // "status changed → invalidate statusEventsProvider" tail is gone with
    // the stored status column; the task notifier owns that invalidation
    // for the flows that actually produce events.
  }

  Future<void> deleteItem(String itemId) =>
      _apply(() => _repo.deleteItem(arg, itemId));

  // ── Order addons ─────────────────────────────────────────────────────────
  /// Chargeable extras. All three endpoints return the full updated Order, so
  /// `_apply` adopts it directly — one round trip repaints both the addons
  /// list and the money card.
  ///
  /// Deliberately **no** `statusEventsProvider` invalidation, unlike
  /// [addItem]. Adding a garment can push a `ready` order back into
  /// production and the backend logs that; adding a delivery fee cannot move
  /// the status, so there is never an event to refetch. Invalidating anyway
  /// would be a harmless-looking line that quietly teaches the next reader
  /// that addons behave like items.
  Future<void> addAddon({
    required String label,
    required double amount,
    int quantity = 1,
    String? notes,
  }) =>
      _apply(() => _repo.addAddon(
            arg,
            label: label,
            amount: amount,
            quantity: quantity,
            notes: notes,
          ));

  Future<void> updateAddon(
    String addonId, {
    String? label,
    double? amount,
    int? quantity,
    String? notes,
  }) =>
      _apply(() => _repo.updateAddon(
            arg,
            addonId,
            label: label,
            amount: amount,
            quantity: quantity,
            notes: notes,
          ));

  /// Removing an addon from an already-paid order drops the total below what
  /// was paid, and the Order that comes back carries `paymentStatus:
  /// 'overpaid'`. That's the intended outcome — the money card then shows
  /// "Refund due" — not an error to swallow.
  Future<void> deleteAddon(String addonId) =>
      _apply(() => _repo.deleteAddon(arg, addonId));

  // ── Order media ──────────────────────────────────────────────────────────
  Future<void> addMedia(File file, {String? notes}) =>
      _mutateThenRefetch(() => _repo.addMedia(arg, file, notes: notes));

  Future<void> deleteMedia(String mediaId) =>
      _mutateThenRefetch(() => _repo.deleteMedia(arg, mediaId));

  // ── Fabrics (per item) ───────────────────────────────────────────────────
  /// Adds a fabric to an item and refetches the order so the embedded `fabrics`
  /// list reflects it. Returns the created [Fabric] (carrying its new serial)
  /// so the caller can show the tag to write on the cloth.
  Future<Fabric> addFabric(String itemId, FabricInput input) async {
    final fabric = await _repo.addFabric(arg, itemId, input);
    state = AsyncData(await _repo.getById(arg));
    return fabric;
  }

  Future<void> updateFabric(
    String itemId,
    String fabricId, {
    String? details,
    double? quantity,
    String? unit,
  }) =>
      _mutateThenRefetch(() => _repo.updateFabric(
            arg,
            itemId,
            fabricId,
            details: details,
            quantity: quantity,
            unit: unit,
          ));

  Future<void> deleteFabric(String itemId, String fabricId) =>
      _mutateThenRefetch(() => _repo.deleteFabric(arg, itemId, fabricId));

  // ── Fabric image (per fabric) ────────────────────────────────────────────
  Future<void> uploadFabricImage(String fabricId, File file) =>
      _mutateThenRefetch(() => _repo.uploadFabricImage(fabricId, file));

  Future<void> deleteFabricImage(String fabricId) =>
      _mutateThenRefetch(() => _repo.deleteFabricImage(fabricId));

  // ── Style references (per item) ──────────────────────────────────────────
  Future<void> addStyleReference(String itemId, File file, {String? notes}) =>
      _mutateThenRefetch(
          () => _repo.addStyleReference(itemId, file, notes: notes));

  Future<void> deleteStyleReference(String itemId, String referenceId) =>
      _mutateThenRefetch(
          () => _repo.deleteStyleReference(itemId, referenceId));
}

final orderDetailProvider =
    AsyncNotifierProvider.family<OrderDetailNotifier, Order, String>(
  OrderDetailNotifier.new,
);
