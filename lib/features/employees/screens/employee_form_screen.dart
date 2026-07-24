import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_error_view.dart';
import '../data/employee_repository.dart';
import '../state/employee_list_notifier.dart';
import '../state/employee_providers.dart';

import '../../../core/utils/errors.dart';
import '../../../core/widgets/feedback.dart';
/// Handles both create and edit. Pass [employeeId] to edit; omit to create.
/// On edit, the existing employee is fetched via employeeByIdProvider so the
/// screen is deep-link safe (doesn't rely on the list being in memory).
class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key, this.employeeId});

  final String? employeeId;

  bool get isEditing => employeeId != null;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isActive = true;
  bool _isSubmitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded({
    required String name,
    required String phone,
    String? specialty,
    String? notes,
    required bool isActive,
  }) {
    if (_prefilled) return;
    _nameController.text = name;
    _phoneController.text = phone;
    _specialtyController.text = specialty ?? '';
    _notesController.text = notes ?? '';
    _isActive = isActive;
    _prefilled = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(employeeRepositoryProvider);
      if (widget.isEditing) {
        await repo.update(
          widget.employeeId!,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          specialty: _specialtyController.text.trim(),
          isActive: _isActive,
          notes: _notesController.text.trim(),
        );
        ref.invalidate(employeeByIdProvider(widget.employeeId!));
        ref.invalidate(employeeWorkloadProvider(widget.employeeId!));
      } else {
        await repo.create(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          specialty: _specialtyController.text.trim(),
          notes: _notesController.text.trim(),
        );
      }
      await ref.read(employeeListProvider.notifier).refresh();
      if (mounted) {
        showSuccessSnackbar(
          context,
          widget.isEditing ? 'Employee updated' : 'Employee created',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          e,
          action: '${widget.isEditing ? 'Update' : 'Create'} failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildForm(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (WhatsApp)',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty (optional)',
                  hintText: 'e.g. stitching, embroidery, finishing',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text(
                    'Inactive employees can\'t be assigned new work',
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Save changes' : 'Add employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('New employee')),
        body: _buildForm(context),
      );
    }

    final employeeAsync = ref.watch(employeeByIdProvider(widget.employeeId!));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit employee')),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () async =>
              ref.invalidate(employeeByIdProvider(widget.employeeId!)),
        ),
        data: (employee) {
          _prefillIfNeeded(
            name: employee.name,
            phone: employee.phone,
            specialty: employee.specialty,
            notes: employee.notes,
            isActive: employee.isActive,
          );
          return _buildForm(context);
        },
      ),
    );
  }
}
