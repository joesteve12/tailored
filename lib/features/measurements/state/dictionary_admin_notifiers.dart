import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_field.dart';
import '../models/measurement_template.dart';
import 'measurement_dictionary_providers.dart';

/// State for the measurement-dictionary editors under Settings.
///
/// These are deliberately SEPARATE from `measurementFieldsProvider` and
/// `measurementTemplatesProvider`. Those two are active-only and are consumed
/// by the capture form, the ad-hoc field picker, the history screen and the
/// order snapshot picker — surfaces that must never see an archived field.
/// Giving them a mutable "show archived" toggle so Settings could reuse them
/// would leak archived fields straight into a capture form the moment an owner
/// flipped the filter on another screen.
///
/// So: Settings owns its own notifiers with the toggle, and every mutation
/// calls [invalidateMeasurementDictionary] to push the change out to the
/// read-only providers the rest of the app uses.

class FieldAdminListNotifier extends AsyncNotifier<List<MeasurementField>> {
  bool _showArchived = false;

  bool get showArchived => _showArchived;

  @override
  Future<List<MeasurementField>> build() async {
    final currentUserId = ref.read(authStateProvider).valueOrNull?.id;
    if (currentUserId == null) return const [];
    return _fetch();
  }

  Future<List<MeasurementField>> _fetch() {
    return ref
        .read(measurementRepositoryProvider)
        .listFields(includeArchived: _showArchived);
  }

  /// Re-runs the current view. Call after any create/update/delete.
  Future<void> refresh() async {
    state = const AsyncLoading<List<MeasurementField>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setShowArchived(bool value) async {
    if (_showArchived == value) return;
    _showArchived = value;
    await refresh();
  }
}

final fieldAdminListProvider =
    AsyncNotifierProvider<FieldAdminListNotifier, List<MeasurementField>>(
  FieldAdminListNotifier.new,
);

class TemplateAdminListNotifier extends AsyncNotifier<List<MeasurementTemplate>> {
  bool _showArchived = false;

  bool get showArchived => _showArchived;

  @override
  Future<List<MeasurementTemplate>> build() async {
    final currentUserId = ref.read(authStateProvider).valueOrNull?.id;
    if (currentUserId == null) return const [];
    return _fetch();
  }

  Future<List<MeasurementTemplate>> _fetch() {
    return ref
        .read(measurementRepositoryProvider)
        .listTemplates(includeArchived: _showArchived);
  }

  Future<void> refresh() async {
    state =
        const AsyncLoading<List<MeasurementTemplate>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setShowArchived(bool value) async {
    if (_showArchived == value) return;
    _showArchived = value;
    await refresh();
  }
}

final templateAdminListProvider = AsyncNotifierProvider<TemplateAdminListNotifier,
    List<MeasurementTemplate>>(
  TemplateAdminListNotifier.new,
);

/// A single field by id — deep-link safe, so the edit screen works on a cold
/// start without the list being in memory. Same pattern as employeeByIdProvider.
final fieldByIdProvider =
    FutureProvider.family<MeasurementField, String>((ref, id) async {
  return ref.read(measurementRepositoryProvider).getField(id);
});

/// A single template with its fields, by id.
final templateByIdProvider =
    FutureProvider.family<MeasurementTemplate, String>((ref, id) async {
  return ref.read(measurementRepositoryProvider).getTemplate(id);
});

/// Which templates use each field: `fieldId -> [template names]`.
///
/// This is what lets the field editor say "Used in Agbada, Gown, Suit / Blazer"
/// before you archive or delete something — and it costs nothing extra, because
/// the template list already ships its field rows inline. Archived templates are
/// included on purpose: a field is still "in use" by a template you might
/// un-archive tomorrow, and finding that out afterwards is worse.
final fieldTemplateUsageProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
  final templates = await ref
      .read(measurementRepositoryProvider)
      .listTemplates(includeArchived: true);
  final usage = <String, List<String>>{};
  for (final t in templates) {
    for (final f in t.fields) {
      usage.putIfAbsent(f.fieldId, () => <String>[]).add(t.name);
    }
  }
  return usage;
});

/// Push a dictionary change out to every surface that reads it.
///
/// Call this after ANY field or template mutation. The capture form, the
/// snapshot picker and the history screen all read the active-only providers
/// and none of them are autoDispose — without this, renaming a field in
/// Settings would leave the old label sitting in the capture form until the app
/// was restarted.
void invalidateMeasurementDictionary(WidgetRef ref) {
  ref.invalidate(measurementFieldsProvider);
  ref.invalidate(measurementTemplatesProvider);
  ref.invalidate(fieldByIdProvider);
  ref.invalidate(templateByIdProvider);
  ref.invalidate(fieldTemplateUsageProvider);
}
