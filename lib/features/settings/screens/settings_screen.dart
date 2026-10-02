import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/skeleton.dart';
import '../../home/state/home_dashboard_providers.dart';
import '../../promotions/state/promotion_providers.dart';
import '../../promotions/widgets/promo_slot.dart';

/// The "More" tab — the shop's hub for everything that isn't one of the four
/// primary flows (Home / Orders / Tasks / Customers). Renamed in the bottom
/// nav from "Settings", and rebuilt from a flat divided list into a modern
/// grouped layout: a business-identity header, a live Dashboard card, quick
/// search, colour-coded destination groups, an inline theme switcher, and a
/// log-out footer.
///
/// The class/route stay `SettingsScreen` / `/settings` — only the tab's label
/// and this screen's chrome changed, so the deep-link paths ('/settings/...')
/// its rows push to are untouched.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// Category accents for the destination chips. Fixed (not theme-derived) the
// same way [StatusColors] is: they read as distinct labels in both light and
// dark, tinted to a soft fill behind a full-strength icon. Dashboard rides the
// scheme's own terracotta primary, so it isn't listed here.
const Color _catBlue = Color(0xFF2563EB); // Employees
const Color _catAmber = Color(0xFFD97706); // Fabric inventory
const Color _catTeal = Color(0xFF0D9488); // Measurement fields
const Color _catViolet = Color(0xFF7C3AED); // Templates
const Color _catIndigo = Color(0xFF4F46E5); // Production processes
const Color _catRose = Color(0xFFBE185D); // Plan & billing

// Bumped alongside pubspec `version:` — shown in the footer.
const String _appVersion = '0.1.0';

/// Two initials for the business monogram: first letters of the first and last
/// words, or the first two letters of a single word.
String _monogram(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final w = parts.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

/// One navigable destination in the More hub. [color] tints its icon chip;
/// [onTap] pushes the (unchanged) route.
class _Dest {
  const _Dest({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Every row maps to a real, unchanged route. Dashboard leads (it's also the
    // hero card above the groups); the rest split into the two groups below.
    final destinations = <_Dest>[
      _Dest(
        title: 'Dashboard',
        subtitle: 'Business overview and key numbers',
        icon: Icons.bar_chart_outlined,
        color: scheme.primary,
        onTap: () => context.push('/dashboard'),
      ),
      _Dest(
        title: 'Employees',
        subtitle: 'Tailors you assign work to',
        icon: Icons.groups_outlined,
        color: _catBlue,
        onTap: () => context.push('/settings/employees'),
      ),
      _Dest(
        title: 'Fabric inventory',
        subtitle: 'Browse fabric in store, search by serial',
        icon: Icons.inventory_2_outlined,
        color: _catAmber,
        onTap: () => context.push('/fabrics'),
      ),
      _Dest(
        title: 'Measurement fields',
        subtitle: 'Everything your shop measures',
        icon: Icons.straighten,
        color: _catTeal,
        onTap: () => context.push('/settings/measurements/fields'),
      ),
      _Dest(
        title: 'Templates',
        subtitle: 'Which measurements each outfit needs',
        icon: Icons.checkroom_outlined,
        color: _catViolet,
        onTap: () => context.push('/settings/measurements/templates'),
      ),
      _Dest(
        title: 'Production processes',
        subtitle: 'The stages your task pipelines are built from',
        icon: Icons.linear_scale_outlined,
        color: _catIndigo,
        onTap: () => context.push('/settings/processes'),
      ),
      _Dest(
        title: 'Plan & billing',
        subtitle: 'Your plan, usage, and payments',
        icon: Icons.workspace_premium_outlined,
        color: _catRose,
        onTap: () => context.push('/settings/plan'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _Header(query: _query, controller: _searchController, onChanged: (v) {
              setState(() => _query = v.trim());
            }),
            const SizedBox(height: 18),
            if (_query.isEmpty)
              ..._browseBody(context, destinations)
            else
              ..._searchBody(context, destinations),
          ],
        ),
      ),
    );
  }

  /// The default view: identity header, live dashboard, grouped destinations,
  /// theme switcher, and the account footer.
  List<Widget> _browseBody(BuildContext context, List<_Dest> destinations) {
    return [
      const _ProfileCard(),
      const SizedBox(height: 14),
      const _DashboardCard(),
      const SizedBox(height: 22),
      const _GroupLabel('Workspace'),
      _Group([destinations[1], destinations[2]]),
      const SizedBox(height: 20),
      const _GroupLabel('Configuration'),
      _Group([destinations[3], destinations[4], destinations[5]]),
      const SizedBox(height: 20),
      const _GroupLabel('Billing'),
      _Group([destinations[6]]),
      const SizedBox(height: 20),
      // House-promo slot on a calm, non-time-pressured surface (proposal §5
      // `more_tab_card`). The padding applies only when a campaign renders, so
      // an empty slot leaves this layout byte-for-byte unchanged.
      const PromoSlot(
        placement: kMoreTabPlacement,
        padding: EdgeInsets.only(bottom: 20),
      ),
      const _GroupLabel('Preferences'),
      const _ThemeCard(),
      const SizedBox(height: 20),
      const _GroupLabel('Account'),
      const _LogoutCard(),
      const SizedBox(height: 20),
      // DEV-ONLY: a discreet entry to the AdMob bring-up smoke test
      // (AD_SYSTEM Phase A1). Compiled out of release builds by kDebugMode,
      // matching the debug-only `/dev/ads` route registration.
      if (kDebugMode) ...[
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Ads debug (dev)'),
          onTap: () => context.push('/dev/ads'),
        ),
        const SizedBox(height: 20),
      ],
      Center(
        child: Text(
          'Dinkee · v$_appVersion',
          style: TextStyle(
            fontSize: 11,
            color: context.appTokens.mutedForeground,
          ),
        ),
      ),
    ];
  }

  /// The filtered view: destinations whose title or subtitle matches the query,
  /// in one card — or a quiet empty state.
  List<Widget> _searchBody(BuildContext context, List<_Dest> destinations) {
    final q = _query.toLowerCase();
    final matches = destinations
        .where((d) =>
            d.title.toLowerCase().contains(q) ||
            d.subtitle.toLowerCase().contains(q))
        .toList();

    if (matches.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              'Nothing matches "$_query"',
              style: TextStyle(
                fontSize: 14,
                color: context.appTokens.mutedForeground,
              ),
            ),
          ),
        ),
      ];
    }
    return [_Group(matches)];
  }
}

/// The scrolling title + search field (this screen has no AppBar, matching the
/// Home tab's scroll-with-content header).
class _Header extends StatelessWidget {
  const _Header({
    required this.query,
    required this.controller,
    required this.onChanged,
  });

  final String query;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'More',
            style: TextStyle(
              fontFamily: tokens.fontDisplay,
              fontFamilyFallback: tokens.fontDisplayFallback,
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search settings',
            prefixIcon: Icon(Icons.search, size: 20, color: tokens.mutedForeground),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: tokens.mutedForeground,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              borderSide: BorderSide(
                color: scheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              borderSide: BorderSide(color: scheme.primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Business identity header — monogram, business name (with an Owner tag), and
/// the signed-in email. A display header, not a link (there's no business-edit
/// route to send it to), so it carries no chevron.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final user = ref.watch(authStateProvider).valueOrNull;

    final name = (user?.businessName.isNotEmpty ?? false)
        ? user!.businessName
        : (user?.email.split('@').first ?? 'Your business');
    final email = user?.email ?? '';
    final initials = _monogram(name);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Owner',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The Dashboard shortcut, rendered as a filled terracotta card that previews
/// three live figures off `homeSummaryProvider` (the same aggregate the Home
/// tab reads) and taps through to the full dashboard. Degrades gracefully: a
/// shimmer while loading, and a plain call-to-action card if the summary can't
/// be fetched — the card is always tappable regardless.
class _DashboardCard extends ConsumerWidget {
  const _DashboardCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final summaryAsync = ref.watch(homeSummaryProvider);

    Widget frame(Widget child) => Material(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(tokens.radiusXl),
          child: InkWell(
            onTap: () => context.push('/dashboard'),
            borderRadius: BorderRadius.circular(tokens.radiusXl),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: child,
            ),
          ),
        );

    final headerRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart_outlined, size: 19, color: scheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.onPrimary.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_outward, size: 16, color: scheme.onPrimary),
        ),
      ],
    );

    return summaryAsync.when(
      loading: () => frame(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerRow,
          const SizedBox(height: 14),
          Shimmer(
            baseColor: scheme.onPrimary.withValues(alpha: 0.18),
            highlightColor: scheme.onPrimary.withValues(alpha: 0.34),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Skeleton(
                      height: 52,
                      radius: 11,
                      color: scheme.onPrimary.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      )),
      error: (_, __) => frame(Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart_outlined,
                        size: 19, color: scheme.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Business overview and key numbers',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_outward, size: 18, color: scheme.onPrimary),
        ],
      )),
      data: (summary) => frame(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerRow,
          const SizedBox(height: 14),
          Row(
            children: [
              _DashStat(
                value: '${summary.production.ordersInProduction}',
                label: 'In production',
              ),
              const SizedBox(width: 10),
              _DashStat(
                value: formatCompactNaira(summary.revenue.amount),
                label: 'Revenue',
              ),
              const SizedBox(width: 10),
              _DashStat(
                value: formatCompactNaira(summary.revenue.outstanding),
                label: 'Outstanding',
              ),
            ],
          ),
        ],
      )),
    );
  }
}

/// One translucent figure tile inside the dashboard card.
class _DashStat extends StatelessWidget {
  const _DashStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.onPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: tokens.fontDisplay,
                  fontFamilyFallback: tokens.fontDisplayFallback,
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: scheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small section caption above a group.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: context.appTokens.mutedForeground,
        ),
      ),
    );
  }
}

/// A rounded card wrapping one or more destination rows, hairline-split.
class _Group extends StatelessWidget {
  const _Group(this.destinations);

  final List<_Dest> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    final rows = <Widget>[];
    for (var i = 0; i < destinations.length; i++) {
      rows.add(_DestRow(destinations[i]));
      if (i < destinations.length - 1) {
        rows.add(Divider(
          height: 1,
          thickness: 0.5,
          indent: 65,
          color: scheme.onSurface.withValues(alpha: 0.07),
        ));
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: rows),
    );
  }
}

/// A single tappable row: a tinted icon chip, a title + subtitle, a chevron.
class _DestRow extends StatelessWidget {
  const _DestRow(this.dest);

  final _Dest dest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    return InkWell(
      onTap: dest.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            _IconChip(icon: dest.icon, color: dest.color),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    dest.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: tokens.mutedForeground),
          ],
        ),
      ),
    );
  }
}

/// The rounded, tinted square that holds a destination's icon.
class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Appearance card: a leading chip and an inline Light / Dark / Auto segmented
/// control wired straight to [themeModeProvider].
class _ThemeCard extends ConsumerWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final mode = ref.watch(themeModeProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const _IconChip(icon: Icons.brightness_6_outlined, color: Color(0xFF8A5C3A)),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'Theme',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
          _ThemeSegment(
            mode: mode,
            onSelected: (m) =>
                ref.read(themeModeProvider.notifier).setThemeMode(m),
          ),
        ],
      ),
    );
  }
}

/// The Light / Dark / Auto pill switch.
class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({required this.mode, required this.onSelected});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    Widget seg(String label, ThemeMode m) {
      final selected = mode == m;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? scheme.primary : tokens.mutedForeground,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('Light', ThemeMode.light),
          seg('Dark', ThemeMode.dark),
          seg('Auto', ThemeMode.system),
        ],
      ),
    );
  }
}

/// The account footer's single action — sign out.
class _LogoutCard extends ConsumerWidget {
  const _LogoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: () => ref.read(authStateProvider.notifier).logout(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              _IconChip(icon: Icons.logout, color: scheme.error),
              const SizedBox(width: 13),
              Text(
                'Log out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: scheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
