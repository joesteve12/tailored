import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ads/ads_controller.dart';
import 'core/ads/interstitial_ad_manager.dart';
import 'core/notifications/reminder_reconciler.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

void main() {
  runApp(const ProviderScope(child: TailoredApp()));
}

class TailoredApp extends ConsumerWidget {
  const TailoredApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Activate the reminder reconciler for the app's lifetime: keeps local
    // notifications matched to the server's reminder set, auth-aware.
    // Watching (not reading) a plain Provider just pins it alive; its
    // create runs once. See core/notifications/reminder_reconciler.dart.
    ref.watch(reminderReconcilerProvider);
    // Same "pin a controller alive" trick for AdMob bring-up (AD_SYSTEM A1):
    // it watches ad eligibility and initialises the SDK behind consent only
    // once the server confirms an ad-eligible (Starter/trialing) shop. A paid
    // shop, or a not-yet-loaded snapshot, keeps it inert. See ads_controller.
    ref.watch(adsControllerProvider);
    // Pin the interstitial manager alive too (AD_SYSTEM A3): it preloads a
    // capped full-screen ad for eligible shops and shows it only on a natural
    // stop (returning to a tab root). The router provider attaches it to the
    // router; here we just keep the singleton from being disposed.
    ref.watch(interstitialAdManagerProvider);

    return MaterialApp.router(
      title: 'Dinkee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
