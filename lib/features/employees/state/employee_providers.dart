import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employee_repository.dart';
import '../models/employee.dart';
import '../models/employee_workload_item.dart';

/// A single employee by id. Read-only — mutations go through the form (which
/// calls the repository directly), then invalidate this so the detail screen
/// refetches. Deep-link safe: doesn't depend on the list being loaded.
final employeeByIdProvider =
    FutureProvider.family<Employee, String>((ref, id) async {
  return ref.read(employeeRepositoryProvider).getById(id);
});

/// An employee's workload (task stages assigned to them). Invalidate
/// alongside [employeeByIdProvider] after an edit, or pull-to-refresh.
final employeeWorkloadProvider =
    FutureProvider.family<List<EmployeeWorkloadItem>, String>((ref, id) async {
  return ref.read(employeeRepositoryProvider).workload(id);
});

/// The active employees, for populating assignment dropdowns on the order-item
/// screen. Deliberately separate from [employeeListProvider] (which the
/// Employees settings screen owns and whose active/all filter the owner can
/// toggle): assignment dropdowns always want *assignable* staff, regardless of
/// what filter the list screen happens to be showing. A `FutureProvider` keeps
/// it auto-disposing and refetch-on-demand; the assignment editor reads it
/// once per open.
final activeEmployeesProvider =
    FutureProvider<List<Employee>>((ref) async {
  return ref.read(employeeRepositoryProvider).list(active: true);
});
