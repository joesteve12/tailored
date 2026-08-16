import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../models/task_summary.dart';

/// The horizontal stage progress bar on a production task card. Each stage
/// is a rounded segment with its name beneath it. It reads as a fill: solid
/// [ColorScheme.primary] once a stage is behind us, a lighter primary for
/// the stage in hand, and neutral for the stages ahead — one hue, so it
/// stays inside the app's warm palette instead of importing a second one.
///
/// The row SCROLLS horizontally: stage lists are dynamic (the backend
/// decides how many processes a garment has and what they're called), so a
/// four-stage suit and a nine-stage gown both get full, uncramped labels
/// instead of being squeezed to fit the card width.
class MiniTimeline extends StatelessWidget {
  const MiniTimeline({super.key, required this.stages});

  final List<StageBrief> stages;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // A dense list is a vertical scroller; let the finger drag the bar
      // sideways without the card fighting it for the gesture.
      physics: const ClampingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            if (i != 0) const SizedBox(width: 6),
            _Segment(stage: stages[i]),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.stage});

  final StageBrief stage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final muted = tokens.mutedForeground;

    late final Color bar;
    late final Color label;
    late final FontWeight weight;
    switch (stage.state) {
      case 'done':
        // Finished: filled solid with the brand colour.
        bar = scheme.primary;
        label = muted;
        weight = FontWeight.w600;
        break;
      case 'in_progress':
        // The stage in hand gets its own hue — a warm gold, not just a
        // paler primary (that was too near the finished segments to tell
        // apart) — plus the boldest, darkest label, so it's unmistakably
        // where the work is now.
        bar = tokens.chart3;
        label = scheme.onSurface;
        weight = FontWeight.w700;
        break;
      case 'skipped':
        // Traversed but not worked: a faded primary so the bar still reads
        // as "past", with a neutral label — it wasn't actually done.
        bar = scheme.primary.withValues(alpha: 0.3);
        label = muted;
        weight = FontWeight.w500;
        break;
      case 'untouched':
      default:
        // Ahead of the work: a faint NEUTRAL, so upcoming stages read as
        // plainly empty and never blend with the warm done/in-progress bars.
        bar = scheme.onSurface.withValues(alpha: 0.12);
        label = muted;
        weight = FontWeight.w500;
    }

    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _label(stage.processName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              color: label,
              fontWeight: weight,
            ),
          ),
        ],
      ),
    );
  }

  /// Backend `process_name` is usually already a clean label ("Cut"), but
  /// capitalise defensively so a lowercase wire value never renders raw.
  String _label(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }
}
