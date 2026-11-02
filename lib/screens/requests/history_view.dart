import 'package:flutter/material.dart';

import '../../models/borrow_request.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/request_widgets.dart';
import 'request_detail_screen.dart';

/// "History" tab: completed (returned) borrowing transactions.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key, required this.uid});

  final String uid;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final Stream<List<BorrowRequest>> _requests =
      FirestoreService.instance.myRequestsStream(widget.uid);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<BorrowRequest>>(
      stream: _requests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MessageView(
            icon: Icons.error_outline,
            title: 'Could not load your history',
            message: '${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final completed = snapshot.data!
            .where((request) => request.status == RequestStatus.returned)
            .toList()
          // Most recently returned first.
          ..sort((a, b) => (b.returnDate ?? b.sortDate)
              .compareTo(a.returnDate ?? a.sortDate));

        if (completed.isEmpty) {
          return const MessageView(
            icon: Icons.history,
            title: 'No completed borrowings yet',
            message: 'Equipment you have returned will be listed here.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Text(
                completed.length == 1
                    ? '1 completed borrowing'
                    : '${completed.length} completed borrowings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final request in completed)
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
