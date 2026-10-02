import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/interstitial_ad_manager.dart';
import '../data/guest_repository.dart';
import '../state/guest_detail_notifier.dart';
import '../state/guest_list_notifier.dart';
import '../../../core/widgets/async_error_view.dart';

import '../../../core/utils/errors.dart';
import '../../../core/widgets/feedback.dart';
/// Handles both create and edit, same split as ClientFormScreen. No
/// photo field here either, same chicken-and-egg reason: POST
/// /uploads/guests/{guest_id}/photo needs a guest_id that doesn't exist
/// until after creation, so a new guest must be saved first and the
/// photo added afterward on the detail screen.
class GuestFormScreen extends ConsumerStatefulWidget {
  const GuestFormScreen({super.key, required this.clientId, this.guestId});

  final String clientId;
  final String? guestId;

  bool get isEditing => guestId != null;

  @override
  ConsumerState<GuestFormScreen> createState() => _GuestFormScreenState();
}

class _GuestFormScreenState extends ConsumerState<GuestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();

  bool _isSubmitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  // Guarded by _prefilled so a later rebuild (e.g. a provider refresh)
  // doesn't stomp on text the user is mid-way through editing — same
  // pattern as ClientFormScreen.
  void _prefillIfNeeded({required String name, String? relation}) {
    if (_prefilled) return;
    _nameController.text = name;
    _relationController.text = relation ?? '';
    _prefilled = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(guestRepositoryProvider);

      if (widget.isEditing) {
        await repo.update(
          widget.clientId,
          widget.guestId!,
          name: _nameController.text.trim(),
          relation: _relationController.text.trim(),
        );
        ref.invalidate(guestDetailProvider(
          (clientId: widget.clientId, guestId: widget.guestId!),
        ));
        await ref.read(guestListProvider(widget.clientId).notifier).refresh();
      } else {
        await repo.create(
          widget.clientId,
          name: _nameController.text.trim(),
          relation: _relationController.text.trim(),
        );
        await ref.read(guestListProvider(widget.clientId).notifier).refresh();
      }

      if (mounted) {
        showSuccessSnackbar(
          context,
          widget.isEditing ? 'Guest updated' : 'Guest added',
        );
        final wasCreate = !widget.isEditing;
        final interstitial = ref.read(interstitialAdManagerProvider);
        context.pop();
        // "Task complete" natural stop (AD_SYSTEM A3), create only.
        if (wasCreate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            interstitial.notifyTaskComplete();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          e,
          action: '${widget.isEditing ? 'Update' : 'Create'} failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildForm(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationController,
                decoration: const InputDecoration(
                  labelText: 'Relation (optional)',
                  hintText: 'e.g. Spouse, Son, Daughter',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Save changes' : 'Add guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('New guest')),
        body: _buildForm(context),
      );
    }

    final guestAsync = ref.watch(guestDetailProvider(
      (clientId: widget.clientId, guestId: widget.guestId!),
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit guest')),
      body: guestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref
              .read(guestDetailProvider(
                (clientId: widget.clientId, guestId: widget.guestId!),
              ).notifier)
              .refresh(),
        ),
        data: (guest) {
          _prefillIfNeeded(name: guest.name, relation: guest.relation);
          return _buildForm(context);
        },
      ),
    );
  }
}
