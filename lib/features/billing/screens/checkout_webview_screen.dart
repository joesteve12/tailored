import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/feedback.dart';
import '../data/billing_repository.dart';

/// Args carried via go_router `extra` into the checkout WebView: the Paystack
/// hosted-checkout URL to open and the reference verify-on-return confirms.
class CheckoutArgs {
  const CheckoutArgs({required this.authorizationUrl, required this.reference});

  final String authorizationUrl;
  final String reference;
}

/// In-app Paystack checkout (Phase 6, decided over the alpha Paystack SDK /
/// external browser). Loads the hosted-checkout `authorization_url` in a WebView,
/// then confirms the outcome with `GET /billing/verify/{reference}` — the
/// authoritative reconciler, so confirmation never depends on webhook delivery
/// (webhooks can't even reach a dev box).
///
/// Because the backend attaches no `callback_url`, the return can't be pinned to
/// one redirect URL. Two paths therefore trigger verification: a conservative
/// auto-detect of Paystack's terminal URLs, and an always-visible "I've
/// completed payment" button so the shop is never trapped if auto-detect misses.
///
/// Pops `true` once verify reports the shop is on an active paid plan; the caller
/// then refreshes entitlements and shows a receipt. A dismissed/abandoned
/// checkout pops `false` (or `null` on a hardware back), and the caller still
/// re-checks — a late webhook may have applied it in the meantime.
class CheckoutWebViewScreen extends ConsumerStatefulWidget {
  const CheckoutWebViewScreen({super.key, required this.args});

  final CheckoutArgs args;

  @override
  ConsumerState<CheckoutWebViewScreen> createState() =>
      _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends ConsumerState<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _pageLoading = true;
  bool _verifying = false;
  bool _done = false; // guards against double-confirm / pop-after-dispose

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _pageLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _pageLoading = false);
          },
          onNavigationRequest: (request) {
            if (_looksComplete(request.url)) {
              // Terminal Paystack URL — confirm rather than following it.
              _confirm();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.args.authorizationUrl));
  }

  /// Conservative check for a Paystack terminal URL. Deliberately narrow so it
  /// never short-circuits the many legitimate navigations a hosted checkout makes
  /// (bank pages, OTP, 3-D Secure): only Paystack's own close page, or a redirect
  /// carrying the transaction reference back, counts as "done".
  bool _looksComplete(String url) {
    final lower = url.toLowerCase();
    // Paystack's own popup-close page.
    if (lower.contains('paystack') && lower.contains('/close')) return true;
    // The canonical return redirect carries ?trxref=... (Paystack appends it to
    // the callback). Deliberately NOT matching a bare "reference=" — that string
    // appears on intermediate checkout pages and would confirm too early. The
    // manual "I've completed payment" button covers any callback we don't catch.
    if (lower.contains('trxref=')) return true;
    return false;
  }

  /// Verify the checkout with the backend and pop on a confirmed active plan.
  Future<void> _confirm() async {
    if (_done || _verifying) return;
    setState(() => _verifying = true);
    try {
      final result =
          await ref.read(billingRepositoryProvider).verify(widget.args.reference);
      if (!mounted) return;
      if (result.isActivePaid || result.applied) {
        _done = true;
        Navigator.of(context).pop(true);
        return;
      }
      // Verified, but not yet a usable success — abandoned, or still settling.
      showErrorMessage(
        context,
        "We couldn't confirm your payment yet. If you completed it, wait a "
        'moment and try again.',
      );
    } on DioException catch (e) {
      if (!mounted) return;
      // 400 = transaction isn't a usable success (not paid / still pending).
      final status = e.response?.statusCode;
      if (status == 400) {
        showErrorMessage(
          context,
          "We couldn't confirm your payment yet. If you completed it, wait a "
          'moment and try again.',
        );
      } else {
        showErrorSnackbar(context, e, action: 'Verification failed');
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: 'Verification failed');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    return PopScope(
      // Let the pop happen (result defaults to null); the caller re-checks
      // entitlements regardless, so a back-out is never a dead end.
      canPop: !_verifying,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: _verifying ? null : () => Navigator.of(context).pop(false),
          ),
        ),
        body: Column(
          children: [
            if (_pageLoading)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: scheme.surfaceContainerLow,
              ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_verifying)
                    ColoredBox(
                      color: scheme.surface.withValues(alpha: 0.7),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _verifying ? null : _confirm,
                        child: _verifying
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("I've completed payment"),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pay on the secure Paystack page above, then tap to confirm.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
