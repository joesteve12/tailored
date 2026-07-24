import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_summary.dart';
import '../state/tasks_providers.dart';
import '../utils/task_labels.dart';
import '../widgets/task_card.dart';
import '../widgets/todo_sheet.dart';

/// The Tasks tab — replaces the old Dashboard slot in the bottom nav.
/// Filter tabs across the top (Active / Delayed / Due today / Due
/// tomorrow — Completed reachable from the overflow menu), a search
/// field, and a mixed list of production task cards and to-do cards.
/// FAB creates a new to-do; production tasks are born from an order item
/// (see step 6 for that entry point).
///
/// Deep-linked from:
///   * the Home tab's Production chips (step 6) — with the filter
///     preselected via the `initialFilter` path passed on route,
///   * an order item's production chip (also step 6) — filter left at
///     'active'.
class TasksTabScreen extends ConsumerStatefulWidget {
  const TasksTabScreen({super.key, this.initialFilter});

  /// Wire filter value; must be one of the four live filters, or null for
  /// the default ('active'). 'completed' isn't a legal initial value —
  /// it's the history view and reached from the overflow menu.
  final String? initialFilter;

  @override
  ConsumerState<TasksTabScreen> createState() => _TasksTabScreenState();
}

class _TasksTabScreenState extends ConsumerState<TasksTabScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: kTaskLiveFilters.length,
    vsync: this,
    initialIndex: () {
      final initial = widget.initialFilter;
      if (initial == null) return 0;
      final idx = kTaskLiveFilters.indexOf(initial);
      return idx < 0 ? 0 : idx;
    }(),
  );

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {}); // rebuild for the list
    });
  }

  @override
  void didUpdateWidget(covariant TasksTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab lives in a StatefulShellBranch, so this State PERSISTS
    // across deep links: a second Home-chip tap rebuilds the widget with a
    // new initialFilter but never re-runs initState. React here or the
    // chip silently does nothing after the first use.
    final filter = widget.initialFilter;
    if (filter != null && filter != oldWidget.initialFilter) {
      final idx = kTaskLiveFilters.indexOf(filter);
      if (idx >= 0) {
        _tabs.animateTo(idx);
        if (_showCompleted) setState(() => _showCompleted = false);
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Debounce the search: refetching on every keystroke would flood the
  /// endpoint. 300 ms feels responsive without a query per letter.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  String get _activeFilter =>
      _showCompleted ? 'completed' : kTaskLiveFilters[_tabs.index];

  @override
  Widget build(BuildContext context) {
    final query = (
      filter: _activeFilter,
      search: _search.isEmpty ? null : _search,
      kind: null as String?,
    );
    final listAsync = ref.watch(taskListProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip:
                _showCompleted ? 'Show open tasks' : 'Show completed tasks',
            icon: Icon(_showCompleted
                ? Icons.checklist_rtl
                : Icons.history_toggle_off),
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
          ),
        ],
        bottom: _showCompleted
            ? PreferredSize(
                preferredSize: const Size.fromHeight(66),
                child: _CompletedBanner(
                  onClose: () => setState(() => _showCompleted = false),
                  searchField: _SearchField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                  ),
                ),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(110),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        for (final f in kTaskLiveFilters)
                          Tab(text: taskFilterLabel(f)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: _SearchField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTodoSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New to-do'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(taskListProvider(query));
          await ref.read(taskListProvider(query).future);
        },
        child: listAsync.when(
          data: (list) => _TaskList(
            results: list.results,
            emptyState: _EmptyState(filter: _activeFilter, search: _search),
          ),
          error: (err, _) => _ErrorState(
            error: err,
            onRetry: () => ref.invalidate(taskListProvider(query)),
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField(
      {required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search order, garment, client, to-do…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isDense: true,
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner({required this.onClose, required this.searchField});

  final VoidCallback onClose;
  final Widget searchField;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: scheme.surfaceContainerHighest,
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Icon(Icons.history_toggle_off,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Completed tasks',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 18,
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: searchField,
        ),
      ],
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.results, required this.emptyState});

  final List<TaskSummary> results;
  final Widget emptyState;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      // ListView so RefreshIndicator still works on empty state.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: emptyState,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => TaskCard(task: results[i]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.search});

  final String filter;
  final String search;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = search.isNotEmpty
        ? 'No matches for "$search".'
        : _messageForFilter(filter);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _messageForFilter(String f) {
    switch (f) {
      case 'active':
        return 'Nothing on the go right now.';
      case 'delayed':
        return 'Nothing is delayed — good.';
      case 'due_today':
        return 'Nothing due today.';
      case 'due_tomorrow':
        return 'Nothing due tomorrow.';
      case 'completed':
        return 'No completed tasks yet.';
      default:
        return 'No tasks.';
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: scheme.error),
          const SizedBox(height: 12),
          Text('Could not load tasks.',
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
