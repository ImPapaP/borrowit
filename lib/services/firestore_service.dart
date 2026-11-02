import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/sample_equipment.dart';
import '../models/borrow_request.dart';
import '../models/equipment.dart';

/// All reads and writes to Cloud Firestore.
///
/// Collections:
///   equipment/{id}  - the catalog (managed by staff in the Firebase console)
///   requests/{id}   - borrow requests made by students
///   users/{uid}     - student profiles (see AuthService)
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _equipment =>
      _db.collection('equipment');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('requests');

  // ---------------------------------------------------------------- equipment

  Stream<List<Equipment>> equipmentStream() {
    return _equipment.snapshots().map((snapshot) {
      final items = snapshot.docs.map(Equipment.fromDoc).toList();
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    });
  }

  Stream<Equipment?> equipmentById(String id) {
    return _equipment
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Equipment.fromDoc(doc) : null);
  }

  /// Writes the sample catalog. Used by the debug-only "Load sample
  /// equipment" button. Running it twice just overwrites the same items.
  Future<void> seedSampleEquipment() async {
    final batch = _db.batch();
    for (final item in sampleEquipment) {
      final data = Map<String, Object>.from(item)..remove('id');
      batch.set(_equipment.doc(item['id']! as String), data);
    }
    await batch.commit();
  }

  // ----------------------------------------------------------------- requests

  /// The raw query for a student's requests. RequestWatcher listens to this
  /// directly because it needs the snapshot metadata.
  Query<Map<String, dynamic>> myRequestsQuery(String uid) =>
      _requests.where('userId', isEqualTo: uid);

  /// All of a student's requests, newest first. Sorting happens here instead
  /// of in the query so no composite index is needed.
  Stream<List<BorrowRequest>> myRequestsStream(String uid) {
    return myRequestsQuery(uid).snapshots().map(requestsFromSnapshot);
  }

  static List<BorrowRequest> requestsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final items = snapshot.docs.map(BorrowRequest.fromDoc).toList();
    items.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return items;
  }

  Stream<BorrowRequest?> requestById(String id) {
    return _requests
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? BorrowRequest.fromDoc(doc) : null);
  }

  Future<String> submitRequest({
    required String userId,
    required Equipment equipment,
    required DateTime dateNeeded,
    required DateTime returnDate,
    required String purpose,
    String? imageFileName,
  }) async {
    final doc = await _requests.add({
      'userId': userId,
      'equipmentId': equipment.id,
      'equipmentName': equipment.name,
      'equipmentCategory': equipment.category,
      'equipmentImage': equipment.image,
      'dateNeeded': Timestamp.fromDate(dateNeeded),
      'returnDate': Timestamp.fromDate(returnDate),
      'purpose': purpose,
      'status': RequestStatus.pending.label,
      'imageFileName': imageFileName,
      'remarks': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Students can only cancel (delete) requests that are still Pending.
  Future<void> cancelRequest(String id) => _requests.doc(id).delete();
}
