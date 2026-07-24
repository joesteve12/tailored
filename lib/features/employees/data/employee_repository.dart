import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/employee.dart';
import '../models/employee_workload_item.dart';

class EmployeeRepository {
  EmployeeRepository(this._dio);

  final Dio _dio;

  /// GET /employees?active=...
  /// Returns a plain JSON array (no {results} envelope), unlike clients/orders.
  /// Pass [active] = true to list only active employees, false for inactive,
  /// or null for all.
  Future<List<Employee>> list({bool? active}) async {
    final response = await _dio.get('/employees', queryParameters: {
      if (active != null) 'active': active,
    });
    return (response.data as List)
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Employee> getById(String id) async {
    final response = await _dio.get('/employees/$id');
    return Employee.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Employee> create({
    required String name,
    required String phone,
    String? specialty,
    String? notes,
  }) async {
    final response = await _dio.post('/employees', data: {
      'name': name,
      'phone': phone,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Employee.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /employees/{id} — only sends fields that were passed in. The
  /// backend's EmployeeUpdate makes every field optional and only touches
  /// what's present. `isActive` is included here so the form's active toggle
  /// (and reactivating a previously deactivated employee) works through the
  /// same call.
  Future<Employee> update(
    String id, {
    String? name,
    String? phone,
    String? specialty,
    bool? isActive,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (specialty != null) 'specialty': specialty,
      if (isActive != null) 'is_active': isActive,
      if (notes != null) 'notes': notes,
    };
    final response = await _dio.patch('/employees/$id', data: data);
    return Employee.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /employees/{id} is a soft delete on the backend (sets
  /// is_active=false), so this is "deactivate", not a hard removal.
  Future<void> deactivate(String id) async {
    await _dio.delete('/employees/$id');
  }

  /// GET /employees/{id}/workload — every task stage ever assigned to
  /// them (the endpoint was renamed with the Task system; the old
  /// /assignments path is gone).
  Future<List<EmployeeWorkloadItem>> workload(String id) async {
    final response = await _dio.get('/employees/$id/workload');
    return (response.data as List)
        .map((e) => EmployeeWorkloadItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(dioProvider));
});
