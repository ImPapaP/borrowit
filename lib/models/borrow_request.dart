import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

/// The status values stored in Firestore ("Pending", "Approved", ...).
enum RequestStatus {
  pending('Pending'),
  approved('Approved'),
  borrowed('Borrowed'),
  returned('Returned'),
  rejected('Rejected');

  const RequestStatus(this.label);

  /// The exact text saved in Firestore and shown in the app.
  final String label;

  /// Reads a status from Firestore. Not case-sensitive, so "approved" typed
  /// in the Firebase console also works.
  static RequestStatus parse(Object? value) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    for (final status in RequestStatus.values) {
      if (status.name == text) return status;
    }
    return RequestStatus.pending;
  }
}

/// One document in the `requests` collection.
class BorrowRequest {
  const BorrowRequest({
    required this.id,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCategory,
    required this.equipmentImage,
    required this.dateNeeded,
    required this.returnDate,
    required this.purpose,
    required this.status,
    this.imageFileName,
    this.remarks,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String equipmentId;
  final String equipmentName;
  final String equipmentCategory;
  final String equipmentImage;
  final DateTime? dateNeeded;
  final DateTime? returnDate;
  final String purpose;
  final RequestStatus status;

  /// Name of the attached photo. The photo itself is saved on the student's
  /// phone (see LocalImageService), not in the cloud.
  final String? imageFileName;

  /// Optional note from the staff (for example, why a request was rejected).
  final String? remarks;

  final DateTime? createdAt;

  bool get hasPhoto => imageFileName != null && imageFileName!.isNotEmpty;

  /// Used to sort newest first. A request that was just submitted has no
  /// server time yet, so it is treated as the newest.
  DateTime get sortDate => createdAt ?? DateTime.now();

  factory BorrowRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return BorrowRequest(
      id: doc.id,
      userId: readString(data['userId']),
      equipmentId: readString(data['equipmentId']),
      equipmentName: readString(data['equipmentName']),
      equipmentCategory: readString(data['equipmentCategory']),
      equipmentImage: readString(data['equipmentImage']),
      dateNeeded: readDate(data['dateNeeded']),
      returnDate: readDate(data['returnDate']),
      purpose: readString(data['purpose']),
      status: RequestStatus.parse(data['status']),
      imageFileName: readNullableString(data['imageFileName']),
      remarks: readNullableString(data['remarks']),
      createdAt: readDate(data['createdAt']),
    );
  }
}
