import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/measurement_repository.dart';
import '../models/measurement_field.dart';
import '../models/measurement_template.dart';

/// The shop's measurement dictionary and templates. Per-tenant (not keyed by a
/// record id), so AuthStateNotifier invalidates both on login/logout. Read-only
/// here — the capture form consumes them to render inputs and offer templates.
/// (Field/template *editing* under Settings is a later increment.)
final measurementFieldsProvider =
    FutureProvider<List<MeasurementField>>((ref) async {
  return ref.read(measurementRepositoryProvider).listFields();
});

final measurementTemplatesProvider =
    FutureProvider<List<MeasurementTemplate>>((ref) async {
  return ref.read(measurementRepositoryProvider).listTemplates();
});
