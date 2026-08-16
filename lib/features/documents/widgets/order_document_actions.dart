import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/share_document.dart';
import '../../../core/widgets/feedback.dart';
import '../../orders/models/order.dart';
import '../data/document_repository.dart';
import '../state/document_providers.dart';

/// Invoice sharing on the order screen. Fetches the server-generated PDF and
/// opens the OS share sheet (reusing [shareDocumentBytes] from the work-order
/// flow), so the owner can send it over WhatsApp.
///
/// **Invoice only.** The order-level receipt button used to live here and is
/// gone: receipts are per payment now, and they're issued from the row they
/// describe in the Activity section. An order-level receipt couldn't answer
/// the one question a receipt is for — what did this client hand over, when,
/// and what was left — because it drew from live order totals, so taking a
/// second payment silently rewrote the first receipt.
///
/// The invoice is offered while there's still a balance to invoice for. The
/// backend refuses it outright on `paid` **and `overpaid`**; the second case
/// is the one worth spelling out, since invoicing a client who is owed money
/// back is exactly the mistake that state exists to prevent.
class OrderDocumentActions extends ConsumerStatefulWidget {
  const OrderDocumentActions({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderDocumentActions> createState() =>
      _OrderDocumentActionsState();
}

class _OrderDocumentActionsState extends ConsumerState<OrderDocumentActions> {
  bool _busyInvoice = false;

  Order get order => widget.order;

  Future<void> _shareInvoice() async {
    final format = await pickDocumentFormat(context);
    if (format == null || !mounted) return;

    setState(() => _busyInvoice = true);
    try {
      final bytes = await ref
          .read(documentRepositoryProvider)
          .fetchInvoice(order.id, format: format.apiValue);
      await shareDocumentBytes(
        bytes,
        fileName: 'invoice_${safeFileSegment(order.orderNumber)}'
            '.${format.extension}',
        mimeType: format.mimeType,
        text: 'Invoice · order ${order.orderNumber}',
      );
      // The backend logs every generation; refresh so the Activity section's
      // delete warnings see an up-to-date document list.
      ref.invalidate(orderDocumentsProvider(order.id));
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not prepare invoice');
      }
    } finally {
      if (mounted) setState(() => _busyInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mirrors the backend gate rather than approximating it: 'paid' and
    // 'overpaid' both 400, and a button that always fails is worse than no
    // button. `balanceDue` alone would be wrong here — it reads zero on an
    // overpaid order too, but for the opposite reason.
    final blocked = order.paymentStatus == 'paid' ||
        order.paymentStatus == 'overpaid';
    if (blocked) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Receipts are issued per payment — see Activity.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTokens.mutedForeground,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busyInvoice ? null : _shareInvoice,
              icon: _busyInvoice
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              label: const Text('Share invoice'),
            ),
          ],
        ),
      ),
    );
  }
}
