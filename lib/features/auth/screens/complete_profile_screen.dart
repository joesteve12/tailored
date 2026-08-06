import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/widgets/feedback.dart';
import '../widgets/specialization_picker.dart';

/// Shown to a logged-in business whose profile is missing anything registration
/// now collects — Google signups (empty business name, no owner/address/
/// specializations) and accounts created before those fields existed. The
/// router (app_router.dart) redirects here and keeps them here until
/// [UserProfileCompletion.isProfileComplete] is true, so this is a gate, not an
/// optional prompt.
///
/// Fields are pre-filled from whatever the account already has, so a Google
/// user who typed a business name at some point doesn't have to re-enter it,
/// and this doubles as a general profile editor. Submits via PUT /users/me
/// (auth_state.completeProfile); on success the redirect guard moves the user
/// to /home on its own.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _businessAddressController;

  late List<String> _specializations;
  String? _specializationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Seed from the current user so nothing already saved has to be retyped.
    final user = ref.read(authStateProvider).valueOrNull;
    _businessNameController =
        TextEditingController(text: user?.businessName ?? '');
    _ownerNameController = TextEditingController(text: user?.ownerName ?? '');
    _businessAddressController =
        TextEditingController(text: user?.businessAddress ?? '');
    _specializations = List<String>.from(user?.specializations ?? const []);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();

    final specializationsValid = _specializations.isNotEmpty;
    setState(() {
      _specializationError =
          specializationsValid ? null : 'Select at least one';
    });

    if (!formValid || !specializationsValid) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authStateProvider.notifier).completeProfile(
            businessName: _businessNameController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            businessAddress: _businessAddressController.text.trim(),
            specializations: _specializations,
          );
      // Router redirects to /home once the updated user is complete.
      if (mounted) showSuccessSnackbar(context, 'Profile saved');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: 'Could not save profile');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _logout,
            child: const Text('Log out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tell us a bit more about your business to finish setting '
                    'up your account.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _businessNameController,
                    decoration:
                        const InputDecoration(labelText: 'Business name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Owner / contact name',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Business address',
                    ),
                    textCapitalization: TextCapitalization.words,
                    maxLines: 2,
                    minLines: 1,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  SpecializationPicker(
                    initialValue: _specializations,
                    enabled: !_isSubmitting,
                    errorText: _specializationError,
                    onChanged: (values) {
                      setState(() {
                        _specializations = values;
                        if (values.isNotEmpty) _specializationError = null;
                      });
                    },
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
                        : const Text('Save and continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
