import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/section_label.dart';
import '../models/order.dart';
import 'order_form_fields.dart';

/// What the discount sheet collected. `discountIncludesAddons` is null when the
/// order has no addons — there's nothing for the choice to apply to, so the
/// sheet doesn't ask and the field isn't sent.
class DiscountEdit {
  const DiscountEdit({
    required this.discountType,
    required this.discountValue,
    required this.discountIncludesAddons,
  });

  final String discountType;
  final double discountValue;
  final bool? discountIncludesAddons;
}

/// Add or edit an order's discount, surfaced from the payment ticket where the
/// money it changes is already shown. Slides up from the bottom and reuses the
/// create form's segmented None · ₦ · % control. When the order carries extra
/// charges it also asks whether the discount applies to them, since that flag
/// silently changes the total.
///
/// Returns a [DiscountEdit] via `Navigator.pop`, or null if dismissed — the
/// caller commits it through `updateDetails` and owns the busy state.
class DiscountEditSheet extends StatefulWidget {
  const DiscountEditSheet({super.key, required this.order});

  final Order order;

  @override
  State<DiscountEditSheet> createState() => _DiscountEditSheetState();
}

class _DiscountEditSheetState extends State<DiscountEditSheet> {
  late String _type;
  late final TextEditingController _valueController;
  late bool _includesAddons;

  bool get _isEdit => widget.order.hasDiscount;

  @override
  void initState() {
    super.initState();
    _type = widget.order.discountType;
    _valueController = TextEditingController(
      text: widget.order.discountValue > 0
          ? trimTrailingZeros(widget.order.discountValue)
          : '',
    );
    _includesAddons = widget.order.discountIncludesAddons;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    final value = _type == 'none'
        ? 0.0
        : (double.tryParse(_valueController.text.trim()) ?? 0.0);
    if (_type != 'none' && value <= 0) {
      showErrorMessage(context, 'Enter a discount value, or pick "None"');
      return;
    }
    if (_type == 'percentage' && value > 100) {
      showErrorMessage(context, "A percentage can't be more than 100");
      return;
    }
    Navigator.pop(
      context,
      DiscountEdit(
        discountType: _type,
        discountValue: value,
        discountIncludesAddons: widget.order.hasAddons ? _includesAddons : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final order = widget.order;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  _isEdit ? 'Edit discount' : 'Add discount',
                  style: TextStyle(
                    fontFamily: tokens.fontDisplay,
                    fontFamilyFallback: tokens.fontDisplayFallback,
                    fontSize: 22,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionLabel('Discount'),
            const SizedBox(height: 10),
            DiscountField(
              type: _type,
              valueController: _valueController,
              onTypeChanged: (v) => setState(() {
                _type = v;
                if (v == 'none') _valueController.text = '';
              }),
            ),
            // Asked only when there are addons for the answer to apply to. On a
            // plain order the choice is meaningless and the default (include)
            // is sent silently.
            if (_type != 'none' && order.hasAddons) ...[
              const SizedBox(height: 22),
              const SectionLabel('Apply to extra charges?'),
              const SizedBox(height: 4),
              Text(
                'This order has ${formatNaira(order.addonsTotal)} in extras.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: true,
                groupValue: _includesAddons,
                onChanged: (v) => setState(() => _includesAddons = v!),
                title: Text(
                    'Yes — discount the full ${formatNaira(order.subtotal)}'),
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: false,
                groupValue: _includesAddons,
                onChanged: (v) => setState(() => _includesAddons = v!),
                title: Text('No — only the ${formatNaira(order.itemsSubtotal)} '
                    'in garments'),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_isEdit ? 'Save discount' : 'Add discount'),
            ),
          ],
        ),
      ),
    );
  }
}
