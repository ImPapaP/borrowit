import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/borrow_request.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

/// Watches the student's requests while the app is open and turns status
/// changes (made by staff in Firebase) into local notifications.
///
/// The last status seen for each request is saved on the phone, so a change
/// that happened while the app was closed is announced the next time the app
/// opens.
class RequestWatcher {
  RequestWatcher(this.uid);

  final String uid;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Future<void> _queue = Future<void>.value();

  String get _storageKey => 'known_request_statuses_$uid';

  void start() {
    _subscription = FirestoreService.instance
        .myRequestsQuery(uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            // Only act on data confirmed by the server, so an old offline
            // copy doesn't look like a status change.
            if (snapshot.metadata.isFromCache) return;
            final requests = FirestoreService.requestsFromSnapshot(snapshot);
            _queue = _queue.then((_) => _process(requests));
          },
          onError: (Object error) => debugPrint('RequestWatcher: $error'),
        );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _process(List<BorrowRequest> requests) async {
    try {
      final notifications = NotificationService.instance;

      final saved = await _prefs.getString(_storageKey);
      final firstRun = saved == null;
      final known = <String, String>{};
      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (decoded is Map) {
          decoded.forEach((key, value) => known['$key'] = '$value');
        }
      }

      final current = <String, String>{};
      for (final request in requests) {
        final status = request.status.name;
        current[request.id] = status;
        final before = known[request.id];

        if (firstRun || before == null) {
          // First time we see this request: no pop-up, just set reminders.
          await notifications.syncReminders(request);
        } else if (before != status) {
          await notifications.handleStatusChange(request);
        }
      }

      // Requests that disappeared (cancelled) don't need reminders anymore.
      for (final id in known.keys) {
        if (!current.containsKey(id)) {
          await notifications.cancelReminders(id);
        }
      }

      await _prefs.setString(_storageKey, jsonEncode(current));
    } catch (e) {
      debugPrint('RequestWatcher: $e');
    }
  }
}
