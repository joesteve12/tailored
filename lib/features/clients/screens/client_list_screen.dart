import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/client_list_notifier.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/auth/models/user.dart';
import '../../../core/utils/hero_tags.dart';
import '../../../core/widgets/async_error_view.dart';

import '../../../core/widgets/feedback.dart';
class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
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
    // Trigger the next page a bit before hitting the literal bottom so
    // the next batch is loading by the time the user gets there.
    const threshold = 200.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      ref.read(clientListProvider.notifier).loadMore().catchError((_) {
        if (!mounted) return;
        showErrorMessage(context, 'Could not load more clients');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(
      authStateProvider.select((state) => state.valueOrNull),
      (previous, next) {
        final prevId = previous?.id;
        final nextId = next?.id;
        if (prevId != nextId) {
          ref.read(clientListProvider.notifier).refresh().catchError((_) {});
        }
      },
    );

    final listState = ref.watch(clientListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(clientListProvider.notifier).search(value),
            ),
          ),
          Expanded(
            child: listState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AsyncErrorView(
                error: err,
                onRetry: () => ref.read(clientListProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  // See employee_list_screen for why the empty state needs a
                  // scrollable wrapper to enable pull-to-refresh here.
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(clientListProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child:
                              const Center(child: Text('No clients yet')),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(clientListProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final client = state.items[index];
                      return ListTile(
                        leading: Hero(
                          tag: clientPhotoHeroTag(client.id),
                          // See client_detail_screen for why this is the
                          // centre-arc variant and not the MaterialApp
                          // default. This Hero is the *destination* when
                          // popping back from the detail screen, so its tween
                          // governs the return flight.
                          createRectTween: (begin, end) =>
                              MaterialRectCenterArcTween(
                                  begin: begin, end: end),
                          transitionOnUserGestures: true,
                          child: CircleAvatar(
                            backgroundImage: client.photoUrl != null
                                ? NetworkImage(client.photoUrl!)
                                : null,
                            child: client.photoUrl == null
                                ? Text(client.name.isNotEmpty
                                    ? client.name[0].toUpperCase()
                                    : '?')
                                : null,
                          ),
                        ),
                        title: Text(client.name),
                        subtitle: Text(client.phone),
                        trailing: const Icon(Icons.chevron_right),
                        // `extra: client` is load-bearing, not a shortcut.
                        // The detail screen needs a Client on its FIRST frame
                        // or its Hero isn't in the tree when the
                        // HeroController looks for a match — and it only looks
                        // once. Handing over the row we're already rendering
                        // is what makes the flight happen at all.
                        onTap: () => context.push(
                          '/clients/${client.id}',
                          extra: client,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clients',
        onPressed: () => context.push('/clients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
