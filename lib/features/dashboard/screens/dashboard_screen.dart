import 'package:flutter/material.dart';

/// Placeholder Dashboard tab. The real stat cards (delivery due, trials due,
/// revenue, item-due list) come in a later phase against the admin-stats
/// endpoint; this keeps the tab present in the nav shell without faking data.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart_outlined, size: 40),
              const SizedBox(height: 12),
              Text('Dashboard coming soon',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Stats and due outfits will appear here.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
