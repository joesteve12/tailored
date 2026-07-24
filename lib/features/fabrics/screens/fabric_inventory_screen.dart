import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/fabric_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../models/fabric_inventory.dart';
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Debounce so we don't fire a request per keystroke; the provider is keyed
    // by the query, so the latest value wins.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(fabricSearchProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(fabricSearchProvider);
    final fabricsAsync = ref.watch(fabricListProvider(search));

    return Scaffold(
      appBar: AppBar(title: const Text('Fabric inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search serial, fabric, or customer',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          ref.read(fabricSearchProvider.notifier).state = '';
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: fabricsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AsyncErrorView(
                error: err,
                onRetry: () async =>
                    ref.refresh(fabricListProvider(search).future),
              ),
              data: (fabrics) {
                if (fabrics.isEmpty) {
                  return _EmptyState(searching: search.isNotEmpty);
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(fabricListProvider(search).future),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: fabrics.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _FabricTile(fabric: fabrics[i]),
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

class _FabricTile extends StatelessWidget {
  const _FabricTile({required this.fabric});

  final FabricInventoryItem fabric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = formatFabricQuantity(fabric.quantity, fabric.unit);
    final subtitleParts = <String>[
      if (fabric.details != null && fabric.details!.isNotEmpty) fabric.details!,
      '${fabric.garmentType} · ${fabric.orderNumber}',
      if (fabric.recipientName != null && fabric.recipientName!.isNotEmpty)
        'for ${fabric.recipientName}',
    ];

    return ListTile(
      leading: _Thumb(imageUrl: fabric.imageUrl),
      title: Row(
        children: [
          Expanded(
            child: Text(
              fabric.serial,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (qty != null) ...[
            const SizedBox(width: 8),
            Text(qty, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
      subtitle: Text(
        subtitleParts.join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: subtitleParts.length > 1,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/fabrics/${fabric.serial}'),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    if (!hasImage) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Icon(Icons.texture_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.broken_image_outlined),
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
    return ListView(
      // ListView so RefreshIndicator-less empty state is still scrollable on
      // small screens and centers nicely.
      children: [
        const SizedBox(height: 96),
        Icon(
          searching ? Icons.search_off : Icons.texture_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            searching
                ? 'No fabric matches that search'
                : 'No fabric recorded yet',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (!searching) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Fabric you add to an outfit shows up here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}
