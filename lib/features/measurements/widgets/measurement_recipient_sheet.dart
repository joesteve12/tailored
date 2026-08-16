import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../clients/data/client_repository.dart';
import '../../clients/models/client.dart';
import '../../guests/data/guest_repository.dart';
import '../../guests/models/guest_profile.dart';

/// Presents a bottom sheet that resolves "who is this measurement for?" — a
/// client, or one of that client's guests (family members measured under the
/// same account). Returns the chosen [RecipientRef], or null if dismissed.
///
/// Two steps: pick a client, then — only if that client has guests — pick the
/// client themselves or a guest. A guest-less client resolves in a single tap,
/// which is the common case.
///
/// Self-contained on purpose: it queries the client/guest repositories
/// directly with its own state rather than driving the shared list providers,
/// so opening the picker never disturbs the Clients tab's filter or a client
/// detail screen's guest list.
Future<RecipientRef?> showMeasurementRecipientSheet(BuildContext context) {
  return showModalBottomSheet<RecipientRef>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _MeasurementRecipientSheet(),
  );
}

class _MeasurementRecipientSheet extends ConsumerStatefulWidget {
  const _MeasurementRecipientSheet();

  @override
  ConsumerState<_MeasurementRecipientSheet> createState() =>
      _MeasurementRecipientSheetState();
}

class _MeasurementRecipientSheetState
    extends ConsumerState<_MeasurementRecipientSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // ── Step 1: client list ──────────────────────────────────────────────────
  List<Client> _clients = [];
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _page = 1;
  int _total = 0;
  String _query = '';

  // Only the latest search/refresh may write state. A slow response for an
  // earlier query (the user kept typing) is discarded rather than clobbering
  // the results actually on screen.
  int _requestSeq = 0;

  // ── Step 2: recipient within a client ────────────────────────────────────
  // Non-null once a client is chosen AND confirmed to have guests: the sheet
  // switches to the guest/self picker. Null shows the client list.
  Client? _selectedClient;
  List<GuestProfile> _guests = [];
  bool _loadingGuests = false;
  Object? _guestError;
  int _guestSeq = 0;

  // The client whose guests are being fetched from the list (step 1). Kept
  // separate from [_selectedClient] so a guest-less client never flashes the
  // step-2 view: we stay on the list, show a spinner on its row, and only
  // advance once guests are confirmed to exist.
  String? _pendingClientId;

  bool get _hasMore => _clients.length < _total;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadClients(query: '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = 200.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      _loadMoreClients();
    }
  }

  Future<void> _loadClients({required String query}) async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
      _query = query;
    });
    try {
      final res =
          await ref.read(clientRepositoryProvider).list(search: query, page: 1);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _clients = res.results;
        _page = res.page;
        _total = res.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreClients() async {
    if (_loadingMore || _loading || !_hasMore) return;
    final seq = _requestSeq;
    setState(() => _loadingMore = true);
    try {
      final res = await ref
          .read(clientRepositoryProvider)
          .list(search: _query, page: _page + 1);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _clients = [..._clients, ...res.results];
        _page = res.page;
        _total = res.total;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || seq != _requestSeq) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
        const Duration(milliseconds: 400), () => _loadClients(query: value));
  }

  // Step 1 → 2. Fetch the tapped client's guests without leaving the list. A
  // guest-less client resolves immediately (fast path, no step-2 flash);
  // otherwise the sheet advances to the guest/self picker.
  Future<void> _openClient(Client client) async {
    if (_pendingClientId != null) return; // ignore taps while one resolves
    final seq = ++_guestSeq;
    setState(() => _pendingClientId = client.id);
    try {
      final guests = await ref.read(guestRepositoryProvider).list(client.id);
      if (!mounted || seq != _guestSeq) return;
      if (guests.isEmpty) {
        // No guests — the only recipient is the client themselves.
        Navigator.of(context).pop(clientRecipient(client.id));
        return;
      }
      setState(() {
        _pendingClientId = null;
        _selectedClient = client;
        _guests = guests;
        _guestError = null;
        _loadingGuests = false;
      });
    } catch (e) {
      if (!mounted || seq != _guestSeq) return;
      // Guests couldn't load. Advance to step 2 anyway with a retry, so the
      // user can still proceed with the client themselves.
      setState(() {
        _pendingClientId = null;
        _selectedClient = client;
        _guests = [];
        _guestError = e;
        _loadingGuests = false;
      });
    }
  }

  // Step-2 retry after a failed guest load. Unlike [_openClient] this keeps
  // the guest/self view up and shows an inline spinner while refetching.
  Future<void> _retryGuests() async {
    final client = _selectedClient;
    if (client == null) return;
    final seq = ++_guestSeq;
    setState(() {
      _guestError = null;
      _loadingGuests = true;
    });
    try {
      final guests = await ref.read(guestRepositoryProvider).list(client.id);
      if (!mounted || seq != _guestSeq) return;
      if (guests.isEmpty) {
        // The guests were removed since we last looked — the client is now the
        // only recipient.
        Navigator.of(context).pop(clientRecipient(client.id));
        return;
      }
      setState(() {
        _guests = guests;
        _loadingGuests = false;
      });
    } catch (e) {
      if (!mounted || seq != _guestSeq) return;
      setState(() {
        _guestError = e;
        _loadingGuests = false;
      });
    }
  }

  void _backToClients() {
    setState(() {
      _selectedClient = null;
      _guests = [];
      _guestError = null;
      _loadingGuests = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: _selectedClient == null
            ? _buildClientStep(context)
            : _buildRecipientStep(context, _selectedClient!),
      ),
    );
  }

  // ── Step 1 UI ────────────────────────────────────────────────────────────
  Widget _buildClientStep(BuildContext context) {
    final tokens = context.appTokens;
    return Column(
      children: [
        const _SheetHeader(
          title: 'New measurement',
          subtitle: 'Who is this measurement for?',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name or phone',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(child: _buildClientList(context, tokens)),
      ],
    );
  }

  Widget _buildClientList(BuildContext context, AppTokens tokens) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AsyncErrorView(
        error: _error!,
        onRetry: () async => _loadClients(query: _query),
      );
    }
    if (_clients.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty ? 'No clients yet' : 'No clients match "$_query"',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: tokens.mutedForeground),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: _clients.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _clients.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final client = _clients[index];
        return ListTile(
          leading: _Avatar(
            name: client.name,
            photoUrl: client.photoUrl,
            scheme: scheme,
          ),
          title: Text(
            client.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(client.phone, overflow: TextOverflow.ellipsis),
          // While this row's guests are being fetched, a spinner replaces the
          // chevron. The chevron otherwise hints there may be a second step
          // (guests); guest-less clients still resolve in one tap.
          trailing: _pendingClientId == client.id
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.chevron_right, color: tokens.mutedForeground),
          onTap: () => _openClient(client),
        );
      },
    );
  }

  // ── Step 2 UI ────────────────────────────────────────────────────────────
  Widget _buildRecipientStep(BuildContext context, Client client) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Column(
      children: [
        _SheetHeader(
          title: client.name,
          subtitle: 'Who is this measurement for?',
          onBack: _backToClients,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            children: [
              // The client themselves.
              ListTile(
                leading: _Avatar(
                  name: client.name,
                  photoUrl: client.photoUrl,
                  scheme: scheme,
                ),
                title: Text(
                  client.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('This client'),
                onTap: () =>
                    Navigator.of(context).pop(clientRecipient(client.id)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'GUESTS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tokens.mutedForeground,
                        letterSpacing: 0.6,
                      ),
                ),
              ),
              if (_loadingGuests)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_guestError != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Couldn't load guests.",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _retryGuests,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                for (final guest in _guests)
                  ListTile(
                    leading: _Avatar(
                      name: guest.name,
                      photoUrl: guest.photoUrl,
                      scheme: scheme,
                    ),
                    title: Text(
                      guest.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: (guest.relation != null &&
                            guest.relation!.isNotEmpty)
                        ? Text(guest.relation!)
                        : null,
                    onTap: () =>
                        Navigator.of(context).pop(guestRecipient(guest.id)),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The sheet's title block, optionally with a back button for the second step.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: tokens.mutedForeground),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(onBack == null ? 20 : 4, 4, 20, 4),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to clients',
              onPressed: onBack,
            ),
          Expanded(child: titles),
        ],
      ),
    );
  }
}

/// Circle avatar showing a network photo, or the recipient's first initial.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.photoUrl,
    required this.scheme,
  });

  final String name;
  final String? photoUrl;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: scheme.primaryContainer,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}
