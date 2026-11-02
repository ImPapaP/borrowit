import 'package:cloud_firestore/cloud_firestore.dart';

/// Small helpers that read Firestore values safely, so a field typed a bit
/// differently in the Firebase console doesn't crash the app.

String readString(Object? value) => value == null ? '' : value.toString();

String? readNullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(readString(value)) ?? 0;
}

DateTime? readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
