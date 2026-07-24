import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/errors.dart';
import '../../../core/widgets/async_error_view.dart';
import '../data/task_repository.dart';
import '../models/production_process.dart';
import '../state/tasks_providers.dart';

/// Settings → Production processes: manage the shop's process dictionary
/// (Cutting, Stitching, …) that task pipelines are built from.
///
/// What each control maps to, and why the affordances look the way they do:
///
///  * Drag-to-reorder the ACTIVE list — `sort_order` drives the
///    pre-selected order on the Create Task screen. A drop renumbers every
///    active row 1..n and PATCHes the rows whose position changed (the
///    dictionary is a handful of rows; sequential PATCHes are fine and a
///    bulk endpoint would be ceremony).
///  * Rename — safe by design: stages snapshot the process name at
///    creation, so existing tasks keep the old spelling and history never
///    rewrites. The dialog says so.
///  * Deactivate — the only removal that exists. There is deliberately NO
///    hard delete server-side (stage rows RESTRICT the FK), so the UI
///    doesn't pretend otherwise. Deactivated rows stay visible, greyed,
///    with a Reactivate action (`is_active: true` on the same PATCH).
///  * Add — one text field in a dialog; the per-shop case-insensitive
///    uniqueness 400 ("A process named 'x' already exists") surfaces as an
///    inline field error, not a snackbar.
class ProcessesScreen extends ConsumerStatefulWidget {
  const ProcessesScreen({super.key});

  @override
  ConsumerState<ProcessesScreen> createState() => _ProcessesScreenState();
}

class _ProcessesScreenState extends ConsumerState<ProcessesScreen> {
  /// Local override of the active rows while a reorder is being saved, so
  /// the list doesn't snap back to server order mid-flight. Cleared once
  /// the providers are re-fetched (success) or on failure (revert).
  List<ProductionProcess>? _reordering;
  bool _busy = false;

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  void _invalidate() {
    ref.invalidate(allProcessesProvider);
    ref.invalidate(activeProcessesProvider);
  }

  /// The backend's own message for a 400 (the duplicate-name case) is the
  /// most useful thing to show; anything else goes through the shared
  /// [describeError] phrasing.
  String _errorText(Object e) {
    if (e is DioException && e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
    }
    return describeError(e);
  }

  Future<void> _onReorder(
      List<ProductionProcess> active, int oldIndex, int newIndex) async {
    if (_busy) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final next = List<ProductionProcess>.of(active);
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);

    setState(() {
      _reordering = next;
      _busy = true;
    });
    try {
      // Renumber 1..n; only PATCH rows whose sort_order actually changed.
      for (var i = 0; i < next.length; i++) {
        final wanted = i + 1;
        if (next[i].sortOrder != wanted) {
          await _repo.updateProcess(next[i].id, sortOrder: wanted);
        }
      }
      _invalidate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(e))));
        _invalidate(); // revert to server truth
      }
    } finally {
      if (mounted) {
        setState(() {
          _reordering = null;
          _busy = false;
        });
      }
    }
  }

  /// One dialog serves add AND rename — same field, same duplicate-name
  /// inline error; [existing] switches the copy and the call.
  Future<void> _nameDialog({ProductionProcess? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    String? errorText;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> save() async {
            final name = controller.text.trim();
            if (name.isEmpty) {
              setDialogState(() => errorText = 'Name cannot be empty');
              return;
            }
            setDialogState(() {
              saving = true;
              errorText = null;
            });
            try {
              if (existing == null) {
                // New rows land at the end of the active order.
                final active = ref
                        .read(allProcessesProvider)
                        .valueOrNull
                        ?.where((p) => p.isActive)
                        .length ??
                    0;
                await _repo.createProcess(name, sortOrder: active + 1);
              } else {
                await _repo.updateProcess(existing.id, name: name);
              }
              _invalidate();
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              setDialogState(() {
                saving = false;
                errorText = _errorText(e);
              });
            }
          }

          return AlertDialog(
            title: Text(existing == null ? 'New process' : 'Rename process'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Process name',
                    hintText: 'e.g. Embroidery',
                    counterText: '',
                    errorText: errorText,
                  ),
                  onSubmitted: (_) => save(),
                ),
                if (existing != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Existing tasks keep the old name — renaming never '
                      'rewrites history.',
                      style: Theme.of(ctx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color:
                                  Theme.of(ctx).colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(existing == null ? 'Add' : 'Rename'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }

  Future<void> _setActive(ProductionProcess process, bool active) async {
    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Deactivate ${process.name}?'),
          content: const Text(
              'New tasks can no longer use it. Stages already using it are '
              'unaffected, and you can reactivate it here any time.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Deactivate')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _busy = true);
    try {
      await _repo.updateProcess(process.id, isActive: active);
      _invalidate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final processesAsync = ref.watch(allProcessesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Production processes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _nameDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New process'),
      ),
      body: processesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () async => _invalidate(),
        ),
        data: (all) {
          final active = _reordering ??
              all.where((p) => p.isActive).toList(growable: false);
          final inactive =
              all.where((p) => !p.isActive).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(
                'The kinds of work your pipelines are built from. Their '
                'order here is the pre-selected order when creating a task.',
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (o, n) => _onReorder(active, o, n),
                children: [
                  for (var i = 0; i < active.length; i++)
                    Card(
                      key: ValueKey(active[i].id),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: i,
                          enabled: !_busy,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Text(active[i].name),
                        trailing: PopupMenuButton<String>(
                          enabled: !_busy,
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'rename', child: Text('Rename')),
                            PopupMenuItem(
                                value: 'deactivate',
                                child: Text('Deactivate')),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _nameDialog(existing: active[i]);
                              case 'deactivate':
                                _setActive(active[i], false);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('INACTIVE',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                            color: scheme.primary, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                for (final p in inactive)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.block_outlined,
                          color: scheme.onSurfaceVariant),
                      title: Text(p.name,
                          style:
                              TextStyle(color: scheme.onSurfaceVariant)),
                      trailing: TextButton(
                        onPressed: _busy ? null : () => _setActive(p, true),
                        child: const Text('Reactivate'),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
