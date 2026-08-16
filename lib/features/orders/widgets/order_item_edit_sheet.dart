import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/utils/fabric_labels.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/pick_image.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';
import '../models/fabric.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/style_reference.dart';
import '../state/order_detail_notifier.dart';
import 'measurement_snapshot_picker.dart';
import 'recipient_picker.dart';

/// Edit sheet for an item that already exists on a saved order — the
/// counterpart to [OrderItemFormSheet] (which builds a not-yet-created item).
///
///  * Scalar fields (garment, qty, price, recipient, the measurement
///    snapshot, notes) are **batched** and committed together on Save via
///    `OrderItemUpdate`.
///  * Fabrics and style references hit their own endpoints and are applied
///    **immediately** on add/edit/remove — there's no staging step for an item
///    that already has an id. Each refetches the order, so this sheet watches
///    the detail provider and re-derives the live item rather than trusting the
///    snapshot it opened with.
///
/// Owns its own busy flags so one in-flight upload doesn't blank the sheet, and
/// surfaces failures as SnackBars while leaving the sheet open.
class OrderItemEditSheet extends ConsumerStatefulWidget {
  const OrderItemEditSheet({
    super.key,
    required this.orderId,
    required this.item,
    required this.clientId,
  });

  final String orderId;

  /// The item as it was when the sheet opened — used only to seed the
  /// controllers and local editable state once. Live fabric/style data is read
  /// from the watched order, not from this.
  final OrderItem item;

  /// The order's owning client, needed by [RecipientPicker] to list guests.
  final String clientId;

  @override
  ConsumerState<OrderItemEditSheet> createState() => _OrderItemEditSheetState();
}

class _OrderItemEditSheetState extends ConsumerState<OrderItemEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _garmentController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;

  late RecipientRef _recipient;
  late List<String> _measurementSetIds;

  bool _saving = false;
  bool _busyStyle = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _garmentController = TextEditingController(text: item.garmentType);
    _descriptionController =
        TextEditingController(text: item.description ?? '');
    _quantityController = TextEditingController(text: item.quantity.toString());
    _priceController =
        TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    _notesController = TextEditingController(text: item.notes ?? '');
    _recipient = item.recipient;
    _measurementSetIds = List<String>.from(item.measurementSetIds);
  }

  @override
  void dispose() {
    _garmentController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  OrderDetailNotifier get _notifier =>
      ref.read(orderDetailProvider(widget.orderId).notifier);

  void _dismissSheet() {
    if (!mounted || _isClosing) return;
    _isClosing = true;
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Finds this item in the (possibly refetched) order. Null if it was deleted
  /// out from under the sheet.
  OrderItem? _liveItem(Order? order) {
    if (order == null) return null;
    for (final it in order.items) {
      if (it.id == widget.item.id) return it;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final original = widget.item;
    final recipientChanged = _recipient != original.recipient;
    // Order-independent compare — the backend re-sorts snapshots on read, so
    // only a change in *which* sets are linked counts as an edit.
    final snapshotChanged = !setEquals(
      _measurementSetIds.toSet(),
      original.measurementSetIds.toSet(),
    );

    setState(() => _saving = true);
    try {
      await _notifier.updateItem(
        widget.item.id,
        garmentType: _garmentController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        unitPrice: double.parse(_priceController.text.trim()),
        notes: _notesController.text.trim(),
        recipient: recipientChanged ? _recipient : null,
        // Non-null list = replace (empty clears); null = leave untouched. Only
        // send when it actually changed.
        measurementSetIds: snapshotChanged ? _measurementSetIds : null,
      );
      if (mounted) _dismissSheet();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackbar(context, e, action: 'Could not save outfit');
      }
    }
  }

  Future<void> _addStyleRef() async {
    final file = await pickImageFile(context);
    if (file == null || !mounted) return;
    setState(() => _busyStyle = true);
    try {
      await _notifier.addStyleReference(widget.item.id, file);
      if (mounted) showSuccessSnackbar(context, 'Style reference uploaded');
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Style reference upload failed');
      }
    } finally {
      if (mounted) setState(() => _busyStyle = false);
    }
  }

  Future<void> _removeStyleRef(StyleReference ref_) async {
    setState(() => _busyStyle = true);
    try {
      await _notifier.deleteStyleReference(widget.item.id, ref_.id);
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not remove reference');
      }
    } finally {
      if (mounted) setState(() => _busyStyle = false);
    }
  }

  Future<void> _confirmDelete(bool isLastItem, Order? order) async {
    if (isLastItem) {
      showErrorMessage(
        context,
        "An order must keep at least one outfit — add another before "
        "removing this one.",
      );
      return;
    }

    // Warn about credit; never block on it, and never offer to refund here.
    //
    // Before the money rebuild this path could fail outright: the backend
    // refused any change that pushed the total below what had been paid, and
    // told the operator to void a payment first — destroying the record of
    // money that genuinely changed hands so the arithmetic could stay inside
    // a constraint. Removal now always succeeds and the order lands in
    // `overpaid`.
    //
    // The projected total is computed here **for the warning copy only**. The
    // backend recomputes and returns the settled figures; nothing downstream
    // reads these numbers.
    final item = widget.item;
    final projectedTotal =
        order == null ? null : order.totalAmount - item.lineTotal;
    final createsCredit = order != null &&
        projectedTotal != null &&
        order.amountPaid > projectedTotal + 0.005;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(createsCredit
            ? 'Remove ${item.garmentType} '
                '(${formatNaira(item.lineTotal)})?'
            : 'Remove outfit?'),
        content: createsCredit
            ? Text(
                "This order's total drops to "
                '${formatNaira(projectedTotal)}. '
                "You've received ${formatNaira(order.amountPaid)}, so "
                '${formatNaira(order.amountPaid - projectedTotal)} will be '
                'owed back to the client.\n\n'
                'You can refund it later from the payment card.',
              )
            : const Text('This outfit will be deleted from the order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _notifier.deleteItem(widget.item.id);
      if (mounted) {
        showSuccessSnackbar(context, 'Outfit removed');
        _dismissSheet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackbar(context, e, action: 'Could not remove outfit');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId)).valueOrNull;
    final live = _liveItem(order);

    // Deleted from under us (e.g. removed on another screen): close cleanly.
    if (order != null && live == null && !_isClosing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dismissSheet();
      });
      return const SizedBox.shrink();
    }

    final item = live ?? widget.item;
    final isLastItem = (order?.items.length ?? 1) <= 1;
    final anyBusy = _saving || _busyStyle;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Edit outfit',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton(
                    tooltip: 'Remove outfit',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: anyBusy
                        ? null
                        : () => _confirmDelete(isLastItem, order),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _garmentController,
                decoration: const InputDecoration(labelText: 'Outfit type'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return (n == null || n < 1) ? 'Invalid' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration:
                          const InputDecoration(labelText: 'Unit price'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        return (n == null || n <= 0) ? 'Invalid' : null;
                      },
                    ),
                  ),
                ],
              ),
              // NOTE: the production-status dropdown is gone on purpose.
              // Production state is derived from the item's Task and can
              // only move through the task screen — an item edit is purely
              // descriptive now.
              const SizedBox(height: 20),
              _FabricsSection(
                orderId: widget.orderId,
                itemId: widget.item.id,
                fabrics: item.fabrics,
              ),
              const SizedBox(height: 20),
              _StyleRefsRow(
                refs: item.styleReferences,
                busy: _busyStyle,
                onAdd: _addStyleRef,
                onRemove: _removeStyleRef,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              RecipientPicker(
                clientId: widget.clientId,
                selected: _recipient,
                onChanged: (r) => setState(() {
                  _recipient = r;
                  _measurementSetIds = const [];
                }),
              ),
              const SizedBox(height: 4),
              MeasurementSnapshotField(
                recipient: _recipient,
                selectedSetIds: _measurementSetIds,
                onChanged: (ids) => setState(() => _measurementSetIds = ids),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: anyBusy ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manages the live fabrics on an existing item. Each operation hits a fabric
/// endpoint and refetches the order (via the notifier), so this re-renders off
/// the watched item passed down by the sheet. Adding a fabric surfaces its new
/// serial so the owner can tag the cloth.
class _FabricsSection extends ConsumerStatefulWidget {
  const _FabricsSection({
    required this.orderId,
    required this.itemId,
    required this.fabrics,
  });

  final String orderId;
  final String itemId;
  final List<Fabric> fabrics;

  @override
  ConsumerState<_FabricsSection> createState() => _FabricsSectionState();
}

class _FabricsSectionState extends ConsumerState<_FabricsSection> {
  bool _busy = false;

  OrderDetailNotifier get _notifier =>
      ref.read(orderDetailProvider(widget.orderId).notifier);

  Future<void> _run(Future<void> Function() op, String failMessage) async {
    setState(() => _busy = true);
    try {
      await op();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: '$failMessage');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFabric() async {
    final result = await showDialog<_FabricFormResult>(
      context: context,
      builder: (_) => const _FabricEditDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final fabric = await _notifier.addFabric(
        widget.itemId,
        FabricInput(
          details: result.details,
          quantity: result.quantity,
          unit: result.unit,
        ),
      );
      if (mounted) {
        showSuccessSnackbar(
          context,
          'Added — tag this fabric: ${fabric.serial}',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not add fabric');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editFabric(Fabric fabric) async {
    final result = await showDialog<_FabricFormResult>(
      context: context,
      builder: (_) => _FabricEditDialog(existing: fabric),
    );
    if (result == null || !mounted) return;
    await _run(
      () => _notifier.updateFabric(
        widget.itemId,
        fabric.id,
        details: result.details ?? '',
        quantity: result.quantity,
        unit: result.unit,
      ),
      'Could not update fabric',
    );
  }

  Future<void> _deleteFabric(Fabric fabric) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove fabric?'),
        content: Text('${fabric.serial} will be removed from this outfit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => _notifier.deleteFabric(widget.itemId, fabric.id),
      'Could not remove fabric',
    );
  }

  Future<void> _pickImage(Fabric fabric) async {
    final file = await pickImageFile(context);
    if (file == null || !mounted) return;
    await _run(
      () => _notifier.uploadFabricImage(fabric.id, file),
      'Fabric image upload failed',
    );
  }

  Future<void> _removeImage(Fabric fabric) async {
    await _run(
      () => _notifier.deleteFabricImage(fabric.id),
      'Could not remove fabric image',
    );
  }

  @override
  Widget build(BuildContext context) {
    final fabrics = widget.fabrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Fabrics',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            if (_busy)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (fabrics.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No fabric on this outfit yet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final fabric in fabrics)
          _FabricRow(
            fabric: fabric,
            busy: _busy,
            onEdit: () => _editFabric(fabric),
            onDelete: () => _deleteFabric(fabric),
            onPickImage: () => _pickImage(fabric),
            onRemoveImage: () => _removeImage(fabric),
          ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _addFabric,
            icon: const Icon(Icons.add),
            label: const Text('Add fabric'),
          ),
        ),
      ],
    );
  }
}

class _FabricRow extends StatelessWidget {
  const _FabricRow({
    required this.fabric,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Fabric fabric;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = fabric.imageUrl != null && fabric.imageUrl!.isNotEmpty;
    final qty = formatFabricQuantity(fabric.quantity, fabric.unit);
    final subtitle = [
      if (fabric.details != null && fabric.details!.isNotEmpty) fabric.details!,
      if (qty != null) qty,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        leading: hasImage
            ? GestureDetector(
                onTap: () => showImageViewer(
                  context,
                  urls: [fabric.imageUrl!],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fabric.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              )
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: const Icon(Icons.texture_outlined, size: 20),
              ),
        title: Text(fabric.serial,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: PopupMenuButton<String>(
          enabled: !busy,
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'image':
                onPickImage();
              case 'remove_image':
                onRemoveImage();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit details')),
            PopupMenuItem(
              value: 'image',
              child: Text(hasImage ? 'Replace image' : 'Add image'),
            ),
            if (hasImage)
              const PopupMenuItem(
                  value: 'remove_image', child: Text('Remove image')),
            const PopupMenuItem(value: 'delete', child: Text('Delete fabric')),
          ],
        ),
      ),
    );
  }
}

/// Result of the fabric add/edit dialog.
class _FabricFormResult {
  const _FabricFormResult({this.details, this.quantity, required this.unit});
  final String? details;
  final double? quantity;
  final String unit;
}

/// Small dialog to enter/edit a fabric's details, quantity, and unit. The
/// serial is server-generated and never edited here; the image is managed from
/// the row's menu.
class _FabricEditDialog extends StatefulWidget {
  const _FabricEditDialog({this.existing});

  final Fabric? existing;

  @override
  State<_FabricEditDialog> createState() => _FabricEditDialogState();
}

class _FabricEditDialogState extends State<_FabricEditDialog> {
  late final TextEditingController _detailsController;
  late final TextEditingController _quantityController;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _detailsController = TextEditingController(text: f?.details ?? '');
    _quantityController = TextEditingController(
      text: f?.quantity != null ? _trimQty(f!.quantity!) : '',
    );
    _unit =
        (f?.unit != null && kFabricUnits.contains(f!.unit)) ? f.unit! : 'yards';
  }

  static String _trimQty(double q) {
    var n = q.toStringAsFixed(2);
    if (n.contains('.')) {
      n = n.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return n;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      _FabricFormResult(
        details: _detailsController.text.trim(),
        quantity: double.tryParse(_quantityController.text.trim()),
        unit: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add fabric' : 'Edit fabric'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _detailsController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Fabric details',
              hintText: 'e.g. navy wool',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [
                    for (final u in kFabricUnits)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _unit = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.existing == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

/// Style references strip for an existing item — each thumb removable, plus an
/// add tile. Operates on the live [StyleReference] list and the per-item
/// style-reference endpoints.
class _StyleRefsRow extends StatelessWidget {
  const _StyleRefsRow({
    required this.refs,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<StyleReference> refs;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<StyleReference> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Style references'),
            const SizedBox(width: 8),
            if (busy)
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            // Snapshot image URLs (skipping videos, which the viewer can't
            // play) so the tap-index math and the rendered order stay in
            // sync.
            final imageUrls = [
              for (final r in refs)
                if (r.fileType != 'video') r.fileUrl,
            ];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ref_ in refs)
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: ref_.fileType == 'video'
                              ? null
                              : () => showImageViewer(
                                    context,
                                    urls: imageUrls,
                                    initialIndex:
                                        imageUrls.indexOf(ref_.fileUrl),
                                  ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ref_.fileType == 'video'
                                ? Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child:
                                        const Icon(Icons.play_circle_outline),
                                  )
                                : Image.network(
                                    ref_.fileUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: CircleAvatar(
                              radius: 10,
                              backgroundColor:
                                  Theme.of(context).colorScheme.errorContainer,
                              child: Icon(
                                Icons.close,
                                size: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                            onPressed: busy ? null : () => onRemove(ref_),
                          ),
                        ),
                      ],
                    ),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: busy ? null : onAdd,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
