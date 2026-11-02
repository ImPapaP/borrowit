import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

/// One item in the `equipment` collection.
class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.image,
    required this.quantityAvailable,
    required this.quantityTotal,
    required this.location,
    required this.condition,
  });

  final String id;
  final String name;
  final String description;
  final String category;

  /// File name of the picture inside `assets/equipment/` (for example
  /// `laptop.png`). A full https:// link also works.
  final String image;

  final int quantityAvailable;
  final int quantityTotal;
  final String location;
  final String condition;

  bool get isAvailable => quantityAvailable > 0;

  factory Equipment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final available = readInt(data['quantityAvailable']);
    final total = readInt(data['quantityTotal']);
    return Equipment(
      id: doc.id,
      name: readString(data['name']),
      description: readString(data['description']),
      category: readString(data['category']).isEmpty
          ? 'Other'
          : readString(data['category']),
      image: readString(data['image']),
      quantityAvailable: available,
      quantityTotal: total < available ? available : total,
      location: readString(data['location']),
      condition: readString(data['condition']),
    );
  }
}
