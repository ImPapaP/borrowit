import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/equipment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/local_image_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// Longest borrowing period a student can choose.
const int maxBorrowDays = 30;

/// How far ahead a student can reserve.
const int maxDaysAhead = 180;

/// The borrow request form: equipment, date needed, return date, purpose and
/// an optional photo from the camera or gallery (saved on the phone).
class BorrowRequestScreen extends StatefulWidget {
  const BorrowRequestScreen({super.key, required this.equipment});

  final Equipment equipment;

  @override
  State<BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<BorrowRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  DateTime? _dateNeeded;
  DateTime? _returnDate;
  XFile? _photo;
  Uint8List? _photoBytes; // for the preview; works on phones and the web
  bool _showDateErrors = false;
  bool _submitting = false;

  DateTime get _today => dateOnly(DateTime.now());

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickDateNeeded() async {
    final picked = await showDatePicker(
      context: context,
      helpText: 'Date needed',
      initialDate: _dateNeeded ?? _today,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: maxDaysAhead)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateNeeded = picked;
      final returnDate = _returnDate;
      if (returnDate != null &&
          (returnDate.isBefore(picked) ||
              returnDate.difference(picked).inDays > maxBorrowDays)) {
        _returnDate = null;
      }
    });
  }

  Future<void> _pickReturnDate() async {
    final first = _dateNeeded ?? _today;
    final current = _returnDate;
    final picked = await showDatePicker(
      context: context,
      helpText: 'Return date',
      initialDate:
          (current != null && !current.isBefore(first)) ? current : first,
      firstDate: first,
      lastDate: first.add(const Duration(days: maxBorrowDays)),
    );
    if (picked == null || !mounted) return;
    setState(() => _returnDate = picked);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await LocalImageService.instance.pick(source);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = picked;
        _photoBytes = bytes;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      final where = source == ImageSource.camera ? 'camera' : 'gallery';
      _showMessage('Could not open the $where: ${error.message ?? error.code}');
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState!.validate();
    final dateNeeded = _dateNeeded;
    final returnDate = _returnDate;
    if (dateNeeded == null || returnDate == null) {
      setState(() => _showDateErrors = true);
    }
    if (!formValid || dateNeeded == null || returnDate == null) return;

    final user = AuthService.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    String? savedFileName;
    try {
      // 1. Save the photo on this device (nothing is uploaded).
      final photo = _photo;
      if (photo != null) {
        savedFileName = await LocalImageService.instance.saveToDevice(photo);
      }

      // 2. Save the request in Firestore with just the photo's file name.
      await FirestoreService.instance.submitRequest(
        userId: user.uid,
        equipment: widget.equipment,
        dateNeeded: dateNeeded,
        returnDate: returnDate,
        purpose: _purpose.text.trim(),
        imageFileName: savedFileName,
      );

      if (!mounted) return;
      _showMessage(
        'Request for ${widget.equipment.name} submitted. '
        'Track it in My Requests.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (savedFileName != null) {
        await LocalImageService.instance.delete(savedFileName);
      }
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Could not submit the request: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final equipment = widget.equipment;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Equipment being requested
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: EquipmentImage(equipment.image, width: 64, height: 64),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(equipment.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            equipment.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AvailabilityBadge(equipment),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const SectionLabel('When do you need it?'),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Date needed',
                    value: _dateNeeded,
                    showError: _showDateErrors && _dateNeeded == null,
                    onTap: _pickDateNeeded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Return date',
                    value: _returnDate,
                    showError: _showDateErrors && _returnDate == null,
                    onTap: _pickReturnDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const SectionLabel('Purpose'),
            TextFormField(
              controller: _purpose,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Group report presentation for IT 301',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().length < 5)
                  ? 'Please describe the purpose (at least 5 characters).'
                  : null,
            ),
            const SizedBox(height: 12),

            const SectionLabel('Attach a photo (optional)'),
            Text(
              'For example, your school ID or a signed request letter. '
              'The photo is saved on this device only.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_photoBytes == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              )
            else
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _photoBytes!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Remove photo',
                      onPressed: _submitting
                          ? null
                          : () => setState(() {
                                _photo = null;
                                _photoBytes = null;
                              }),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.showError,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final bool showError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: showError ? 'Required' : null,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value == null ? '' : formatDate(value)),
      ),
    );
  }
}
