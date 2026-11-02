import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/request_watcher.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Fades the page in when switching tabs (tabs keep their scroll position).
  late final AnimationController _tabFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

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
    _tabFade.dispose();
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

  static const _destinations = [
    (Icons.devices_other_outlined, Icons.devices_other, 'Equipment'),
    (Icons.assignment_outlined, Icons.assignment, 'My Requests'),
    (Icons.history_outlined, Icons.history, 'History'),
  ];

  void _selectTab(int index) {
    if (index == _tab) return;
    setState(() => _tab = index);
    if (reduceMotion(context)) return;
    _tabFade.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    final pages = FadeTransition(
      opacity: CurvedAnimation(parent: _tabFade, curve: Curves.easeOut),
      child: IndexedStack(
      index: _tab,
      children: [
        EquipmentListView(
          userName: widget.user.displayName,
          uid: widget.user.uid,
        ),
        MyRequestsView(uid: widget.user.uid),
        HistoryView(uid: widget.user.uid),
      ],
      ),
    );

    final initial = (widget.user.displayName ?? widget.user.email ?? '?')
        .trim();
    final accountButton = Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: _showAccount,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initial.isEmpty ? '?' : initial[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );

    if (wide) {
      // Website on a laptop or desktop: side navigation and a centered page.
      return Scaffold(
        appBar: AppBar(
          title: Text(_titles[_tab]),
          actions: [accountButton],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              extended: width >= 1200,
              selectedIndex: _tab,
              onDestinationSelected: _selectTab,
              labelType: width >= 1200
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: AppLogo(size: 44),
              ),
              destinations: [
                for (final (icon, selected, label) in _destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: pages,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [accountButton],
      ),
      body: pages,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _selectTab,
        destinations: [
          for (final (icon, selected, label) in _destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
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
