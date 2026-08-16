// TEMPORARY dev-only harness to visually verify the redesigned
// ClientDetailScreen without a live backend. Not part of the app — delete
// before committing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/clients/models/client.dart';
import 'features/clients/screens/client_detail_screen.dart';
import 'features/clients/state/client_stats_provider.dart';

void main() {
  final client = Client(
    id: 'preview-1',
    name: 'Miriam Tetteh',
    phone: '+233 20 112 3344',
    email: 'm.tetteh@email.com',
    address: '7 Ring Road Central, Accra',
    createdAt: DateTime.now(),
  );

  final router = GoRouter(
    initialLocation: '/clients/preview-1',
    routes: [
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) => ClientDetailScreen(
          clientId: 'preview-1',
          initialClient: client,
        ),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Edit screen (stub)'))),
      ),
      GoRoute(
        path: '/orders/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('New order (stub)'))),
      ),
    ],
  );

  runApp(
    ProviderScope(
      overrides: [
        // Richer placeholder numbers than the shipped zero-default, purely
        // so the stats strip has something to look at in this preview.
        clientStatsProvider('preview-1').overrideWith(
          (ref) => const ClientStats(
            revenue: 148000,
            outstanding: 32000,
            refundDue: 0,
            activeOrders: 1,
            guests: 0,
          ),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    ),
  );
}
