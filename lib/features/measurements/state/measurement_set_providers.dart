import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/measurement_repository.dart';
import '../models/measurement_set.dart';

/// A single measurement set by id (GET /measurements/sets/{id}). Backs the set
/// detail and edit screens; deep-link safe. Invalidate after an edit.
final measurementSetByIdProvider =
    FutureProvider.family<MeasurementSet, String>((ref, id) async {
  return ref.read(measurementRepositoryProvider).getSet(id);
});
