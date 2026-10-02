import 'package:canonical_adaptive_scaffold/canonical_adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ads/anchored_banner_ad.dart';

// Navigation chrome swaps at the Material 3 "md" window-size class — 840px, per
// the "breakpoints" section of tokens.json (sm 600 / md 840 / lg 1200). Below
// md the shell shows a bottom NavigationBar; at md and above it shows a vertical
// NavigationRail.
const double _mdBreakpoint = 840;

// Active for any width below md → drives the bottom NavigationBar.
const Breakpoint _belowMd = Breakpoint(beginWidth: 0, endWidth: _mdBreakpoint);

// Active for md and up → drives the NavigationRail.
const Breakpoint _mdAndUp = Breakpoint(beginWidth: _mdBreakpoint, andUp: true);

// Never active. AdaptiveScaffold exposes five size tiers; we only want the two
// states above, keyed on the single md (840) swap. Collapsing the mediumLarge /
// large / extraLarge tiers to a never-active breakpoint keeps one standard
// NavigationRail across all widths >= md and avoids relying on threshold values
// (e.g. the package default 1600) that aren't defined in tokens.json.
const Breakpoint _never = Breakpoint(beginWidth: double.infinity);

/// The app's persistent adaptive-nav scaffold. Wraps the five top-level tabs
/// (Home / Orders / Tasks / Customers / More) using go_router's
/// StatefulNavigationShell, which keeps each tab's navigation stack alive
/// when switching between them (an IndexedStack under the hood).
///
/// The navigation chrome is adaptive: a bottom [NavigationBar] below the "md"
/// breakpoint and a vertical [NavigationRail] at "md" and above (see
/// [_mdBreakpoint]). This is purely a chrome swap — routing is unchanged.
///
/// Detail and form screens (order detail, client form, employee detail, …)
/// are NOT branches here — they're top-level routes that render over this
/// shell on the root navigator, so they're full-screen with a back button,
/// matching the reference UI.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // initialLocation:true makes tapping the current tab again pop back to
    // its root, the conventional bottom-nav behaviour.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: navigationShell.currentIndex,
      onSelectedIndexChange: _onTap,
      // Keep the below-md navigation a bottom NavigationBar rather than a
      // drawer; drawerBreakpoint is intentionally left unconfigured.
      useDrawer: false,
      smallBreakpoint: _belowMd,
      mediumBreakpoint: _mdAndUp,
      mediumLargeBreakpoint: _never,
      largeBreakpoint: _never,
      extraLargeBreakpoint: _never,
      // Same content at every size — the branch shell (an IndexedStack over the
      // five tabs) is unchanged; only the navigation chrome around it adapts.
      // The anchored banner (AD_SYSTEM Phase A2) rides along at the bottom of
      // this same body column at every breakpoint: above the bottom
      // NavigationBar on small layouts, at the foot of the body on
      // NavigationRail layouts. It collapses to nothing for an ineligible
      // shop, so this is a no-op wrapper until then.
      smallBody: (_) => _ShellBody(navigationShell: navigationShell),
      body: (_) => _ShellBody(navigationShell: navigationShell),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        // Tasks replaces the old Dashboard slot in the bar. Dashboard is
        // now reached from Settings.
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Customers',
        ),
        // "More" — the catch-all hub (dashboard, team, inventory, shop setup,
        // appearance, account). Renamed from "Settings" because the tab holds
        // far more than app preferences; the three-dots glyph reads as "more"
        // rather than the gear's "settings".
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }
}

/// Wraps a branch's content with the anchored banner pinned to the bottom of
/// the body column (AD_SYSTEM Phase A2). [AnchoredBannerAd] renders
/// `SizedBox.shrink()` for an ineligible/paid shop, so this is a plain
/// pass-through of [navigationShell] until a shop is ad-eligible.
class _ShellBody extends StatelessWidget {
  const _ShellBody({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: navigationShell),
        const AnchoredBannerAd(),
      ],
    );
  }
}
