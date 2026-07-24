import 'package:flutter/material.dart';

import '../models/task_summary.dart';
import '../utils/task_labels.dart';

/// The horizontal stage timeline on a production task card. Each node
/// carries its wire state — untouched (empty circle) / in_progress (clock)
/// / done (filled check) / skipped (dash) — mapped to a glyph in one
/// place, so a state added on the backend is one switch arm here.
///
/// The completion date under a finished node is intentionally brief
/// ("22 Jul"); the card sits in a dense list and the filter tab already
/// tells the user which day is which.
class MiniTimeline extends StatelessWidget {
  const MiniTimeline({super.key, required this.stages});

  final List<StageBrief> stages;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final children = <Widget>[];
    for (var i = 0; i < stages.length; i++) {
      final stage = stages[i];
      children.add(_Node(stage: stage));
      if (i != stages.length - 1) {
        children.add(_Connector(finished: stage.isFinished));
      }
    }

    return DefaultTextStyle.merge(
      style: theme.textTheme.bodySmall ?? const TextStyle(),
      child: SizedBox(
        // Two lines: nodes + a caption row for finished dates. Fixed
        // height so cards in the list scroll uniformly.
        height: 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.stage});

  final StageBrief stage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    late Widget dot;
    switch (stage.state) {
      case 'done':
        dot = Container(
          width: 20,
          height: 20,
          decoration:
              BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          child: Icon(Icons.check, size: 14, color: scheme.onPrimary),
        );
        break;
      case 'skipped':
        dot = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline),
          ),
          child: Icon(Icons.remove, size: 14, color: scheme.onSurfaceVariant),
        );
        break;
      case 'in_progress':
        dot = Container(
          width: 20,
          height: 20,
          decoration:
              BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          child: Icon(Icons.schedule, size: 14, color: scheme.onPrimary),
        );
        break;
      case 'untouched':
      default:
        dot = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline, width: 1.5),
          ),
        );
    }

    // Caption slot fixed even when empty, so nodes on the same row all
    // align at their vertical centres regardless of who has a date.
    final finishedAt = stage.finishedAt;
    final caption = (stage.isFinished && finishedAt != null)
        ? Text(
            taskDueDateLabel(finishedAt.toLocal()),
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          )
        : const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(height: 4),
        SizedBox(height: 14, child: caption),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.finished});

  /// A connector reads as "traversed" iff the stage BEFORE it is finished
  /// (worked or skipped) — same rule as the reference UI.
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      // Vertical padding aligns the connector line with each dot's centre
      // (dot is 20 tall, so centre sits at y=10 within the row).
      padding: const EdgeInsets.only(top: 9),
      child: Container(
        width: 16,
        height: 2,
        color: finished ? scheme.primary : scheme.outlineVariant,
      ),
    );
  }
}
