import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/borrow_request.dart';
import '../services/local_image_service.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'common.dart';

/// One row in "My Requests" and "History".
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, this.onTap});

  final BorrowRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: EquipmentImage(
                  request.equipmentImage,
                  width: 64,
                  height: 64,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.equipmentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateRange(request.dateNeeded, request.returnDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(request.status),
                        if (request.hasPhoto) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.photo_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a photo saved on this device by LocalImageService.
/// Tap it to view full screen.
class LocalRequestImage extends StatefulWidget {
  const LocalRequestImage({
    super.key,
    required this.fileName,
    this.equipmentName,
    this.date,
    this.height = 220,
  });

  final String fileName;

  /// Used to name the file when the student saves a copy to Downloads
  /// (website only). Leave null to hide the "Save to Downloads" button.
  final String? equipmentName;
  final DateTime? date;

  final double height;

  @override
  State<LocalRequestImage> createState() => _LocalRequestImageState();
}

class _LocalRequestImageState extends State<LocalRequestImage> {
  late Future<Uint8List?> _photo;

  @override
  void initState() {
    super.initState();
    _photo = LocalImageService.instance.load(widget.fileName);
  }

  @override
  void didUpdateWidget(covariant LocalRequestImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName) {
      _photo = LocalImageService.instance.load(widget.fileName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List?>(
      future: _photo,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.image_not_supported_outlined,
                    color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'The photo isn\'t on this device. It was saved on the '
                    'device used to submit the request.',
                  ),
                ),
              ],
            ),
          );
        }
        final photo = GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _FullScreenPhoto(bytes: bytes),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              height: widget.height,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        );

        final equipmentName = widget.equipmentName;
        if (equipmentName == null ||
            !LocalImageService.instance.canSaveToDownloads) {
          return photo;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            photo,
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _saveToDownloads(bytes, equipmentName),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Save to Downloads'),
            ),
          ],
        );
      },
    );
  }

  void _saveToDownloads(Uint8List bytes, String equipmentName) {
    final saved = LocalImageService.instance.saveCopyToDownloads(
      bytes,
      equipmentName: equipmentName,
      date: widget.date,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Photo sent to your Downloads.'
              : 'This browser didn\'t allow the download. Try another browser.',
        ),
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Attached photo'),
      ),
      body: Center(
        child: InteractiveViewer(child: Image.memory(bytes)),
      ),
    );
  }
}

/// Pending → Approved → Borrowed → Returned progress bar.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.status});

  final RequestStatus status;

  static const List<RequestStatus> _steps = [
    RequestStatus.pending,
    RequestStatus.approved,
    RequestStatus.borrowed,
    RequestStatus.returned,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (status == RequestStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.block_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This request was rejected.',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final current = _steps.indexOf(status);
    final active = statusColor(status, scheme);
    final inactive = scheme.outlineVariant;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            for (var i = 0; i < _steps.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            color: i == 0
                                ? Colors.transparent
                                : (i <= current ? active : inactive),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= current ? active : inactive,
                          ),
                          child: Icon(
                            i < current ? Icons.check : statusIcon(_steps[i]),
                            size: 16,
                            color: i <= current
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 3,
                            color: i == _steps.length - 1
                                ? Colors.transparent
                                : (i < current ? active : inactive),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _steps[i].label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            i == current ? FontWeight.w700 : FontWeight.w400,
                        color: i <= current
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
