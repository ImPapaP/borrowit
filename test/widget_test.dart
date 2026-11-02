import 'package:borrowit/models/borrow_request.dart';
import 'package:borrowit/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status text from Firestore is read correctly', () {
    expect(RequestStatus.parse('Approved'), RequestStatus.approved);
    expect(RequestStatus.parse('borrowed'), RequestStatus.borrowed);
    expect(RequestStatus.parse(' RETURNED '), RequestStatus.returned);
    expect(RequestStatus.parse('Rejected'), RequestStatus.rejected);
    expect(RequestStatus.parse(null), RequestStatus.pending);
    expect(RequestStatus.parse('something else'), RequestStatus.pending);
  });

  test('date range is formatted for the request cards', () {
    expect(
      formatDateRange(DateTime(2026, 3, 3), DateTime(2026, 3, 5)),
      'Mar 3 – Mar 5, 2026',
    );
    expect(formatDate(null), '—');
  });
}
