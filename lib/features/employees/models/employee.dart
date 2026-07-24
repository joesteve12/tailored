import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee.freezed.dart';
part 'employee.g.dart';

/// Mirrors the backend EmployeeResponse. `name` and `phone` are the only
/// required fields on create (EmployeeCreate); `specialty` and `notes` are
/// nullable. Employees are login-less directory records — soft-deleted via
/// `isActive` rather than hard-deleted, so historical assignments stay
/// meaningful.
@freezed
class Employee with _$Employee {
  const factory Employee({
    required String id,
    required String name,
    required String phone,
    String? specialty,
    @JsonKey(name: 'is_active') required bool isActive,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Employee;

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
}
