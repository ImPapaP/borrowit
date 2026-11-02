import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/request_watcher.dart';
import 'equipment/equipment_list_view.dart';
import 'requests/history_view.dart';
import 'requests/my_requests_view.dart';
import 'requests/request_detail_screen.dart';

/// Main screen after login, with three tabs:
/// Equipment, My Requests and History.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _titles = ['Equipment', 'My Requests', 'History'];

  int _tab = 0;
  late final RequestWatcher _watcher;

  @override
  void initState() {
    super.initState();

    // Turns status changes into notifications while the app is open.
    _watcher = RequestWatcher(widget.user.uid)..start();

    final notifications = NotificationService.instance;
    notifications.onOpenRequest = _openRequest;
    notifications.onInAppMessage = _showInAppMessage;
    notifications.requestPermission();

    // If the app was opened by tapping a notification, show that request.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final requestId = await notifications.takeLaunchRequestId();
      if (requestId != null) _openRequest(requestId);
    });
  }

  @override
  void dispose() {
    _watcher.stop();
    final notifications = NotificationService.instance;
    if (notifications.onOpenRequest == _openRequest) {
      notifications.onOpenRequest = null;
    }
    if (notifications.onInAppMessage == _showInAppMessage) {
      notifications.onInAppMessage = null;
    }
    super.dispose();
  }

  /// Status updates on the web version (no phone notifications there).
  void _showInAppMessage(String title, String body, String requestId) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(body),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _openRequest(requestId),
        ),
      ),
    );
  }

  void _openRequest(String requestId) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestDetailScreen(requestId: requestId),
      ),
    );
  }

  void _showAccount() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AccountSheet(user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          IconButton(
            tooltip: 'Account',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _showAccount,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          const EquipmentListView(),
          MyRequestsView(uid: widget.user.uid),
          HistoryView(uid: widget.user.uid),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other),
            label: 'Equipment',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'My Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _AccountSheet extends StatefulWidget {
  const _AccountSheet({required this.user});

  final User user;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late final Future<Map<String, dynamic>?> _profile =
      AuthService.instance.profile(widget.user.uid);
  bool _seeding = false;

  Future<void> _seed() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _seeding = true);
    try {
      await FirestoreService.instance.seedSampleEquipment();
      messenger.showSnackBar(
        const SnackBar(content: Text('Sample equipment loaded.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not load sample equipment: $error')),
      );
    }
    if (mounted) setState(() => _seeding = false);
  }

  Future<void> _signOut() async {
    Navigator.of(context).pop();
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profile,
          builder: (context, snapshot) {
            final profile = snapshot.data ?? const <String, dynamic>{};
            final name = '${profile['name'] ?? widget.user.displayName ?? 'Student'}';
            final studentId = profile['studentId'];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                if (studentId != null)
                  Text(
                    'Student ID: $studentId',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                Text(
                  widget.user.email ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (kDebugMode) ...[
                  OutlinedButton.icon(
                    onPressed: _seeding ? null : _seed,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(_seeding
                        ? 'Loading…'
                        : 'Load sample equipment (debug only)'),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.tonalIcon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
