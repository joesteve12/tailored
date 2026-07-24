import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clients/data/client_repository.dart';
import '../../clients/models/client.dart';
import '../../../core/widgets/async_error_view.dart';

/// Returns the picked client's id via Navigator.pop, or null if dismissed
/// without picking one. Deliberately not a Riverpod-cached provider/
/// notifier — this is a one-off, throwaway lookup for a single pick, not
/// app state anything else needs to watch or that benefits from being
/// kept alive.
///
/// pageSize: 50, no "load more" — with a confirmed ceiling of ~300
/// clients, an unfiltered list is rare to need beyond one page, and
/// typing a few characters narrows it immediately via the same `search`
/// param ClientListScreen already uses. Not built to scale past that
/// ceiling.
class ClientPickerSheet extends ConsumerStatefulWidget {
  const ClientPickerSheet({super.key});

  @override
  ConsumerState<ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends ConsumerState<ClientPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late Future<List<Client>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _fetch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Client>> _fetch(String query) async {
    final response = await ref
        .read(clientRepositoryProvider)
        .list(search: query, pageSize: 50);
    return response.results;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _resultsFuture = _fetch(value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose a client',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Client>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AsyncErrorView(
                      error: snapshot.error!,
                      onRetry: () async {
                        setState(() {
                          _resultsFuture = _fetch(_searchController.text);
                        });
                        await _resultsFuture;
                      },
                    );
                  }
                  final clients = snapshot.data ?? const [];
                  if (clients.isEmpty) {
                    return const Center(child: Text('No clients found'));
                  }
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: clients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: client.photoUrl != null
                              ? NetworkImage(client.photoUrl!)
                              : null,
                          child: client.photoUrl == null
                              ? Text(client.name.isNotEmpty
                                  ? client.name[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(client.name),
                        subtitle: Text(client.phone),
                        onTap: () => Navigator.pop(context, client.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
