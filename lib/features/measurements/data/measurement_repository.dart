import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/models/recipient_ref.dart';
import '../models/measurement_field.dart';
import '../models/measurement_set.dart';
import '../models/measurement_template.dart';

/// Request-building helper for a single value in a set — mirrors the backend
/// MeasurementValueCreate. Not a response model; only ever needs toJson().
/// `unit` is intentionally omitted on the wire: the backend defaults it to the
/// field's own unit, which is what we want, so there's no unit picker in the
/// capture UI for v1.
class MeasurementValueInput {
  const MeasurementValueInput({
    required this.fieldId,
    this.valueNumber,
    this.valueText,
  });

  final String fieldId;
  final double? valueNumber;
  final String? valueText;

  Map<String, dynamic> toJson() => {
        'field_id': fieldId,
        if (valueNumber != null) 'value_number': valueNumber,
        if (valueText != null && valueText!.isNotEmpty) 'value_text': valueText,
      };
}

/// Request-building helper for one row of a template's field list — mirrors the
/// backend TemplateFieldCreate. `sortOrder` is the position the capture form
/// lays the field out in (send the list index); `isRequired` is enforced
/// server-side when a set is created against the template.
class TemplateFieldInput {
  const TemplateFieldInput({
    required this.fieldId,
    required this.sortOrder,
    required this.isRequired,
  });

  final String fieldId;
  final int sortOrder;
  final bool isRequired;

  Map<String, dynamic> toJson() => {
        'field_id': fieldId,
        'sort_order': sortOrder,
        'is_required': isRequired,
      };
}

class MeasurementRepository {
  MeasurementRepository(this._dio);

  final Dio _dio;

  // ── Dictionary (fields) ─────────────────────────────────────────────────
  /// GET /measurements/fields — active (non-archived) fields by default.
  /// The capture form and the ad-hoc field picker always want the default;
  /// only the Settings dictionary screen passes [includeArchived].
  Future<List<MeasurementField>> listFields({bool includeArchived = false}) async {
    final response = await _dio.get(
      '/measurements/fields',
      queryParameters: {if (includeArchived) 'include_archived': true},
    );
    return (response.data as List)
        .map((e) => MeasurementField.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MeasurementField> getField(String id) async {
    final response = await _dio.get('/measurements/fields/$id');
    return MeasurementField.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /measurements/fields.
  ///
  /// No `key` is sent: the backend derives it from the label, and keeps it in
  /// sync when the label is later renamed — the key is an internal uniqueness
  /// handle, never a user-facing concept. `value_type` is not sent either: it
  /// defaults to "number", and the app no longer creates text fields
  /// (non-numeric instruction lives in a measurement set's `notes`, which
  /// prints on the work order).
  Future<MeasurementField> createField({
    required String label,
    required String unit,
    String? description,
  }) async {
    final response = await _dio.post('/measurements/fields', data: {
      'label': label,
      'unit': unit,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return MeasurementField.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /measurements/fields/{id}. Only sends what's passed; the backend's
  /// MeasurementFieldUpdate is fully optional and uses exclude_unset.
  ///
  /// `key` is absent by design — it isn't updatable server-side, so the form
  /// locks it once the field exists. Passing [isArchived] is how a field is
  /// retired: it disappears from the dictionary, from the ad-hoc picker and
  /// from capture forms, while every historical value it holds keeps rendering.
  Future<MeasurementField> updateField(
    String id, {
    String? label,
    String? unit,
    String? description,
    bool? isArchived,
  }) async {
    final response = await _dio.put('/measurements/fields/$id', data: {
      if (label != null) 'label': label,
      if (unit != null) 'unit': unit,
      if (description != null) 'description': description,
      if (isArchived != null) 'is_archived': isArchived,
    });
    return MeasurementField.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /measurements/fields/{id} — a genuine hard delete, not a soft one.
  ///
  /// The backend refuses with a 400 the moment any measurement has been
  /// captured against the field ("Archive it instead"), so in practice this
  /// only ever removes fields nobody has used yet: typos, mostly. It DOES strip
  /// the field out of every template referencing it — warn first.
  Future<void> deleteField(String id) async {
    await _dio.delete('/measurements/fields/$id');
  }

  // ── Templates ───────────────────────────────────────────────────────────
  /// GET /measurements/templates — active templates with their fields.
  Future<List<MeasurementTemplate>> listTemplates({
    bool includeArchived = false,
  }) async {
    final response = await _dio.get(
      '/measurements/templates',
      queryParameters: {if (includeArchived) 'include_archived': true},
    );
    return (response.data as List)
        .map((e) => MeasurementTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MeasurementTemplate> getTemplate(String id) async {
    final response = await _dio.get('/measurements/templates/$id');
    return MeasurementTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MeasurementTemplate> createTemplate({
    required String name,
    String? garmentType,
    String? description,
    required List<TemplateFieldInput> fields,
  }) async {
    final response = await _dio.post('/measurements/templates', data: {
      'name': name,
      if (garmentType != null && garmentType.isNotEmpty) 'garment_type': garmentType,
      if (description != null && description.isNotEmpty) 'description': description,
      'fields': fields.map((f) => f.toJson()).toList(),
    });
    return MeasurementTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /measurements/templates/{id}.
  ///
  /// Sending [fields] REPLACES the template's whole field list — the backend
  /// drops every existing TemplateField row and re-inserts what you send. So
  /// the editor builds the complete list and saves once; there's no per-row
  /// endpoint and there doesn't need to be. This can't corrupt history:
  /// captured values reference `field_id`, never a template_field row.
  Future<MeasurementTemplate> updateTemplate(
    String id, {
    String? name,
    String? garmentType,
    String? description,
    bool? isArchived,
    List<TemplateFieldInput>? fields,
  }) async {
    final response = await _dio.put('/measurements/templates/$id', data: {
      if (name != null) 'name': name,
      if (garmentType != null) 'garment_type': garmentType,
      if (description != null) 'description': description,
      if (isArchived != null) 'is_archived': isArchived,
      if (fields != null) 'fields': fields.map((f) => f.toJson()).toList(),
    });
    return MeasurementTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /measurements/templates/{id}. The backend 400s if any measurement
  /// set was captured under this template — archive it instead. The editor
  /// catches that and offers exactly that.
  Future<void> deleteTemplate(String id) async {
    await _dio.delete('/measurements/templates/$id');
  }

  // ── Sets ────────────────────────────────────────────────────────────────
  /// GET /measurements/sets/client|guest/{id} — newest first, no pagination.
  Future<List<MeasurementSet>> listForClient(String clientId) async {
    final response = await _dio.get('/measurements/sets/client/$clientId');
    return (response.data as List)
        .map((e) => MeasurementSet.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MeasurementSet>> listForGuest(String guestId) async {
    final response = await _dio.get('/measurements/sets/guest/$guestId');
    return (response.data as List)
        .map((e) => MeasurementSet.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MeasurementSet>> listFor(RecipientRef recipient) {
    return recipient.isClient
        ? listForClient(recipient.id)
        : listForGuest(recipient.id);
  }

  Future<MeasurementSet> getSet(String id) async {
    final response = await _dio.get('/measurements/sets/$id');
    return MeasurementSet.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /measurements/sets. Exactly one of [clientId] / [guestRecipientId]
  /// must be set (the recipient is pinned by the launching screen). Required
  /// fields are enforced server-side on create.
  Future<MeasurementSet> createSet({
    String? clientId,
    String? guestRecipientId,
    String? templateId,
    String? label,
    String? notes,
    required List<MeasurementValueInput> values,
  }) async {
    final response = await _dio.post('/measurements/sets', data: {
      if (clientId != null) 'client_id': clientId,
      if (guestRecipientId != null) 'guest_recipient_id': guestRecipientId,
      if (templateId != null) 'template_id': templateId,
      if (label != null && label.isNotEmpty) 'label': label,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'values': values.map((v) => v.toJson()).toList(),
    });
    return MeasurementSet.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /measurements/sets/{id}. Sending `values` replaces the whole value
  /// list; the backend does NOT re-enforce template required-fields on update,
  /// so partial corrections are allowed.
  Future<MeasurementSet> updateSet(
    String id, {
    String? templateId,
    String? label,
    String? notes,
    List<MeasurementValueInput>? values,
  }) async {
    final data = <String, dynamic>{
      if (templateId != null) 'template_id': templateId,
      if (label != null) 'label': label,
      if (notes != null) 'notes': notes,
      if (values != null) 'values': values.map((v) => v.toJson()).toList(),
    };
    final response = await _dio.put('/measurements/sets/$id', data: data);
    return MeasurementSet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSet(String id) async {
    await _dio.delete('/measurements/sets/$id');
  }
}

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepository(ref.watch(dioProvider));
});
