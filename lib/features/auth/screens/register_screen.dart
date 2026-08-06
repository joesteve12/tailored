import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';

import '../../../core/widgets/feedback.dart';
import '../widgets/specialization_picker.dart';
/// Fields here match the confirmed /auth/register request body exactly:
/// business_name, owner_name, business_address, specializations, email, phone,
/// password. Password confirmation is a client-side-only check — there's no
/// separate "confirm_password" field in the request, so it's just UI
/// validation before the single `password` value gets sent.
///
/// `specializations` is a flat list of strings the [SpecializationPicker]
/// builds from the ticked preset chips plus any "Other" free text. The backend
/// requires at least one entry (and trims/de-dupes on its side); we validate
/// here too so the user gets an inline error instead of a round-trip.
///
/// Password rule (min 8 characters) mirrors the backend's own check.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Latest value lifted from the SpecializationPicker.
  List<String> _specializations = const [];
  // Shown under the picker once the user has tried to submit without picking
  // anything; cleared as soon as they pick something valid.
  String? _specializationError;

  bool _isSubmitting = false;
  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _businessAddressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authStateProvider.notifier).registerWithPassword(
            businessName: _businessNameController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            businessAddress: _businessAddressController.text.trim(),
            specializations: _specializations,
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );
      // Successful registration logs the user in (same token+user shape as
      // login) — the router's redirect guard sends them to /home on its
      // own once authStateProvider updates, no manual navigation needed.
      if (mounted) showSuccessSnackbar(context, 'Account created');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: 'Registration failed');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                    enabled: !_isSubmitting,
                    errorText: _specializationError,
                    onChanged: (values) {
                      setState(() {
                        _specializations = values;
                        if (values.isNotEmpty) _specializationError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 8) return 'At least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Confirm password'),
                    obscureText: true,
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
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
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => context.pop(),
                    child: const Text('Already have an account? Sign in'),
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
