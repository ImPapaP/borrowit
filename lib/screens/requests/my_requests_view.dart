import 'package:flutter/material.dart';

import '../../models/borrow_request.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../../widgets/request_widgets.dart';
import 'request_detail_screen.dart';

/// "My Requests" tab: every request that isn't returned yet, with its status.
class MyRequestsView extends StatefulWidget {
  const MyRequestsView({super.key, required this.uid});

  final String uid;

  @override
  State<MyRequestsView> createState() => _MyRequestsViewState();
}

class _MyRequestsViewState extends State<MyRequestsView> {
  late final Stream<List<BorrowRequest>> _requests =
      FirestoreService.instance.myRequestsStream(widget.uid);

  /// null means "All".
  RequestStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<BorrowRequest>>(
      stream: _requests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MessageView(
            icon: Icons.error_outline,
            title: 'Could not load your requests',
            message: '${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final active = snapshot.data!
            .where((request) => request.status != RequestStatus.returned)
            .toList();

        if (active.isEmpty) {
          return const MessageView(
            icon: Icons.assignment_outlined,
            title: 'No active requests',
            message: 'Open the Equipment tab, choose an item and tap '
                '"Request to borrow".',
          );
        }

        final counts = <RequestStatus, int>{};
        for (final request in active) {
          counts[request.status] = (counts[request.status] ?? 0) + 1;
        }
        final shown = _filter == null
            ? active
            : active.where((r) => r.status == _filter).toList();

        const summary = [
          RequestStatus.pending,
          RequestStatus.approved,
          RequestStatus.borrowed,
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            FadeSlideIn(
              child: GradientBanner(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your borrowing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    active.length == 1
                        ? '1 request in progress'
                        : '${active.length} requests in progress',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final status in summary)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: status == summary.last ? 0 : 8,
                            ),
                            child: _StatusCount(
                              status: status,
                              count: counts[status] ?? 0,
                              selected: _filter == status,
                              onTap: () => setState(() {
                                _filter = _filter == status ? null : status;
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  _filter == null ? 'All active requests' : _filter!.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (_filter != null)
                  TextButton(
                    onPressed: () => setState(() => _filter = null),
                    child: const Text('Show all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No ${_filter?.label.toLowerCase() ?? ''} requests.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final (index, request) in shown.indexed)
              Padding(
                key: ValueKey('${_filter?.name ?? 'all'}|${request.id}'),
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideIn(
                  index: index,
                  delay: const Duration(milliseconds: 150),
                  child: Pressable(
                    child: RequestCard(
                      request: request,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              RequestDetailScreen(requestId: request.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// White card inside the banner: status icon, count and name. Tap to filter.
class _StatusCount extends StatelessWidget {
  const _StatusCount({
    required this.status,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final RequestStatus status;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status, Theme.of(context).colorScheme);
    return Pressable(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.14) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon(status), size: 18, color: color),
              ),
              const SizedBox(height: 6),
              CountUpText(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: selected ? color : Colors.white,
                ),
              ),
              Text(
                status.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF1A1C24)
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
