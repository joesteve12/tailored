import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/order_labels.dart';
import '../../../core/utils/pick_image.dart';
import '../data/order_repository.dart';
import '../models/order_item.dart';
import '../state/order_list_notifier.dart';
import '../widgets/order_item_form_sheet.dart';

import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/utils/errors.dart';
/// Create-only. Editing an existing order's details (due date, notes,
/// priority, discount) and its items happens on [OrderDetailScreen] now that
/// the backend supports post-creation item add/edit/delete — so this screen
/// stays focused on standing up a new order in one pass.
///
/// Always launched with a client already chosen (from that client's detail
/// screen), matching how guests and measurements are created in this app.
///
/// Items and any order-level media are accumulated locally and sent in the
/// single `POST /orders` call. Item fabric images / style references were
/// already staged when the item was built in [OrderItemFormSheet]; the order
/// media here is likewise staged on pick (via `/uploads/staging/media`) so
/// the create payload carries URLs the backend can attach, not files.
class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key, required this.clientId});

  final String clientId;

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _priority = 'normal';
  String _discountType = 'none';
  final List<OrderItemInput> _items = [];
  final List<StagedUpload> _media = [];

  bool _isSubmitting = false;
  bool _uploadingMedia = false;
  /// True once the order was created — staged files are then owned by the
  /// order, so discard cleanup must skip them.
  bool _saved = false;

  /// Captured for dispose()-time orphan cleanup (can't use `ref` there).
  late final OrderRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(orderRepositoryProvider);
  }

  @override
  void dispose() {
    // Abandoned create flow: delete every still-staged file (order media plus
    // each pending item's fabric image and style references) so they don't
    // orphan on ImageKit. Skipped once the order was actually saved.
    if (!_saved) {
      for (final m in _media) {
        _repo.deleteStagedFile(m.fileId);
      }
      for (final item in _items) {
        for (final id in item.stagedFileIds) {
          _repo.deleteStagedFile(id);
        }
      }
    }
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      // Backend requires a future due date.
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _addItem() async {
    final item = await showModalBottomSheet<OrderItemInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderItemFormSheet(clientId: widget.clientId),
    );
    if (item != null) setState(() => _items.add(item));
  }

  Future<void> _addMedia() async {
    if (_media.length >= 3) return;
    final file = await pickImageFile(context);
    if (file == null || !mounted) return;
    setState(() => _uploadingMedia = true);
    try {
      final staged = await ref
          .read(orderRepositoryProvider)
          .uploadStagingMedia(file, folder: 'orders');
      if (mounted) setState(() => _media.add(staged));
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Media upload failed');
      }
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      if (mounted) showErrorMessage(context, 'Add at least one outfit');
      return;
    }

    final discountValue = _discountType == 'none'
        ? 0.0
        : (double.tryParse(_discountController.text.trim()) ?? 0.0);
    if (_discountType != 'none' && discountValue <= 0) {
      if (mounted) showErrorMessage(context, 'Enter a discount value, or pick '
          '"No discount"');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(orderRepositoryProvider).create(
            clientId: widget.clientId,
            dueDate: _dueDate,
            notes: _notesController.text.trim(),
            priority: _priority,
            discountType: _discountType,
            discountValue: discountValue,
            items: _items,
            media: _media,
          );
      _saved = true;
      await ref.read(orderListProvider.notifier).refresh();
      if (mounted) {
        showSuccessSnackbar(context, 'Order created');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: 'Create failed');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New order')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date'),
                    subtitle: Text(_fmtDate(_dueDate)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: _pickDueDate,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: [
                      for (final p in kPriorities)
                        DropdownMenuItem(
                            value: p, child: Text(priorityLabel(p))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _priority = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration:
                        const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _DiscountFields(
                    type: _discountType,
                    valueController: _discountController,
                    onTypeChanged: (v) => setState(() {
                      _discountType = v;
                      if (v == 'none') _discountController.text = '0';
                    }),
                  ),
                  const SizedBox(height: 24),
                  _MediaStagingStrip(
                    staged: _media,
                    uploading: _uploadingMedia,
                    onAdd: _addMedia,
                    onRemoveAt: (i) {
                      final removed = _media[i];
                      setState(() => _media.removeAt(i));
                      _repo.deleteStagedFile(removed.fileId);
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Outfits',
                          style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add outfit'),
                      ),
                    ],
                  ),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No outfits added yet'),
                    )
                  else
                    for (var i = 0; i < _items.length; i++)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(_items[i].garmentType),
                          subtitle: Text(_items[i].summaryLine),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              final removed = _items[i];
                              setState(() => _items.removeAt(i));
                              for (final id in removed.stagedFileIds) {
                                _repo.deleteStagedFile(id);
                              }
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed:
                    (_isSubmitting || _uploadingMedia) ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Discount type selector + value field. The value field is shown only when
/// a discount type is chosen, and its label tracks the type (a percentage vs
/// a flat amount) so the meaning of the number is never ambiguous. The
/// backend recomputes the actual `discount_amount`; this only collects the
/// type and the raw value.
class _DiscountFields extends StatelessWidget {
  const _DiscountFields({
    required this.type,
    required this.valueController,
    required this.onTypeChanged,
  });

  final String type;
  final TextEditingController valueController;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: type,
          decoration: const InputDecoration(labelText: 'Discount'),
          items: [
            for (final t in kDiscountTypes)
              DropdownMenuItem(value: t, child: Text(discountTypeLabel(t))),
          ],
          onChanged: (v) {
            if (v != null) onTypeChanged(v);
          },
        ),
        if (type != 'none') ...[
          const SizedBox(height: 12),
          TextField(
            controller: valueController,
            decoration: InputDecoration(
              labelText:
                  type == 'percentage' ? 'Discount (%)' : 'Discount amount',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ],
    );
  }
}

/// Staged order-media strip (≤3). Mirrors the item style-references strip:
/// pick → stage immediately → carry the URL into the create payload.
class _MediaStagingStrip extends StatelessWidget {
  const _MediaStagingStrip({
    required this.staged,
    required this.uploading,
    required this.onAdd,
    required this.onRemoveAt,
  });

  final List<StagedUpload> staged;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    final canAdd = staged.length < 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Order media',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text(
              '${staged.length}/3',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            if (uploading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            // Snapshot once per rebuild so tap-index math stays consistent
            // with what's actually rendered when videos are filtered out.
            final imageUrls = [
              for (final m in staged)
                if (m.fileType != 'video') m.url,
            ];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < staged.length; i++)
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: staged[i].fileType == 'video'
                              ? null
                              : () => showImageViewer(
                                    context,
                                    urls: imageUrls,
                                    initialIndex:
                                        imageUrls.indexOf(staged[i].url),
                                  ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: staged[i].fileType == 'video'
                                ? Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child:
                                        const Icon(Icons.play_circle_outline),
                                  )
                                : Image.network(
                                    staged[i].url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image_outlined),
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
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        onPressed: () => onRemoveAt(i),
                      ),
                    ),
                  ],
                ),
              ),
            if (canAdd)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: uploading ? null : onAdd,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined),
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
