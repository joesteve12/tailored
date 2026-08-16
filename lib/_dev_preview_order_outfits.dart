// TEMPORARY dev-only harness to iterate on a restyled outfit card for
// OrderDetailScreen's Outfits tab, without a live backend. Not part of the
// app — the finished design gets ported into `_OrderItemCard`
// (order_detail_screen.dart) and this file deleted before committing.
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_tokens.dart';
import 'core/utils/money.dart';
import 'features/orders/models/fabric.dart';
import 'features/orders/models/order_item.dart';
import 'features/tasks/models/item_production.dart';
import 'core/models/recipient_ref.dart';

void main() {
  final kaftan = OrderItem(
    id: 'item-1',
    garmentType: 'Kaftan',
    description: 'Cream, hand-embroidered neckline',
    quantity: 1,
    unitPrice: 90000,
    recipientType: 'client',
    recipientClientId: 'client-1',
    fabrics: [
      Fabric(
        id: 'f1',
        orderItemId: 'item-1',
        serial: 'FB-1042',
        details: 'Cream cotton brocade',
        quantity: 4,
        unit: 'yards',
        createdAt: DateTime.now(),
      ),
      Fabric(
        id: 'f2',
        orderItemId: 'item-1',
        serial: 'FB-1043',
        details: 'Gold lining',
        quantity: 2,
        unit: 'yards',
        createdAt: DateTime.now(),
      ),
    ],
    production: const ItemProduction(
      state: 'in_progress',
      currentStageName: 'Cutting',
      currentStageStarted: true,
      taskId: 'task-1',
    ),
  );

  final gown = OrderItem(
    id: 'item-2',
    garmentType: 'Gown',
    quantity: 1,
    unitPrice: 50000,
    recipientType: 'client',
    recipientClientId: 'client-1',
    production: const ItemProduction(state: 'not_started'),
  );

  final agbada = OrderItem(
    id: 'item-3',
    garmentType: 'Agbada',
    quantity: 2,
    unitPrice: 120000,
    recipientType: 'guest',
    guestRecipientId: 'guest-1',
    production: const ItemProduction(
      state: 'in_progress',
      currentStageName: 'Stitching',
      currentStageStarted: false,
      taskId: 'task-3',
    ),
  );

  final suit = OrderItem(
    id: 'item-4',
    garmentType: 'Two-piece Suit',
    quantity: 1,
    unitPrice: 200000,
    recipientType: 'client',
    recipientClientId: 'client-1',
    production: const ItemProduction(
      state: 'done',
      currentStageName: 'Finishing',
      taskId: 'task-4',
    ),
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        appBar: AppBar(title: const Text('Outfits — restyle')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _OutfitCard(item: kaftan),
            _OutfitCard(item: gown),
            _OutfitCard(item: agbada),
            _OutfitCard(item: suit),
          ],
        ),
      ),
    ),
  );
}

/// Semantic color for a production state, used to tint the status pill.
class _ProdVisual {
  const _ProdVisual(this.color, this.label, this.icon);
  final Color color;
  final String label;
  final IconData icon;

  static _ProdVisual of(BuildContext context, ItemProduction p) {
    final scheme = Theme.of(context).colorScheme;
    if (!p.hasTask) {
      return _ProdVisual(scheme.primary, 'Create task', Icons.add_task);
    }
    if (p.isOverdue) {
      return _ProdVisual(scheme.error, p.label, Icons.error_outline);
    }
    if (p.done) {
      return const _ProdVisual(
          Color(0xFF16A34A), 'Done', Icons.check_circle_outline);
    }
    if (p.currentStageStarted) {
      // Actively being worked — brand primary (not an alarm color).
      return _ProdVisual(scheme.primary, p.label, Icons.autorenew_rounded);
    }
    // Queued / up next — muted.
    return _ProdVisual(
        context.appTokens.mutedForeground, p.label, Icons.schedule_rounded);
  }
}

/// Icon standing in for a garment when there's no fabric photo.
IconData _garmentIcon(String type) {
  final t = type.toLowerCase();
  if (t.contains('suit') || t.contains('agbada')) return Icons.checkroom;
  if (t.contains('gown') || t.contains('dress')) return Icons.woman;
  return Icons.checkroom_outlined;
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.appTokens.mutedForeground;
    final prod = _ProdVisual.of(context, item.production);

    final header = InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(item: item),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.garmentType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatNaira(item.lineTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        item.recipient.isGuest
                            ? Icons.person_outline
                            : Icons.account_circle_outlined,
                        size: 14,
                        color: muted,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${item.recipient.isGuest ? 'For a guest' : 'For the client'}  ·  Qty ${item.quantity} · ${formatNaira(item.unitPrice)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          if (item.fabrics.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                listTileTheme: const ListTileThemeData(
                  dense: true,
                  minVerticalPadding: 0,
                  visualDensity: VisualDensity(vertical: -4),
                ),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                title: Text('Details',
                    style: theme.textTheme.labelMedium?.copyWith(color: muted)),
                children: [
                  for (final f in item.fabrics)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.texture_outlined, size: 14, color: muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('${f.serial} · ${f.details}',
                                style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          _StatusBar(prod: prod, hasTask: item.production.hasTask),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;
    final url = item.primaryFabricImageUrl;

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Image.network(url, width: 60, height: 60, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Icon(
        _garmentIcon(item.garmentType),
        size: 26,
        color: tokens.mutedForeground,
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.prod, required this.hasTask});

  final _ProdVisual prod;
  final bool hasTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = prod.color;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        border: Border(
          top: BorderSide(color: tint.withValues(alpha: 0.22)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(prod.icon, size: 16, color: tint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                prod.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: tint),
          ],
        ),
      ),
    );
  }
}
