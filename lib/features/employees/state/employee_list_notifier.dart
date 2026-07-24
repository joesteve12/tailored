import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../data/employee_repository.dart';
import '../models/employee.dart';

/// Backs the Employees list under Settings. The backend returns a plain
/// array (no pagination envelope), so this is a simple AsyncNotifier over a
/// List<Employee> with a refresh() — same convention every other notifier in
/// this codebase exposes so screens can drive AsyncErrorView retries.
///
/// Defaults to active employees only; [setShowInactive] flips to listing all
/// (active + deactivated) so the owner can find and reactivate someone.
class EmployeeListNotifier extends AsyncNotifier<List<Employee>> {
  bool _showInactive = false;

  bool get showInactive => _showInactive;

  @override
  Future<List<Employee>> build() async {
    final currentUserId = ref.read(authStateProvider).valueOrNull?.id;
    if (currentUserId == null) return const [];
    return _fetch();
  }

  Future<List<Employee>> _fetch() {
    // active:true → active only; active:null → all (active + inactive).
    return ref
        .read(employeeRepositoryProvider)
        .list(active: _showInactive ? null : true);
  }

  /// Re-runs the current view. Call after create/update/deactivate elsewhere.
  Future<void> refresh() async {
    state = const AsyncLoading<List<Employee>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setShowInactive(bool value) async {
    if (_showInactive == value) return;
    _showInactive = value;
    await refresh();
  }
}

final employeeListProvider =
    AsyncNotifierProvider<EmployeeListNotifier, List<Employee>>(
  EmployeeListNotifier.new,
);
