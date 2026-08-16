import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/theme/app_tokens.dart';

/// Entry point to a recipient's measurements from the Client/Guest detail
/// screen — a single navigational tile, not an inline preview.
///
/// It used to render one row per template (a grouped preview) that fetched the
/// recipient's whole set list just to draw counts. Templates are no longer a
/// grouping concept — they only prefill the capture form — so the detail screen
/// has nothing to summarise here. The full, flat list (with record + edit)
/// lives on [MeasurementHistoryScreen]; this tile just opens it, and carries no
/// data dependency of its own.
class MeasurementListSection extends StatelessWidget {
  const MeasurementListSection({super.key, required this.recipient});

  final RecipientRef recipient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/measurements/history', extra: recipient),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Measurements',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(Icons.chevron_right, color: tokens.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
