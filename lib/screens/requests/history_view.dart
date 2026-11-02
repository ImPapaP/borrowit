import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/borrow_request.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../../widgets/request_widgets.dart';
import 'request_detail_screen.dart';

/// "History" tab: completed (returned) borrowing transactions, by month.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key, required this.uid});

  final String uid;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final Stream<List<BorrowRequest>> _requests =
      FirestoreService.instance.myRequestsStream(widget.uid);

  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');

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

        // Summary numbers for the banner.
        var totalDays = 0;
        final categoryCounts = <String, int>{};
        for (final request in completed) {
          final start = request.dateNeeded;
          final end = request.returnDate;
          if (start != null && end != null) {
            totalDays += dateOnly(end).difference(dateOnly(start)).inDays + 1;
          }
          final category = request.equipmentCategory.isEmpty
              ? 'Other'
              : request.equipmentCategory;
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
        final topCategory = categoryCounts.entries
            .reduce((a, b) => b.value > a.value ? b : a)
            .key;

        // Group by the month the item was returned.
        final groups = <String, List<BorrowRequest>>{};
        for (final request in completed) {
          final month = _monthFormat.format(request.returnDate ?? request.sortDate);
          groups.putIfAbsent(month, () => []).add(request);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            FadeSlideIn(
              child: GradientBanner(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F8A55), Color(0xFF0E7C86)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Borrowing history',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Everything you have borrowed and returned.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      BannerStat(
                        icon: Icons.assignment_turned_in_outlined,
                        value: '${completed.length}',
                        label: 'Returned',
                      ),
                      BannerStat(
                        icon: Icons.calendar_month_outlined,
                        value: '$totalDays',
                        label: totalDays == 1 ? 'Day borrowed' : 'Days borrowed',
                      ),
                      BannerStat(
                        icon: Icons.star_outline_rounded,
                        value: topCategory,
                        label: 'Most borrowed',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
                child: Row(
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Divider(color: theme.colorScheme.outlineVariant),
                    ),
                  ],
                ),
              ),
              for (final (index, request) in entry.value.indexed)
                Padding(
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
          ],
        );
      },
    );
  }
}
