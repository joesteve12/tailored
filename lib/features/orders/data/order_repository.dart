import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/models/recipient_ref.dart';
import '../models/fabric.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_media.dart';
import '../models/status_event.dart';

/// The result of a staging upload — an ImageKit URL + file_id pair, plus
/// the detected file_type. Used by the create flow to attach a fabric image
/// or style reference to an item that doesn't exist yet (see
/// OrderItemInput). A Dart record gives free value-equality and zero
/// boilerplate for a transport-only shape.
typedef StagedUpload = ({String url, String fileId, String fileType});

/// Formats a DateTime as "YYYY-MM-DD" for any `due_date` sent in a body.
/// The backend types due_date as a Pydantic `date`; a full ISO datetime
/// string (`DateTime.toIso8601String()`) is rejected by
/// `date.fromisoformat()`.
String _dateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  // ── List / read ────────────────────────────────────────────────────────
  Future<OrderListResponse> list({
    String? orderStatus,
    String? paymentStatus,
    String? clientId,
    String? priority,
    DateTime? dueBefore,
    DateTime? dueAfter,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/orders', queryParameters: {
      if (orderStatus != null) 'order_status': orderStatus,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (clientId != null) 'client_id': clientId,
      if (priority != null) 'priority': priority,
      if (dueBefore != null) 'due_before': _dateOnly(dueBefore),
      if (dueAfter != null) 'due_after': _dateOnly(dueAfter),
      if (sortBy != null) 'sort_by': sortBy,
      'page': page,
      'page_size': pageSize,
    });
    return OrderListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /orders/search?q=… — free-text search over order number / client
  /// name, narrowable by the same status/priority/sort knobs the list uses
  /// (a subset: no client_id or due-date range here). Returns the same
  /// {total, page, page_size, results} envelope as [list], so the caller
  /// paginates it identically.
  Future<OrderListResponse> search({
    required String query,
    String? orderStatus,
    String? paymentStatus,
    String? priority,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/orders/search', queryParameters: {
      'q': query,
      if (orderStatus != null) 'order_status': orderStatus,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (priority != null) 'priority': priority,
      if (sortBy != null) 'sort_by': sortBy,
      'page': page,
      'page_size': pageSize,
    });
    return OrderListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> getById(String id) async {
    final response = await _dio.get('/orders/$id');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /orders/{id}/status-events — the append-only log of order- and
  /// item-status transitions, newest first. Backs the Activity → Status tab.
  ///
  /// Returns just the rows; the envelope's `total` is the list length and
  /// isn't useful to the client (the endpoint isn't paginated).
  Future<List<OrderStatusEvent>> listStatusEvents(String orderId) async {
    final response = await _dio.get('/orders/$orderId/status-events');
    final data = response.data as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Create ───────────────────────────────────────────────────────────────
  /// Creates an order with its items, optional order-level media, and the
  /// new priority/discount fields. `items` must be non-empty (OrderCreate
  /// requires at least one). Any fabric images or style references on the
  /// items, and any [media], must already be staged-uploaded (their URLs
  /// passed in) — the order doesn't exist yet, so the attach-by-id upload
  /// endpoints aren't usable at create time.
  Future<Order> create({
    required String clientId,
    required DateTime dueDate,
    String? notes,
    String priority = 'normal',
    String discountType = 'none',
    double discountValue = 0,
    required List<OrderItemInput> items,
    List<StagedUpload> media = const [],
  }) async {
    final response = await _dio.post('/orders', data: {
      'client_id': clientId,
      'due_date': _dateOnly(dueDate),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'priority': priority,
      'discount_type': discountType,
      // Always send a number; the backend rejects a non-zero value when
      // discount_type is 'none', so callers must keep these consistent.
      'discount_value': discountValue,
      'items': items.map((item) => item.toJson()).toList(),
      if (media.isNotEmpty)
        'media': media
            .map((m) => {
                  'file_url': m.url,
                  'file_id': m.fileId,
                  'file_type': m.fileType,
                })
            .toList(),
    });
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Order-level edits ────────────────────────────────────────────────────
  /// PUT /orders/{id} — due date, notes, priority, discount. Only the keys
  /// passed are sent (OrderUpdate treats every field as optional and merges
  /// what's present). When changing the discount, send BOTH type and value
  /// kept consistent: a non-zero value with type 'none' is rejected
  /// server-side. The returned Order carries the recomputed
  /// subtotal/discount/total.
  Future<Order> updateDetails(
    String id, {
    DateTime? dueDate,
    String? notes,
    String? priority,
    String? discountType,
    double? discountValue,
    bool? discountIncludesAddons,
  }) async {
    final data = <String, dynamic>{
      if (dueDate != null) 'due_date': _dateOnly(dueDate),
      if (notes != null) 'notes': notes,
      if (priority != null) 'priority': priority,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      // Flipping this alone changes the total, with no discount field
      // touched: it moves the discount base between items+addons and items
      // alone. The backend treats it as a discount change for recalculation
      // purposes precisely so this can be sent on its own.
      if (discountIncludesAddons != null)
        'discount_includes_addons': discountIncludesAddons,
    };
    final response = await _dio.put('/orders/$id', data: data);
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /orders/{id}/status — order-level status. The caller must pass a
  /// value the backend's transition rules accept (see
  /// `allowedOrderTransitions`); an illegal jump 400s.
  Future<Order> updateStatus(String id, String status) async {
    final response = await _dio.patch('/orders/$id/status', data: {
      'status': status,
    });
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /orders/{id} — only pending/cancelled orders are deletable
  /// server-side; anything else 400s (surfaced to the user as an error).
  Future<void> delete(String id) async {
    await _dio.delete('/orders/$id');
  }

  // ── Order items (editable after creation) ────────────────────────────────
  /// POST /orders/{id}/items — returns the full updated Order (totals
  /// recomputed), so the caller can replace its order state directly.
  Future<Order> addItem(String orderId, OrderItemInput item) async {
    final response =
        await _dio.post('/orders/$orderId/items', data: item.toJson());
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /orders/{id}/items/{itemId} — partial edit; returns the full
  /// updated Order. Only the fields provided are sent.
  ///
  /// Recipient and measurement-snapshot changes are special:
  /// - To change recipient, pass [recipient]; both id fields are written
  ///   (the active one set, the other explicitly null) so the backend's
  ///   "exactly one recipient id" constraint stays satisfied — sending only
  ///   the new id would leave the old one in place and fail validation.
  /// - To change the snapshots, pass [measurementSetIds] — the list replaces
  ///   the item's snapshots wholesale. Pass an empty list to clear them all;
  ///   pass null (the default) to leave them untouched.
  ///
  /// Fabric images and style references are NOT edited here — they have
  /// dedicated upload/delete endpoints (see below).
  Future<Order> updateItem(
    String orderId,
    String itemId, {
    String? garmentType,
    String? description,
    int? quantity,
    double? unitPrice,
    String? notes,
    RecipientRef? recipient,
    List<String>? measurementSetIds,
  }) async {
    final data = <String, dynamic>{
      if (garmentType != null) 'garment_type': garmentType,
      if (description != null) 'description': description,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (notes != null) 'notes': notes,
      if (recipient != null) ...{
        'recipient_type': recipient.isClient ? 'client' : 'guest',
        'recipient_client_id': recipient.isClient ? recipient.id : null,
        'guest_recipient_id': recipient.isGuest ? recipient.id : null,
      },
      // A non-null list (including empty) is sent as-is → replace/clear.
      if (measurementSetIds != null)
        'measurement_set_ids': measurementSetIds,
    };
    final response =
        await _dio.put('/orders/$orderId/items/$itemId', data: data);
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /orders/{id}/items/{itemId} — the backend returns the full
  /// updated Order (NOT 204), because removing an item recomputes totals
  /// and there must always be at least one item left (it 400s on the last
  /// one). Returns that Order so the caller can replace its state.
  Future<Order> deleteItem(String orderId, String itemId) async {
    final response = await _dio.delete('/orders/$orderId/items/$itemId');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Order-level media (max 3) ────────────────────────────────────────────
  /// POST /orders/{id}/media (multipart). Returns just the created
  /// OrderMedia, not the whole order — callers refetch the order to refresh
  /// the media list. `notes` rides as a query parameter, matching the
  /// endpoint signature.
  Future<OrderMedia> addMedia(
    String orderId,
    File file, {
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      '/orders/$orderId/media',
      data: formData,
      queryParameters: {
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return OrderMedia.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /orders/{id}/media/{mediaId} — 204.
  Future<void> deleteMedia(String orderId, String mediaId) async {
    await _dio.delete('/orders/$orderId/media/$mediaId');
  }

  // ── Order addons: chargeable extras, not production work ─────────────────
  /// All three return the **full updated Order** (totals recomputed
  /// server-side), matching the item-CRUD convention — an addon moves
  /// `subtotal`, `discountAmount` and `totalAmount`, so returning the addon
  /// alone would force a second fetch just to redraw the money card.
  ///
  /// None of these advance the order's status. Adding a garment puts an order
  /// back into production because a garment is work; adding a delivery fee is
  /// not, and quietly demoting a `ready` order because someone charged for
  /// postage would be a bug the shop has to undo by hand.
  ///
  /// All three 400 on a delivered or cancelled order (the backend's locked
  /// statuses), so callers should gate on `order.isLocked` client-side rather
  /// than only learning it from a rejected request.

  /// POST /orders/{id}/addons — `amount` must be > 0.
  Future<Order> addAddon(
    String orderId, {
    required String label,
    required double amount,
    int quantity = 1,
    String? notes,
  }) async {
    final response = await _dio.post('/orders/$orderId/addons', data: {
      'label': label,
      'amount': amount,
      'quantity': quantity,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /orders/{id}/addons/{addonId} — partial: only non-null fields are
  /// sent, and anything omitted is left as it was.
  Future<Order> updateAddon(
    String orderId,
    String addonId, {
    String? label,
    double? amount,
    int? quantity,
    String? notes,
  }) async {
    final response = await _dio.patch(
      '/orders/$orderId/addons/$addonId',
      data: <String, dynamic>{
        if (label != null) 'label': label,
        if (amount != null) 'amount': amount,
        if (quantity != null) 'quantity': quantity,
        if (notes != null) 'notes': notes,
      },
    );
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /orders/{id}/addons/{addonId}.
  ///
  /// Unlike items there's no "must keep at least one" floor — an order with
  /// no addons is the normal case. If the order was already paid in full,
  /// removing an addon drops the total below what was paid and the order
  /// comes back as `overpaid`. That's the intended outcome, not an error.
  Future<Order> deleteAddon(String orderId, String addonId) async {
    final response = await _dio.delete('/orders/$orderId/addons/$addonId');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Fabrics on an item (a garment can be cut from several) ───────────────
  /// POST /orders/{orderId}/items/{itemId}/fabrics — creates a fabric and
  /// returns it **with its server-generated serial**, so the caller can show
  /// the tag to write on the cloth immediately. The order's totals are
  /// unaffected by fabrics, so callers refetch the order only to refresh the
  /// embedded `fabrics` list.
  Future<Fabric> addFabric(
    String orderId,
    String itemId,
    FabricInput input,
  ) async {
    final response = await _dio.post(
      '/orders/$orderId/items/$itemId/fabrics',
      data: input.toJson(),
    );
    return Fabric.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT a fabric's details / quantity / unit (the serial is immutable; the
  /// image has its own endpoint). Only the keys passed are sent.
  Future<Fabric> updateFabric(
    String orderId,
    String itemId,
    String fabricId, {
    String? details,
    double? quantity,
    String? unit,
  }) async {
    final data = <String, dynamic>{
      if (details != null) 'details': details,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
    };
    final response = await _dio.put(
      '/orders/$orderId/items/$itemId/fabrics/$fabricId',
      data: data,
    );
    return Fabric.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE a fabric (also removes its ImageKit image server-side) — 204.
  Future<void> deleteFabric(
    String orderId,
    String itemId,
    String fabricId,
  ) async {
    await _dio.delete('/orders/$orderId/items/$itemId/fabrics/$fabricId');
  }

  // ── Fabric image (per fabric) ────────────────────────────────────────────
  /// POST /uploads/fabrics/{fabricId}/image (multipart). The backend persists
  /// the new URL onto the fabric and removes any replaced image from ImageKit,
  /// so the caller only refetches the order. Returns the new image URL. For a
  /// fabric on a not-yet-created item, stage the image instead (see
  /// [uploadStagingImage]) and pass it through FabricInput.
  Future<String> uploadFabricImage(String fabricId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      '/uploads/fabrics/$fabricId/image',
      data: formData,
    );
    return (response.data as Map<String, dynamic>)['url'] as String;
  }

  /// DELETE /uploads/fabrics/{fabricId}/image — 204.
  Future<void> deleteFabricImage(String fabricId) async {
    await _dio.delete('/uploads/fabrics/$fabricId/image');
  }

  // ── Style references (per existing item) ─────────────────────────────────
  /// POST /uploads/order-items/{itemId}/style-reference (multipart).
  /// Uploads and attaches in one call. Returns nothing useful to the caller
  /// here (the new reference id is in the response, but callers refetch the
  /// order to pick up the full style_references list). `notes` is a query
  /// parameter, matching the endpoint.
  Future<void> addStyleReference(
    String itemId,
    File file, {
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    await _dio.post(
      '/uploads/order-items/$itemId/style-reference',
      data: formData,
      queryParameters: {
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  /// DELETE /uploads/order-items/{itemId}/style-reference/{referenceId} —
  /// 204.
  Future<void> deleteStyleReference(String itemId, String referenceId) async {
    await _dio
        .delete('/uploads/order-items/$itemId/style-reference/$referenceId');
  }

  // ── Staging uploads (for the create flow) ────────────────────────────────
  /// POST /uploads/staging/image — uploads an image and returns its URL +
  /// file_id without attaching it to anything. Used to put a fabric image on
  /// an item that's about to be created. `folder` is one of
  /// fabrics/styles/orders (defaults to fabrics; anything else is coerced
  /// server-side).
  Future<StagedUpload> uploadStagingImage(
    File file, {
    String folder = 'fabrics',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      '/uploads/staging/image',
      data: formData,
      queryParameters: {'folder': folder},
    );
    final data = response.data as Map<String, dynamic>;
    return (
      url: data['url'] as String,
      fileId: data['file_id'] as String,
      fileType: data['file_type'] as String,
    );
  }

  /// POST /uploads/staging/media — like [uploadStagingImage] but also
  /// accepts video. Used for staged order media / style references on a
  /// not-yet-created order or item. `folder` is styles/orders.
  Future<StagedUpload> uploadStagingMedia(
    File file, {
    String folder = 'orders',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      '/uploads/staging/media',
      data: formData,
      queryParameters: {'folder': folder},
    );
    final data = response.data as Map<String, dynamic>;
    return (
      url: data['url'] as String,
      fileId: data['file_id'] as String,
      fileType: data['file_type'] as String,
    );
  }

  // ── Per-item work order (job ticket) ─────────────────────────────────────
  /// Fetches the generated work-order document for one item as raw bytes,
  /// for handing to the OS share sheet. `format` is 'pdf' (default) or
  /// 'image' (PNG). The endpoint streams the file back with an attachment
  /// header; we only need the bytes.
  Future<Uint8List> fetchWorkOrder(
    String orderId,
    String itemId, {
    String format = 'pdf',
  }) async {
    final response = await _dio.get<List<int>>(
      '/orders/$orderId/items/$itemId/work-order',
      queryParameters: {'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  // ── Staging cleanup ──────────────────────────────────────────────────────
  /// Deletes a staged (uploaded-but-never-attached) file from ImageKit by its
  /// file_id, so abandoned create flows don't leave orphans. Best-effort: the
  /// file may already be gone, or the endpoint may not be deployed — cleanup
  /// must never crash the flow that triggered it. Requires the backend's
  /// `DELETE /uploads/staging/{file_id}` route (see the Phase-9 backend note).
  Future<void> deleteStagedFile(String fileId) async {
    if (fileId.isEmpty) return;
    try {
      await _dio.delete('/uploads/staging/$fileId');
    } catch (_) {
      // Swallow — orphan cleanup is opportunistic, not load-bearing.
    }
  }

  // ── Dashboard helpers (unchanged) ────────────────────────────────────────
  Future<List<Order>> dueSoon({int days = 3}) async {
    final response = await _dio.get('/orders/due-soon', queryParameters: {
      'days': days,
    });
    return (response.data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> overdue() async {
    final response = await _dio.get('/orders/overdue');
    return (response.data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioProvider));
});
