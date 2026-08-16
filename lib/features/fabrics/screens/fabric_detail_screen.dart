import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/fabric_labels.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/skeleton.dart';
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
        loading: () => const _DetailSkeleton(),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () async => ref.refresh(fabricDetailProvider(serial).future),
        ),
        data: (fabric) => RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(fabricDetailProvider(serial).future),
          child: _FabricDetailBody(fabric: fabric),
        ),
      ),
    );
  }
}

/// Loading placeholder shaped like the editorial body below — swatch block,
/// the SERIAL caption + headline, a run of label/value pairs, and the button —
/// so nothing shifts when the real fabric lands. One shimmer sweeps the lot.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    // One label/value pair, matching _SpecPair's rhythm (label above, value
    // below, 18px trailing gap). Widths vary so the pairs don't line up.
    Widget pair(double labelW, double valueW) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: labelW, height: 10),
              const SizedBox(height: 6),
              Skeleton(width: valueW, height: 16),
            ],
          ),
        );

    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          // The swatch — a full-width block, the one place a solid fill is
          // exactly right (it stands in for the photo).
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Skeleton(height: double.infinity, radius: tokens.radiusXl),
          ),
          const SizedBox(height: 22),
          const Skeleton(width: 54, height: 10),
          const SizedBox(height: 5),
          const Skeleton(width: 190, height: 30),
          const SizedBox(height: 28),
          pair(46, 148),
          pair(68, 104),
          pair(74, 128),
          pair(34, 158),
          pair(52, 92),
          const SizedBox(height: 12),
          Skeleton(height: 52, radius: tokens.radiusLg),
        ],
      ),
    );
  }
}

/// Image-forward, editorial layout: the swatch leads full-bleed, the serial is
/// the headline set in the display serif, and the rest reads as airy
/// label/value pairs on the page — no cards, no icon chips.
class _FabricDetailBody extends StatelessWidget {
  const _FabricDetailBody({required this.fabric});

  final FabricInventoryDetail fabric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.appTokens;

    final qty = formatFabricQuantity(fabric.quantity, fabric.unit);
    final hasImage = fabric.imageUrl != null && fabric.imageUrl!.isNotEmpty;
    final hasDetails = fabric.details != null && fabric.details!.isNotEmpty;
    final hasRecipient =
        fabric.recipientName != null && fabric.recipientName!.isNotEmpty;
    final hasPhone =
        fabric.recipientPhone != null && fabric.recipientPhone!.isNotEmpty;

    // "Fabric" line combines the material and the amount — "Ankara · 2 yards".
    final fabricLine = <String>[
      if (hasDetails) fabric.details!,
      if (qty != null) qty,
    ].join(' · ');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      children: [
        // The swatch — full-width hero, tap to zoom.
        if (hasImage)
          GestureDetector(
            onTap: () => showImageViewer(context, urls: [fabric.imageUrl!]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusXl),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  fabric.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
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
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.radiusXl),
              color: scheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Icon(Icons.texture_outlined,
                  size: 48, color: tokens.mutedForeground),
            ),
          ),

        const SizedBox(height: 22),

        // The serial is the physical tag — the page headline in the serif.
        Text(
          'SERIAL',
          style: textTheme.labelSmall?.copyWith(
            color: tokens.mutedForeground,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          fabric.serial,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: tokens.fontDisplay,
            fontFamilyFallback: tokens.fontDisplayFallback,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 28),

        // Airy label/value pairs — the fabric, then the outfit, then the order.
        if (fabricLine.isNotEmpty)
          _SpecPair(label: 'Fabric', value: fabricLine),
        _SpecPair(label: 'Garment', value: fabric.garmentType),
        _SpecPair(
          label: 'Production',
          value: productionStateShortLabel(fabric.productionState),
        ),

        if (hasRecipient)
          _SpecPair(
            label: fabric.recipientType == 'guest' ? 'For (guest)' : 'For',
            value: fabric.recipientName!,
            trailing: hasPhone ? _PhoneActions(phone: fabric.recipientPhone!) : null,
          )
        else if (hasPhone)
          _SpecPair(
            label: 'Phone',
            value: fabric.recipientPhone!,
            trailing: _PhoneActions(phone: fabric.recipientPhone!),
          ),

        _SpecPair(label: 'Order', value: fabric.orderNumber),
        if (fabric.orderStatus != null)
          _SpecPair(
            label: 'Order status',
            value: orderStatusLabel(fabric.orderStatus!),
          ),
        if (fabric.dueDate != null)
          _SpecPair(label: 'Due', value: _formatDate(fabric.dueDate!)),

        const SizedBox(height: 30),

        FilledButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            context.push('/orders/${fabric.orderId}');
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
            ),
          ),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Open order'),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// One airy label/value pair: a small muted caption with the value beneath it,
/// generous vertical rhythm, no card or icon. An optional [trailing] widget
/// (the phone actions) pins to the value's right on the same baseline.
class _SpecPair extends StatelessWidget {
  const _SpecPair({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = context.appTokens.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Call / WhatsApp buttons for the recipient's phone.
class _PhoneActions extends StatelessWidget {
  const _PhoneActions({required this.phone});

  final String phone;

  Future<void> _launch(BuildContext context, Uri uri,
      {required String failure}) async {
    HapticFeedback.selectionClick();
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) showErrorMessage(context, failure);
    } catch (e) {
      if (context.mounted) showErrorSnackbar(context, e, action: failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundAction(
          icon: Icons.call_outlined,
          tooltip: 'Call',
          onTap: () => _launch(context, Uri(scheme: 'tel', path: phone),
              failure: "Couldn't start a call"),
        ),
        const SizedBox(width: 8),
        _RoundAction(
          svgAsset: 'assets/icons/whatsapp.svg',
          color: const Color(0xFF25D366),
          tooltip: 'WhatsApp',
          onTap: () => _launch(context, Uri.parse('https://wa.me/$digits'),
              failure: "Couldn't open WhatsApp"),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    this.icon,
    this.svgAsset,
    this.color,
    required this.tooltip,
    required this.onTap,
  }) : assert(icon != null || svgAsset != null);

  final IconData? icon;
  final String? svgAsset;
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    final glyph = svgAsset != null
        ? SvgPicture.asset(
            svgAsset!,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
          )
        : Icon(icon, size: 18, color: tint);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tint.withOpacity(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(child: glyph),
          ),
        ),
      ),
    );
  }
}
