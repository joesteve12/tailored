import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/fabric_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/skeleton.dart';
import '../models/fabric_inventory.dart';
import '../state/fabric_list_state.dart';
import '../state/fabric_providers.dart';

/// The shop's fabric inventory: every fabric across all orders, newest first,
/// with a search box that matches serial / details / recipient name. Tapping a
/// row opens the fabric's detail (which links through to its order). This is
/// the entry point reached from the Home tab.
class FabricInventoryScreen extends ConsumerStatefulWidget {
  const FabricInventoryScreen({super.key});

  @override
  ConsumerState<FabricInventoryScreen> createState() =>
      _FabricInventoryScreenState();
}

class _FabricInventoryScreenState extends ConsumerState<FabricInventoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Kick off the next page a bit before the literal bottom, so the new rows
    // are landing by the time the user scrolls to them. The notifier itself
    // no-ops when a page is already loading or there's nothing left, so this
    // can fire freely.
    const threshold = 300.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      ref.read(fabricListProvider.notifier).loadMore().catchError((_) {
        if (!mounted) return;
        showErrorMessage(context, 'Could not load more fabric');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final listAsync = ref.watch(fabricListProvider);
    // Drives the clear button off the field's live text, not the debounced
    // query — so it appears the instant the user types.
    final hasQuery = _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Fabric inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {}); // refresh clear-button visibility
                ref.read(fabricListProvider.notifier).search(value);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search serial, fabric, or customer',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: !hasQuery
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref.read(fabricListProvider.notifier).search('');
                        },
                      ),
                // Filled, borderless pill to match the remodeled surfaces —
                // the row cards below carry the visible edges, so the search
                // field stays quiet chrome.
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: scheme.outlineVariant.withOpacity(0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: listAsync.when(
              // skipLoadingOnReload keeps the current rows on screen during a
              // search/refresh refetch instead of flashing the skeleton over
              // results that are already there.
              skipLoadingOnReload: true,
              loading: () => const SkeletonList(
                scrollable: true,
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                separatorHeight: 10,
                // 1 count strip + a screenful of cards.
                itemCount: 7,
                itemBuilder: _fabricSkeletonRow,
              ),
              error: (err, _) => AsyncErrorView(
                error: err,
                onRetry: () => ref.read(fabricListProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(fabricListProvider.notifier).refresh(),
                    child: _EmptyState(searching: state.searchQuery.isNotEmpty),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(fabricListProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    // Header (index 0) + the loaded cards + an optional trailing
                    // load-more spinner while more pages remain.
                    itemCount: 1 + state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) return _CountHeader(state: state);

                      final index = i - 1;
                      if (index >= state.items.length) {
                        // Trailing loader — reached only when hasMore is true.
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            ),
                          ),
                        );
                      }
                      return _FabricCard(fabric: state.items[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The "N fabrics in inventory" / "N matches" strip above the list. Counts the
/// server's [FabricListState.total] (the full result size), not just the rows
/// loaded so far, so it reads "1000 fabrics" from the first page onward.
class _CountHeader extends StatelessWidget {
  const _CountHeader({required this.state});

  final FabricListState state;

  @override
  Widget build(BuildContext context) {
    final searching = state.searchQuery.isNotEmpty;
    final count = state.total;
    final text = searching
        ? '$count match${count == 1 ? '' : 'es'}'
        : '$count fabric${count == 1 ? '' : 's'} in inventory';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.appTokens.mutedForeground,
            ),
      ),
    );
  }
}

/// Loading placeholder that mirrors the real inventory list: a short count
/// strip up top (index 0), then cards shaped exactly like [_FabricCard] — a
/// rounded swatch, the serial line, two subtitle lines, and a trailing chevron.
///
/// Two deliberate touches so it reads as loading *content* rather than a stack
/// of identical bars:
///  * The card is an outlined shell with a transparent interior, not a filled
///    block. The shimmer's `srcATop` mask would otherwise flood an opaque fill
///    edge-to-edge and hide the bar shapes inside it.
///  * Serial / line widths cycle per row, so no two adjacent cards align.
Widget _fabricSkeletonRow(BuildContext context, int index) {
  final scheme = Theme.of(context).colorScheme;

  // The first slot stands in for the "N fabrics in inventory" count strip, so
  // the header doesn't pop in and shove the first card down when data lands.
  if (index == 0) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 2, left: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Skeleton(width: 150, height: 12),
      ),
    );
  }

  // Deterministic per-row variation — a few width recipes cycled by index.
  const serialWidths = [76.0, 92.0, 64.0, 104.0];
  const line1Factors = [0.72, 0.58, 0.80, 0.64];
  const line2Factors = [0.48, 0.62, 0.40, 0.54];
  final v = index % serialWidths.length;

  return Container(
    // No fill: an outlined shell keeps the interior transparent so the shimmer
    // reads the individual bars rather than one solid swept rectangle. The
    // border rides at low opacity, so it stays a faint frame while the bars
    // (full opacity) carry the eye.
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
    ),
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        const Skeleton(width: 56, height: 56, radius: 12),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Serial line — the display headline slot.
              Skeleton(width: serialWidths[v], height: 15),
              const SizedBox(height: 10),
              // garment · order line.
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: line1Factors[v],
                child: const Skeleton(height: 11),
              ),
              const SizedBox(height: 6),
              // recipient · quantity line.
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: line2Factors[v],
                child: const Skeleton(height: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // The chevron slot — a slim placeholder, faint like the real muted icon.
        const Skeleton(width: 9, height: 16, radius: 3),
      ],
    ),
  );
}

/// A single fabric as a raised card — a rounded swatch thumbnail, the serial
/// (the physical tag number) as the headline, and one muted subtitle line
/// (garment · order, and the recipient / quantity when present). Deliberately
/// spare: the detail screen carries the rest.
class _FabricCard extends StatelessWidget {
  const _FabricCard({required this.fabric});

  final FabricInventoryItem fabric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = context.appTokens.mutedForeground;
    final qty = formatFabricQuantity(fabric.quantity, fabric.unit);
    final hasRecipient =
        fabric.recipientName != null && fabric.recipientName!.isNotEmpty;

    // Second subtitle line: whoever it's for, and how much — whichever exist.
    final secondLine = <String>[
      if (hasRecipient) 'for ${fabric.recipientName}',
      if (qty != null) qty,
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/fabrics/${fabric.serial}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            // Center everything so the chevron sits mid-card against the
            // thumbnail rather than pinned to the top.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Thumb(imageUrl: fabric.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fabric.serial,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: context.appTokens.fontDisplay,
                        fontFamilyFallback:
                            context.appTokens.fontDisplayFallback,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fabric.garmentType} · ${fabric.orderNumber}',
                      style: textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondLine,
                        style: textTheme.bodySmall?.copyWith(color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    if (!hasImage) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.surfaceContainerHighest,
        ),
        child: Icon(Icons.texture_outlined,
            color: context.appTokens.mutedForeground),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          color: scheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;
    return ListView(
      // AlwaysScrollable so the wrapping RefreshIndicator can be pulled even
      // though the empty state is shorter than the viewport.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 88),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching ? Icons.search_off : Icons.texture_outlined,
              size: 40,
              color: muted,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            searching
                ? 'No fabric matches that search'
                : 'No fabric recorded yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (!searching) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Fabric you add to an outfit shows up here.',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ],
    );
  }
}
