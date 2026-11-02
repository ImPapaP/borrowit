import 'package:intl/intl.dart';

final DateFormat _date = DateFormat('MMM d, yyyy');
final DateFormat _shortDate = DateFormat('MMM d');
final DateFormat _dateTime = DateFormat('MMM d, yyyy · h:mm a');

String formatDate(DateTime? value) => value == null ? '—' : _date.format(value);

String formatDateTime(DateTime? value) =>
    value == null ? '—' : _dateTime.format(value);

/// "Mar 3 – Mar 5, 2026"
String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '${formatDate(start)} – ${formatDate(end)}';
  final startText = start.year == end.year ? _shortDate.format(start) : _date.format(start);
  return '$startText – ${_date.format(end)}';
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
