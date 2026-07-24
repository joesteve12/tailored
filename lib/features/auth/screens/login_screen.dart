import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/auth_state.dart';

import '../../../core/utils/errors.dart';
import '../../../core/widgets/feedback.dart';
/// TODO: replace with your actual Web OAuth client ID from Google Cloud
/// Console — the SAME one your backend's settings.GOOGLE_CLIENT_ID points
/// to, NOT the Android client ID. Using the Android client ID here is the
/// single most common silent-failure point in this setup: the sign-in
/// itself succeeds on-device, but the backend's
/// id_token.verify_oauth2_token() rejects the token with an audience
/// mismatch, and the error you'll see is just "Invalid Google token."
const _googleServerClientId =
    'REPLACE_WITH_WEB_CLIENT_ID.apps.googleusercontent.com';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _googleSignIn = GoogleSignIn(serverClientId: _googleServerClientId);

  bool _isSubmitting = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitPasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authStateProvider.notifier).loginWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // No success snackbar here: navigation to the home screen is the
      // confirmation, and stacking a "Welcome back" on top just adds noise.
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: 'Login failed');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogleLogin() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the account picker — not an error.
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Google did not return an ID token');
      }

      await ref
          .read(authStateProvider.notifier)
          .loginWithGoogle(idToken: idToken);
      // No success snackbar — navigation confirms it.
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    'Tailored',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submitPasswordLogin,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _submitGoogleLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => context.push('/register'),
                    child: const Text("Don't have an account? Create one"),
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
