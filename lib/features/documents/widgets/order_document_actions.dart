import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/share_document.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../orders/models/order.dart';
import '../data/document_repository.dart';

/// Invoice / receipt sharing on the order screen. Fetches the server-generated
/// PDF and opens the OS share sheet (reusing [shareDocumentBytes] from the
/// work-order flow), so the owner can send it to the client over WhatsApp.
///
/// Which documents are offered tracks payment state, matching the backend's
/// intent: an **invoice** while there's still an outstanding balance, a
/// **receipt** once anything has been paid. (A partially-paid order shows
/// both.) If neither applies the section renders nothing.
class OrderDocumentActions extends ConsumerStatefulWidget {
  const OrderDocumentActions({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderDocumentActions> createState() =>
      _OrderDocumentActionsState();
}

class _OrderDocumentActionsState extends ConsumerState<OrderDocumentActions> {
  bool _busyInvoice = false;
  bool _busyReceipt = false;

  Order get order => widget.order;

  Future<void> _share({
    required bool invoice,
  }) async {
    final format = await pickDocumentFormat(context);
    if (format == null || !mounted) return;

    setState(() {
      if (invoice) {
        _busyInvoice = true;
      } else {
        _busyReceipt = true;
      }
    });
    try {
      final repo = ref.read(documentRepositoryProvider);
      final bytes = invoice
          ? await repo.fetchInvoice(order.id, format: format.apiValue)
          : await repo.fetchReceipt(order.id, format: format.apiValue);
      final kind = invoice ? 'invoice' : 'receipt';
      final name =
          '${kind}_${safeFileSegment(order.orderNumber)}.${format.extension}';
      await shareDocumentBytes(
        bytes,
        fileName: name,
        mimeType: format.mimeType,
        text: '${invoice ? 'Invoice' : 'Receipt'} · order ${order.orderNumber}',
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          e,
          action: 'Could not prepare ${invoice ? 'invoice' : 'receipt'}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (invoice) {
            _busyInvoice = false;
          } else {
            _busyReceipt = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showInvoice = order.balanceDue > 0.005;
    final showReceipt = order.amountPaid > 0.005;
    if (!showInvoice && !showReceipt) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (showInvoice)
                  OutlinedButton.icon(
                    onPressed:
                        _busyInvoice ? null : () => _share(invoice: true),
                    icon: _busyInvoice
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_long_outlined),
                    label: const Text('Share invoice'),
                  ),
                if (showReceipt)
                  OutlinedButton.icon(
                    onPressed:
                        _busyReceipt ? null : () => _share(invoice: false),
                    icon: _busyReceipt
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_outlined),
                    label: const Text('Share receipt'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
