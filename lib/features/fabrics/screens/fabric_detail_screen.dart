import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/fabric_labels.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../tasks/utils/task_labels.dart';
import '../models/fabric_inventory.dart';
import '../state/fabric_providers.dart';

/// One fabric, looked up by its serial (the number written on the physical
/// tag). Shows the fabric itself plus the order and customer it belongs to,
/// with a button through to the order. Reached by tapping a row in the
/// inventory, or directly via `/fabrics/{serial}` (e.g. after a scan).
class FabricDetailScreen extends ConsumerWidget {
  const FabricDetailScreen({super.key, required this.serial});

  final String serial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(fabricDetailProvider(serial));

    return Scaffold(
      appBar: AppBar(title: Text(serial)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () async => ref.refresh(fabricDetailProvider(serial).future),
        ),
        data: (fabric) => _FabricDetailBody(fabric: fabric),
      ),
    );
  }
}

class _FabricDetailBody extends StatelessWidget {
  const _FabricDetailBody({required this.fabric});

  final FabricInventoryDetail fabric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = formatFabricQuantity(fabric.quantity, fabric.unit);
    final hasImage = fabric.imageUrl != null && fabric.imageUrl!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasImage)
          GestureDetector(
            onTap: () =>
                showImageViewer(context, urls: [fabric.imageUrl!]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  fabric.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: const Center(child: Icon(Icons.texture_outlined, size: 48)),
          ),
        const SizedBox(height: 16),

        // The serial is the physical tag — show it prominently.
        Text('Serial', style: theme.textTheme.labelMedium),
        Text(
          fabric.serial,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        if (fabric.details != null && fabric.details!.isNotEmpty)
          _DetailRow(label: 'Fabric', value: fabric.details!),
        if (qty != null) _DetailRow(label: 'Quantity', value: qty),

        const Divider(height: 32),

        _DetailRow(label: 'Garment', value: fabric.garmentType),
        _DetailRow(
          label: 'Outfit status',
          value: productionStateShortLabel(fabric.productionState),
        ),
        if (fabric.recipientName != null && fabric.recipientName!.isNotEmpty)
          _DetailRow(
            label: fabric.recipientType == 'guest' ? 'For (guest)' : 'For',
            value: fabric.recipientName!,
          ),
        if (fabric.recipientPhone != null && fabric.recipientPhone!.isNotEmpty)
          _DetailRow(label: 'Phone', value: fabric.recipientPhone!),

        const Divider(height: 32),

        _DetailRow(label: 'Order', value: fabric.orderNumber),
        if (fabric.orderStatus != null)
          _DetailRow(
            label: 'Order status',
            value: orderStatusLabel(fabric.orderStatus!),
          ),
        if (fabric.dueDate != null)
          _DetailRow(label: 'Due', value: _formatDate(fabric.dueDate!)),

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push('/orders/${fabric.orderId}'),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Open order'),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
