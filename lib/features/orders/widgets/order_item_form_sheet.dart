import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/utils/fabric_labels.dart';
import '../../../core/utils/pick_image.dart';
import '../data/order_repository.dart';
import '../models/fabric.dart';
import '../models/order_item.dart';
import '../models/style_reference.dart';
import 'measurement_snapshot_picker.dart';
import 'recipient_picker.dart';

import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';
/// A single fabric being drafted on a not-yet-created item. Holds its own
/// controllers and (optionally) a staged image. Because the item doesn't exist
/// yet, the image is uploaded to the staging endpoint here and the URL rides
/// along in the built [FabricInput].
class _FabricDraft {
  final detailsController = TextEditingController();
  final quantityController = TextEditingController();
  String unit = 'yards';
  StagedUpload? image;
  bool uploading = false;

  void disposeControllers() {
    detailsController.dispose();
    quantityController.dispose();
  }

  FabricInput toInput() => FabricInput(
        details: detailsController.text.trim(),
        imageUrl: image?.url,
        imageFileId: image?.fileId,
        quantity: double.tryParse(quantityController.text.trim()),
        unit: unit,
      );
}

/// Builds a single [OrderItemInput] for a not-yet-created item — used both for
/// items on a brand-new order (accumulated locally by the order form) and for
/// adding an item to an existing order (the detail screen passes the returned
/// input straight to OrderDetailNotifier.addItem).
///
/// A garment can be cut from several fabrics, so this collects a list of fabric
/// drafts. Each fabric's image and any style references are uploaded to the
/// staging endpoints *here*, on pick, and the resulting URLs ride along in the
/// returned input. Returns the input via Navigator.pop, or null if dismissed.
class OrderItemFormSheet extends ConsumerStatefulWidget {
  const OrderItemFormSheet({super.key, required this.clientId});

  final String clientId;

  @override
  ConsumerState<OrderItemFormSheet> createState() =>
      _OrderItemFormSheetState();
}

class _OrderItemFormSheetState extends ConsumerState<OrderItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _garmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  late RecipientRef _recipient;
  String? _measurementSetId;
  final List<_FabricDraft> _fabrics = [];
  final List<StagedUpload> _styleRefs = [];

  bool _uploadingStyle = false;

  /// Set just before popping with a built input: tells dispose() that the
  /// staged files are now owned by the returned item (the order form will
  /// clean them up if needed), so they must NOT be deleted here.
  bool _confirmed = false;

  /// Captured once so dispose() — which can't safely touch `ref` — can still
  /// fire orphan-cleanup deletes.
  late final OrderRepository _repo;

  bool get _anyUploading =>
      _uploadingStyle || _fabrics.any((f) => f.uploading);

  @override
  void initState() {
    super.initState();
    _recipient = clientRecipient(widget.clientId);
    _repo = ref.read(orderRepositoryProvider);
  }

  @override
  void dispose() {
    // If the sheet is dismissed without confirming, any staged fabric images
    // and style references were uploaded but never attached — delete them so
    // they don't orphan. Fire-and-forget; deleteStagedFile swallows its errors.
    if (!_confirmed) {
      for (final f in _fabrics) {
        final img = f.image;
        if (img != null) _repo.deleteStagedFile(img.fileId);
      }
      for (final s in _styleRefs) {
        _repo.deleteStagedFile(s.fileId);
      }
    }
    for (final f in _fabrics) {
      f.disposeControllers();
    }
    _garmentController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addFabricDraft() {
    setState(() => _fabrics.add(_FabricDraft()));
  }

  void _removeFabricDraft(int index) {
    final draft = _fabrics[index];
    final img = draft.image;
    if (img != null) _repo.deleteStagedFile(img.fileId);
    setState(() => _fabrics.removeAt(index));
    draft.disposeControllers();
  }

  Future<void> _pickFabricImage(_FabricDraft draft) async {
    final file = await pickImageFile(context);
    if (file == null || !mounted) return;
    setState(() => draft.uploading = true);
    try {
      final staged =
          await _repo.uploadStagingImage(file, folder: 'fabrics');
      // A replaced image leaves the previous staged file orphaned — clean it.
      final old = draft.image;
      if (old != null) _repo.deleteStagedFile(old.fileId);
      if (mounted) setState(() => draft.image = staged);
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Fabric image upload failed');
      }
    } finally {
      if (mounted) setState(() => draft.uploading = false);
    }
  }

  void _clearFabricImage(_FabricDraft draft) {
    final old = draft.image;
    setState(() => draft.image = null);
    if (old != null) _repo.deleteStagedFile(old.fileId);
  }

  Future<void> _addStyleRef() async {
    final file = await pickImageFile(context);
    if (file == null || !mounted) return;
    setState(() => _uploadingStyle = true);
    try {
      final staged =
          await _repo.uploadStagingMedia(file, folder: 'styles');
      if (mounted) setState(() => _styleRefs.add(staged));
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Style reference upload failed');
      }
    } finally {
      if (mounted) setState(() => _uploadingStyle = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // The staged files now travel with the returned item; don't let dispose
    // delete them.
    _confirmed = true;
    Navigator.pop(
      context,
      OrderItemInput(
        garmentType: _garmentController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        unitPrice: double.parse(_priceController.text.trim()),
        fabrics: [for (final d in _fabrics) d.toInput()],
        recipient: _recipient,
        notes: _notesController.text.trim(),
        measurementSetId: _measurementSetId,
        styleReferences: [
          for (final s in _styleRefs)
            StyleReferenceInput(
              fileUrl: s.url,
              fileId: s.fileId,
              fileType: s.fileType,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add outfit', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _garmentController,
                decoration: const InputDecoration(labelText: 'Garment type'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return (n == null || n < 1) ? 'Invalid' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Unit price'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        // Backend requires unit_price > 0.
                        return (n == null || n <= 0) ? 'Invalid' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _FabricsEditor(
                fabrics: _fabrics,
                onAdd: _addFabricDraft,
                onRemoveAt: _removeFabricDraft,
                onPickImage: _pickFabricImage,
                onClearImage: _clearFabricImage,
                onUnitChanged: (draft, unit) =>
                    setState(() => draft.unit = unit),
              ),
              const SizedBox(height: 20),
              _StyleRefsRow(
                staged: _styleRefs,
                uploading: _uploadingStyle,
                onAdd: _addStyleRef,
                onRemoveAt: (i) {
                  final removed = _styleRefs[i];
                  setState(() => _styleRefs.removeAt(i));
                  _repo.deleteStagedFile(removed.fileId);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              RecipientPicker(
                clientId: widget.clientId,
                selected: _recipient,
                onChanged: (r) => setState(() {
                  _recipient = r;
                  // Sets belong to a specific recipient — a snapshot picked for
                  // the previous one no longer applies.
                  _measurementSetId = null;
                }),
              ),
              const SizedBox(height: 4),
              MeasurementSnapshotField(
                recipient: _recipient,
                selectedSetId: _measurementSetId,
                onChanged: (id) => setState(() => _measurementSetId = id),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _anyUploading ? null : _submit,
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The repeatable fabric editor for the create sheet: a card per fabric draft
/// (details, quantity + unit, a staged image) plus an "Add fabric" button.
/// Serials aren't shown here — they're generated server-side when the order is
/// saved, then visible on the order/fabric screens for tagging.
class _FabricsEditor extends StatelessWidget {
  const _FabricsEditor({
    required this.fabrics,
    required this.onAdd,
    required this.onRemoveAt,
    required this.onPickImage,
    required this.onClearImage,
    required this.onUnitChanged,
  });

  final List<_FabricDraft> fabrics;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;
  final ValueChanged<_FabricDraft> onPickImage;
  final ValueChanged<_FabricDraft> onClearImage;
  final void Function(_FabricDraft draft, String unit) onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Fabrics',
              style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 4),
        if (fabrics.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'A garment can be cut from one or more fabrics. Add each piece so '
              'it gets its own tag.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (var i = 0; i < fabrics.length; i++)
          _FabricDraftCard(
            index: i,
            draft: fabrics[i],
            onRemove: () => onRemoveAt(i),
            onPickImage: () => onPickImage(fabrics[i]),
            onClearImage: () => onClearImage(fabrics[i]),
            onUnitChanged: (u) => onUnitChanged(fabrics[i], u),
          ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add fabric'),
        ),
      ],
    );
  }
}

class _FabricDraftCard extends StatelessWidget {
  const _FabricDraftCard({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onPickImage,
    required this.onClearImage,
    required this.onUnitChanged,
  });

  final int index;
  final _FabricDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Fabric ${index + 1}',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                IconButton(
                  tooltip: 'Remove fabric',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            TextField(
              controller: draft.detailsController,
              decoration: const InputDecoration(
                labelText: 'Fabric details (optional)',
                hintText: 'e.g. navy wool',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: draft.unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [
                      for (final u in kFabricUnits)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) {
                      if (v != null) onUnitChanged(v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StagedImageRow(
              staged: draft.image,
              uploading: draft.uploading,
              onPick: onPickImage,
              onClear: onClearImage,
            ),
          ],
        ),
      ),
    );
  }
}

/// Staged fabric-image preview + pick/replace/remove for one draft.
class _StagedImageRow extends StatelessWidget {
  const _StagedImageRow({
    required this.staged,
    required this.uploading,
    required this.onPick,
    required this.onClear,
  });

  final StagedUpload? staged;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (staged != null)
          GestureDetector(
            onTap: () =>
                showImageViewer(context, urls: [staged!.url]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                staged!.url,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          )
        else
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: const Icon(Icons.image_outlined),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              if (uploading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                TextButton(
                  onPressed: onPick,
                  child: Text(staged == null ? 'Add image' : 'Replace'),
                ),
                if (staged != null)
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Remove'),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Staged style references strip for the create sheet.
class _StyleRefsRow extends StatelessWidget {
  const _StyleRefsRow({
    required this.staged,
    required this.uploading,
    required this.onAdd,
    required this.onRemoveAt,
  });

  final List<StagedUpload> staged;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Style references'),
            const SizedBox(width: 8),
            if (uploading)
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < staged.length; i++)
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () => showImageViewer(
                        context,
                        urls: [for (final s in staged) s.url],
                        initialIndex: i,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          staged[i].url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: CircleAvatar(
                          radius: 10,
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                          child: Icon(
                            Icons.close,
                            size: 13,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        onPressed: () => onRemoveAt(i),
                      ),
                    ),
                  ],
                ),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: uploading ? null : onAdd,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
