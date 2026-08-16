import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/pick_image.dart';
import '../data/order_repository.dart';
import '../models/order_item.dart';
import '../state/order_list_notifier.dart';
import '../widgets/order_form_fields.dart';
import '../widgets/order_item_form_sheet.dart';

import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/section_label.dart';
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
  final _discountController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _priority = 'normal';
  // The discount mode the value field is read against. An empty value field
  // means "no discount" — there's no separate 'none' toggle any more.
  String _discountMode = 'fixed';
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
    // Keep the live totals card in step with the discount value as it's typed
    // (type changes and item edits already setState).
    _discountController.addListener(_onDiscountChanged);
  }

  void _onDiscountChanged() {
    if (mounted) setState(() {});
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
    _discountController.removeListener(_onDiscountChanged);
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // ── Local money preview ──────────────────────────────────────────────────
  // The backend recomputes the authoritative subtotal/discount/total on
  // create; these mirror that arithmetic so the owner sees the running figure
  // while building the order, not a blank until save.
  double get _subtotal =>
      _items.fold(0.0, (sum, it) => sum + it.unitPrice * it.quantity);

  double get _discountAmount {
    final value = double.tryParse(_discountController.text.trim()) ?? 0;
    if (value <= 0) return 0; // empty / non-positive field ⇒ no discount
    if (_discountMode == 'percentage') {
      return _subtotal * (value.clamp(0, 100) / 100);
    }
    // Fixed amount can't take the total below zero.
    return value.clamp(0, _subtotal).toDouble();
  }

  double get _total => (_subtotal - _discountAmount).clamp(0, double.infinity);

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

    // Empty (or non-positive) discount field means no discount — there's no
    // separate 'none' toggle any more.
    final discountRaw = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final hasDiscount = discountRaw > 0;
    final discountType = hasDiscount ? _discountMode : 'none';
    final discountValue = hasDiscount ? discountRaw : 0.0;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(orderRepositoryProvider).create(
            clientId: widget.clientId,
            dueDate: _dueDate,
            notes: _notesController.text.trim(),
            priority: _priority,
            discountType: discountType,
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

  void _removeItemAt(int i) {
    final removed = _items[i];
    setState(() => _items.removeAt(i));
    for (final id in removed.stagedFileIds) {
      _repo.deleteStagedFile(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSubmitting || _uploadingMedia;
    return Scaffold(
      appBar: AppBar(title: const Text('New order')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // ── Outfits ──────────────────────────────────────────────
                  SectionLabel(
                    'Outfit items',
                    trailing: _items.isEmpty
                        ? null
                        : _CountBadge(_items.length),
                  ),
                  const SizedBox(height: 10),
                  if (_items.isEmpty)
                    const _EmptyOutfits()
                  else
                    for (var i = 0; i < _items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OutfitCard(
                          item: _items[i],
                          onRemove: () => _removeItemAt(i),
                        ),
                      ),
                  const SizedBox(height: 4),
                  _AddOutfitButton(onTap: _addItem),

                  const SizedBox(height: 26),
                  // ── Due date ─────────────────────────────────────────────
                  const SectionLabel('Due date'),
                  const SizedBox(height: 10),
                  DueDateTile(date: _dueDate, onTap: _pickDueDate),

                  const SizedBox(height: 26),
                  // ── Priority ─────────────────────────────────────────────
                  const SectionLabel('Priority'),
                  const SizedBox(height: 10),
                  PrioritySelector(
                    value: _priority,
                    onChanged: (p) => setState(() => _priority = p),
                  ),

                  const SizedBox(height: 26),
                  // ── Discount ─────────────────────────────────────────────
                  const SectionLabel('Discount'),
                  const SizedBox(height: 10),
                  DiscountField(
                    mode: _discountMode,
                    valueController: _discountController,
                    onModeChanged: (m) => setState(() => _discountMode = m),
                  ),

                  const SizedBox(height: 26),
                  // ── Order media ──────────────────────────────────────────
                  SectionLabel(
                    'Order media',
                    trailing: _MediaCount(
                      count: _media.length,
                      uploading: _uploadingMedia,
                    ),
                  ),
                  const SizedBox(height: 10),
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

                  const SizedBox(height: 26),
                  // ── Notes ────────────────────────────────────────────────
                  const SectionLabel('Notes'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Client preferences, reminders, delivery details…',
                    ),
                  ),

                  const SizedBox(height: 24),
                  // ── Running totals ───────────────────────────────────────
                  _TotalsCard(
                    subtotal: _subtotal,
                    discount: _discountAmount,
                    total: _total,
                  ),
                ],
              ),
            ),
            _BottomBar(
              total: _total,
              hasItems: _items.isNotEmpty,
              busy: busy,
              submitting: _isSubmitting,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// The pinned create bar: the live total on the left, the primary action on
/// the right. Sits above the safe-area inset so it clears the home indicator.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.total,
    required this.hasItems,
    required this.busy,
    required this.submitting,
    required this.onSubmit,
  });

  final double total;
  final bool hasItems;
  final bool busy;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                formatNaira(total),
                style: TextStyle(
                  fontFamily: tokens.fontDisplay,
                  fontFamilyFallback: tokens.fontDisplayFallback,
                  fontSize: 22,
                  height: 1,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: (busy || !hasItems) ? null : onSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: submitting
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
    );
  }
}

/// Placeholder shown until the first outfit is added — the order can't be
/// created without one, so it reads as the obvious next step rather than an
/// error the owner has to discover at submit time.
class _EmptyOutfits extends StatelessWidget {
  const _EmptyOutfits();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(context.appTokens.radiusLg),
      ),
      child: Column(
        children: [
          Icon(Icons.checkroom_outlined,
              color: scheme.onSurfaceVariant, size: 28),
          const SizedBox(height: 8),
          Text(
            'No outfits yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Every order needs at least one outfit.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// One accumulated outfit, as a card: fabric thumbnail (or a garment glyph),
/// the garment name in the display face, its summary line, and the line total.
class _OutfitCard extends StatelessWidget {
  const _OutfitCard({required this.item, required this.onRemove});

  final OrderItemInput item;
  final VoidCallback onRemove;

  String? get _thumbUrl {
    for (final f in item.fabrics) {
      final u = f.imageUrl;
      if (u != null && u.isNotEmpty) return u;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final thumb = _thumbUrl;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusSm),
            child: SizedBox(
              width: 46,
              height: 46,
              child: thumb != null
                  ? Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _GlyphTile(),
                    )
                  : _GlyphTile(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.garmentType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: tokens.fontDisplay,
                    fontFamilyFallback: tokens.fontDisplayFallback,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.summaryLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNaira(item.unitPrice * item.quantity),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close,
                      size: 18, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlyphTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHigh,
      child: Icon(Icons.checkroom_outlined,
          size: 22, color: scheme.onSurfaceVariant),
    );
  }
}

/// The dashed "add" affordance from the design — a placeholder-styled tile
/// rather than a filled button, so it reads as "there's room for more here"
/// instead of the screen's primary action (which is Create, in the bottom bar).
class _AddOutfitButton extends StatelessWidget {
  const _AddOutfitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = context.appTokens.radiusLg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: scheme.primary.withValues(alpha: 0.55),
          radius: radius,
        ),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Add outfit',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Strokes a dashed rounded rectangle the size of its child. Hand-rolled so the
/// design's dashed placeholder borders don't pull in a package for one paint.
class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// The running money card — subtotal, any discount, and the resulting total,
/// echoing the receipt the order will settle to. An estimate: the backend is
/// authoritative on save, but the arithmetic here is the same.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final double subtotal;
  final double discount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', formatNaira(subtotal), muted: true),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _row(context, 'Discount', '−${formatNaira(discount)}',
                muted: true),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: scheme.outline),
          ),
          Row(
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                formatNaira(total),
                style: TextStyle(
                  fontFamily: tokens.fontDisplay,
                  fontFamilyFallback: tokens.fontDisplayFallback,
                  fontSize: 22,
                  height: 1,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool muted = false}) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
        );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}

/// Small filled count badge for a section header ("3").
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// "n/3" count for the media header, with an inline spinner while a pick is
/// still uploading.
class _MediaCount extends StatelessWidget {
  const _MediaCount({required this.count, required this.uploading});

  final int count;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (uploading) ...[
          const SizedBox(
            height: 12,
            width: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '$count/3',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
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
    // Snapshot once per rebuild so tap-index math stays consistent with what's
    // actually rendered when videos are filtered out.
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
                            initialIndex: imageUrls.indexOf(staged[i].url),
                          ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: staged[i].fileType == 'video'
                        ? Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(Icons.play_circle_outline),
                          )
                        : Image.network(
                            staged[i].url,
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
                        color: Theme.of(context).colorScheme.onErrorContainer,
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
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Icon(Icons.add_a_photo_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
