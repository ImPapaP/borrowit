import 'package:flutter/material.dart';

import '../../models/borrow_request.dart';
import '../../services/firestore_service.dart';
import '../../services/local_image_service.dart';
import '../../services/notification_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/request_widgets.dart';

/// Everything about one request: status progress, dates, purpose, the photo
/// saved on the phone, a custom reminder, and cancelling while Pending.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late final Stream<BorrowRequest?> _request =
      FirestoreService.instance.requestById(widget.requestId);
  bool _cancelling = false;

  void _showMessage(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), action: action),
    );
  }

  Future<void> _cancel(BorrowRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: Text(
          'Your request for ${request.equipmentName} will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _cancelling = true);
    try {
      await FirestoreService.instance.cancelRequest(request.id);
      await LocalImageService.instance.delete(request.imageFileName);
      await NotificationService.instance.cancelReminders(request.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Request cancelled.')));
    } catch (error) {
      if (mounted) setState(() => _cancelling = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not cancel the request: $error')),
      );
    }
  }

  Future<void> _setReminder(BorrowRequest request) async {
    final now = DateTime.now();
    final firstDate = dateOnly(now);
    final lastDate = firstDate.add(const Duration(days: 365));
    final suggestedDay = request.status == RequestStatus.borrowed
        ? request.returnDate
        : request.dateNeeded;
    var initialDate = dateOnly(suggestedDay ?? now);
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final day = await showDatePicker(
      context: context,
      helpText: 'Remind me on',
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (day == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      helpText: 'Remind me at',
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(minutes: 2)),
      ),
    );
    if (time == null || !mounted) return;

    final when = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (!when.isAfter(DateTime.now())) {
      _showMessage('Please pick a time in the future.');
      return;
    }

    final notifications = NotificationService.instance;
    final scheduled = await notifications.scheduleCustomReminder(request, when);
    if (!mounted) return;
    if (!scheduled) {
      _showMessage(
        'Could not set the reminder. Check that notifications are allowed '
        'for BorrowIT.',
      );
      return;
    }

    final exact = await notifications.canScheduleExact();
    if (!mounted) return;
    if (exact) {
      _showMessage('Reminder set for ${formatDateTime(when)}.');
    } else {
      _showMessage(
        'Reminder set for ${formatDateTime(when)}. It may arrive a few '
        'minutes late.',
        action: SnackBarAction(
          label: 'Make exact',
          onPressed: notifications.requestExactAlarms,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request details')),
      body: StreamBuilder<BorrowRequest?>(
        stream: _request,
        builder: (context, snapshot) {
          if (_cancelling) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MessageView(
              icon: Icons.error_outline,
              title: 'Could not load this request',
              message: '${snapshot.error}',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final request = snapshot.data;
          if (request == null) {
            return const MessageView(
              icon: Icons.search_off,
              title: 'Request not found',
              message: 'It may have been cancelled.',
            );
          }
          return _buildDetails(context, request);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, BorrowRequest request) {
    final theme = Theme.of(context);
    // Reminders need phone notifications, so they're hidden on the web.
    final canRemind = NotificationService.instance.canSchedule &&
        (request.status == RequestStatus.pending ||
            request.status == RequestStatus.approved ||
            request.status == RequestStatus.borrowed);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: EquipmentImage(
                request.equipmentImage,
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.equipmentName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (request.equipmentCategory.isNotEmpty)
                    Text(
                      request.equipmentCategory,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),
                  StatusChip(request.status),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StatusTimeline(status: request.status),
        if (request.remarks != null) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.comment_outlined),
              title: const Text('Note from staff'),
              subtitle: Text(request.remarks!),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const SectionLabel('Request'),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Date needed'),
                subtitle: Text(formatDate(request.dateNeeded)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text('Return date'),
                subtitle: Text(formatDate(request.returnDate)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('Purpose'),
                subtitle: Text(request.purpose.isEmpty ? '—' : request.purpose),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Submitted'),
                subtitle: Text(formatDateTime(request.createdAt)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Attached photo'),
        if (request.hasPhoto)
          LocalRequestImage(fileName: request.imageFileName!)
        else
          Text(
            'No photo attached.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (canRemind) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _setReminder(request),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.alarm_add),
            label: const Text('Set a reminder'),
          ),
        ],
        if (request.status == RequestStatus.pending) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _cancel(request),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel request'),
          ),
        ],
      ],
    );
  }
}
