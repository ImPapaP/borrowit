import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/borrow_request.dart';
import '../utils/formatters.dart';

/// Local notifications (shown by the phone itself, no server needed):
///
///  * Status updates - "Request approved", "Equipment borrowed", ...
///  * Automatic reminders - 8:00 AM on the pick-up date (Approved) and on the
///    return date (Borrowed).
///  * Custom reminders - the student picks a date and time on the request
///    details screen.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _launchChecked = false;

  /// Set by HomeScreen. Called with a request id when a notification is tapped.
  void Function(String requestId)? onOpenRequest;

  /// Set by HomeScreen. Used instead of a phone notification when phone
  /// notifications aren't available (the web version), so the student still
  /// sees status changes as an in-app message.
  void Function(String title, String body, String requestId)? onInAppMessage;

  /// Whether reminders can be scheduled (phone app only).
  bool get canSchedule => _ready;

  /// Hour of the day (24h) for the automatic pick-up and return reminders.
  static const int reminderHour = 8;

  // Each request can have up to four notifications. Their ids are derived
  // from the request id plus one of these numbers.
  static const int _statusKind = 0;
  static const int _pickupKind = 1;
  static const int _returnKind = 2;
  static const int _customKind = 3;

  final NotificationDetails _statusDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'borrow_status',
      'Borrowing status',
      channelDescription: 'Updates when a borrow request changes status',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  final NotificationDetails _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'borrow_reminders',
      'Borrowing reminders',
      channelDescription: 'Pick-up and return reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // ------------------------------------------------------------------ setup

  Future<void> init() async {
    // The web version shows in-app messages instead (see onInAppMessage).
    if (_ready || kIsWeb) return;
    try {
      tz_data.initializeTimeZones();
      final settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onTap,
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications are not available: $e');
    }
  }

  void _onTap(NotificationResponse response) {
    final requestId = response.payload;
    if (requestId != null && requestId.isNotEmpty) {
      onOpenRequest?.call(requestId);
    }
  }

  /// Asks for notification permission (needed on Android 13 and newer).
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  /// If the app was opened by tapping a notification, returns that request id
  /// (only once).
  Future<String?> takeLaunchRequestId() async {
    if (!_ready || _launchChecked) return null;
    _launchChecked = true;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      final payload = details.notificationResponse?.payload;
      return (payload == null || payload.isEmpty) ? null : payload;
    } catch (_) {
      return null;
    }
  }

  /// Android only: whether "Alarms & reminders" is allowed, which makes
  /// scheduled reminders arrive at the exact minute.
  Future<bool> canScheduleExact() async {
    final android = _android;
    if (android == null) return true;
    try {
      return await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Android settings page for "Alarms & reminders".
  Future<void> requestExactAlarms() async {
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact alarm request failed: $e');
    }
  }

  // ----------------------------------------------------------- status update

  /// Called by RequestWatcher when staff change a request's status.
  Future<void> handleStatusChange(BorrowRequest request) async {
    await showStatusUpdate(request);
    await syncReminders(request);
  }

  Future<void> showStatusUpdate(BorrowRequest request) async {
    final name = request.equipmentName;
    final (title, body) = switch (request.status) {
      RequestStatus.pending => (
          'Request pending',
          'Your request for $name is waiting for approval.',
        ),
      RequestStatus.approved => (
          'Request approved',
          'Your request for $name was approved. '
              'Pick it up on ${formatDate(request.dateNeeded)}.',
        ),
      RequestStatus.borrowed => (
          'Equipment borrowed',
          'You have borrowed $name. '
              'Please return it by ${formatDate(request.returnDate)}.',
        ),
      RequestStatus.returned => (
          'Equipment returned',
          '$name was marked as returned. Thank you!',
        ),
      RequestStatus.rejected => (
          'Request rejected',
          request.remarks == null
              ? 'Your request for $name was rejected.'
              : 'Your request for $name was rejected: ${request.remarks}',
        ),
    };

    if (!_ready) {
      onInAppMessage?.call(title, body, request.id);
      return;
    }

    try {
      await _plugin.show(
        id: _idFor(request.id, _statusKind),
        title: title,
        body: body,
        notificationDetails: _statusDetails,
        payload: request.id,
      );
    } catch (e) {
      debugPrint('Could not show notification: $e');
    }
  }

  // --------------------------------------------------------------- reminders

  /// Makes the automatic reminders match the request's current status.
  Future<void> syncReminders(BorrowRequest request) async {
    if (!_ready) return;
    switch (request.status) {
      case RequestStatus.pending:
        break;
      case RequestStatus.approved:
        await _scheduleAt(
          id: _idFor(request.id, _pickupKind),
          when: _atReminderHour(request.dateNeeded),
          title: 'Pick-up reminder',
          body: 'Today is the day to pick up ${request.equipmentName}.',
          payload: request.id,
        );
      case RequestStatus.borrowed:
        await _cancel(_idFor(request.id, _pickupKind));
        await _scheduleAt(
          id: _idFor(request.id, _returnKind),
          when: _atReminderHour(request.returnDate),
          title: 'Return reminder',
          body: '${request.equipmentName} is due today. '
              'Please return it on time.',
          payload: request.id,
        );
      case RequestStatus.returned:
      case RequestStatus.rejected:
        await cancelReminders(request.id);
    }
  }

  /// A reminder at a time the student chooses. Returns false if the time is
  /// in the past or notifications are unavailable.
  Future<bool> scheduleCustomReminder(BorrowRequest request, DateTime when) {
    final name = request.equipmentName;
    final body = switch (request.status) {
      RequestStatus.borrowed =>
        'Return $name by ${formatDate(request.returnDate)}.',
      RequestStatus.approved =>
        'Pick up $name on ${formatDate(request.dateNeeded)}.',
      _ => 'Check on your request for $name.',
    };
    return _scheduleAt(
      id: _idFor(request.id, _customKind),
      when: when,
      title: 'BorrowIT reminder',
      body: body,
      payload: request.id,
    );
  }

  Future<void> cancelReminders(String requestId) async {
    await _cancel(_idFor(requestId, _pickupKind));
    await _cancel(_idFor(requestId, _returnKind));
    await _cancel(_idFor(requestId, _customKind));
  }

  // ----------------------------------------------------------------- helpers

  DateTime? _atReminderHour(DateTime? day) => day == null
      ? null
      : DateTime(day.year, day.month, day.day, reminderHour);

  Future<bool> _scheduleAt({
    required int id,
    required DateTime? when,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_ready || when == null || !when.isAfter(DateTime.now())) return false;
    try {
      final exact = await canScheduleExact();
      await _plugin.zonedSchedule(
        id: id,
        // Converting the local time to an exact moment in UTC means we don't
        // need to know the phone's time zone name.
        scheduledDate: tz.TZDateTime.from(when, tz.UTC),
        notificationDetails: _reminderDetails,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('Could not schedule reminder: $e');
      return false;
    }
  }

  Future<void> _cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      // Nothing to cancel.
    }
  }

  /// A stable number for (request, kind). Uses FNV-1a hashing because
  /// String.hashCode can change between app runs.
  int _idFor(String requestId, int kind) {
    var hash = 0x811c9dc5;
    for (final unit in requestId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return (hash & 0x0FFFFFFF) * 4 + kind;
  }
}
