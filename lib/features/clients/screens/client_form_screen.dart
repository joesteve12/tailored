import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/interstitial_ad_manager.dart';
import '../data/client_repository.dart';
import '../state/client_detail_notifier.dart';
import '../state/client_list_notifier.dart';
import '../../../core/widgets/async_error_view.dart';

import '../../../core/utils/errors.dart';
import '../../../core/widgets/feedback.dart';
/// Handles both create and edit. Pass [clientId] to edit an existing
/// client; omit it to create a new one.
///
/// No photo field here on purpose — POST /uploads/clients/{client_id}/photo
/// needs a client_id that doesn't exist yet during creation, so a new
/// client must be saved first and photo gets added afterward on the
/// detail screen.
class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key, this.clientId});

  final String? clientId;

  bool get isEditing => clientId != null;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Called once, the first time the existing client's data is available
  // — guarded by _prefilled so a later rebuild (e.g. from a provider
  // refresh) doesn't stomp on text the user is mid-way through editing.
  void _prefillIfNeeded({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) {
    if (_prefilled) return;
    _nameController.text = name;
    _phoneController.text = phone;
    _emailController.text = email ?? '';
    _addressController.text = address ?? '';
    _notesController.text = notes ?? '';
    _prefilled = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(clientRepositoryProvider);

      if (widget.isEditing) {
        await repo.update(
          widget.clientId!,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
        );
        // Refresh both the detail (this client) and list (in case name/
        // phone changed and it's currently visible) so nothing shows
        // stale data after popping back.
        ref.invalidate(clientDetailProvider(widget.clientId!));
        await ref.read(clientListProvider.notifier).refresh();
      } else {
        await repo.create(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
        );
        await ref.read(clientListProvider.notifier).refresh();
      }

      if (mounted) {
        showSuccessSnackbar(
          context,
          widget.isEditing ? 'Client updated' : 'Client created',
        );
        final wasCreate = !widget.isEditing;
        final interstitial = ref.read(interstitialAdManagerProvider);
        context.pop();
        // "Task complete" natural stop (AD_SYSTEM A3), create only. Fires after
        // the pop settles so it overlays the list/detail, never this form.
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
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration:
                    const InputDecoration(labelText: 'Email (optional)'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration:
                    const InputDecoration(labelText: 'Address (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
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
                    : Text(widget.isEditing ? 'Save changes' : 'Create client'),
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
        appBar: AppBar(title: const Text('New client')),
        body: _buildForm(context),
      );
    }

    final clientAsync = ref.watch(clientDetailProvider(widget.clientId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit client')),
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () =>
              ref.read(clientDetailProvider(widget.clientId!).notifier).refresh(),
        ),
        data: (client) {
          _prefillIfNeeded(
            name: client.name,
            phone: client.phone,
            email: client.email,
            address: client.address,
            notes: client.notes,
          );
          return _buildForm(context);
        },
      ),
    );
  }
}
