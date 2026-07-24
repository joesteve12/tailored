import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/theme/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              value: mode,
              groupValue: current,
              title: Text(_themeLabel(mode)),
              onChanged: (v) => Navigator.pop(ctx, v),
            );
          }).toList(),
        ),
      ),
    );
    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Team'),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Employees'),
            subtitle: const Text('Tailors you assign work to'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/employees'),
          ),
          const Divider(height: 1),
          const _SectionHeader('Measurements'),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Measurement fields'),
            subtitle: const Text('Everything your shop measures'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/measurements/fields'),
          ),
          ListTile(
            leading: const Icon(Icons.checkroom_outlined),
            title: const Text('Templates'),
            subtitle: const Text('Which measurements each garment needs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/measurements/templates'),
          ),
          const Divider(height: 1),
          const _SectionHeader('Inventory'),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Fabric inventory'),
            subtitle: const Text('Browse fabric in store, search by serial'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/fabrics'),
          ),
          const Divider(height: 1),
          const _SectionHeader('Production'),
          ListTile(
            leading: const Icon(Icons.linear_scale_outlined),
            title: const Text('Production processes'),
            subtitle: const Text('The stages your task pipelines are built from'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/processes'),
          ),
          const Divider(height: 1),
          const _SectionHeader('Analytics'),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Dashboard'),
            subtitle: const Text('Business overview and key numbers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/dashboard'),
          ),
          const Divider(height: 1),
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, ref),
          ),
          const Divider(height: 1),
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(user?.businessName ?? '—'),
            subtitle: Text(user?.email ?? ''),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Log out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
