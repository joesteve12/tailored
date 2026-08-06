import 'package:flutter/material.dart';

/// Preset clothing specializations offered as chips wherever the app collects
/// them (signup and the "complete your profile" flow). Anything outside this
/// list goes in the free-text "Other" box and is appended to the emitted list.
/// Change this one constant to change the presets everywhere.
const List<String> kSpecializationOptions = [
  'Native / Traditional wear',
  'Agbada / Kaftan',
  'Suits & Corporate',
  'Wedding / Bridal',
  'Casual wear',
  'Uniforms',
];

/// Chip multi-select + "Other" free-text for clothing specializations.
///
/// Holds its own UI state and lifts the combined, trimmed, de-duped list to the
/// parent through [onChanged] on every change, so the parent owns validation
/// and submission. [initialValue] is split back into preset chips vs. the Other
/// box on first build, so it round-trips an already-saved value cleanly.
class SpecializationPicker extends StatefulWidget {
  const SpecializationPicker({
    super.key,
    this.initialValue = const [],
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  final List<String> initialValue;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final String? errorText;

  @override
  State<SpecializationPicker> createState() => _SpecializationPickerState();
}

class _SpecializationPickerState extends State<SpecializationPicker> {
  final Set<String> _selected = <String>{};
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    // Sort incoming values into preset selections vs. free text, so editing an
    // existing profile shows its saved specializations correctly.
    final others = <String>[];
    for (final v in widget.initialValue) {
      final t = v.trim();
      if (t.isEmpty) continue;
      if (kSpecializationOptions.contains(t)) {
        _selected.add(t);
      } else {
        others.add(t);
      }
    }
    _otherController = TextEditingController(text: others.join(', '));
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  /// Ticked chips first (in preset order), then any comma-separated entries
  /// from the Other box. Trimmed and de-duped.
  List<String> _collect() {
    final result = <String>[];
    for (final option in kSpecializationOptions) {
      if (_selected.contains(option)) result.add(option);
    }
    for (final part in _otherController.text.split(',')) {
      final t = part.trim();
      if (t.isNotEmpty && !result.contains(t)) result.add(t);
    }
    return result;
  }

  void _emit() => widget.onChanged(_collect());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What do you specialize in?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Pick all that apply, or add your own below.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final option in kSpecializationOptions)
              FilterChip(
                label: Text(option),
                selected: _selected.contains(option),
                onSelected: widget.enabled
                    ? (selected) {
                        setState(() {
                          if (selected) {
                            _selected.add(option);
                          } else {
                            _selected.remove(option);
                          }
                        });
                        _emit();
                      }
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otherController,
          enabled: widget.enabled,
          decoration: const InputDecoration(
            labelText: 'Other (optional)',
            hintText: 'e.g. Bridal veils, Leather goods',
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _emit(),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
