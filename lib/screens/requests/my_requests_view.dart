import 'package:flutter/material.dart';

import '../../models/borrow_request.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
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

  @override
  Widget build(BuildContext context) {
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

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                for (final status in const [
                  RequestStatus.pending,
                  RequestStatus.approved,
                  RequestStatus.borrowed,
                ])
                  Expanded(
                    child: _CountBox(status: status, count: counts[status] ?? 0),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final request in active)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RequestCard(
                  request: request,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RequestDetailScreen(requestId: request.id),
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

class _CountBox extends StatelessWidget {
  const _CountBox({required this.status, required this.count});

  final RequestStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(status, theme.colorScheme);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(status.label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
